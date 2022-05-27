resource "digitalocean_droplet" "game_night_prod" {
  image  = var.image_id
  name   = "game-night-prod"
  region = "nyc3"
  size   = "s-1vcpu-1gb"
  ssh_keys = [
    data.digitalocean_ssh_key.ssh_key_allie.id,
    data.digitalocean_ssh_key.ssh_key_amy.id,
    data.digitalocean_ssh_key.ssh_key_automation.id
  ]
  volume_ids = [
    data.digitalocean_volume.game_night_prod.id,
    data.digitalocean_volume.game_night_backup.id
  ]
  graceful_shutdown = true

}

resource "digitalocean_floating_ip" "game_night_prod" {
  droplet_id = digitalocean_droplet.game_night_prod.id
  region     = digitalocean_droplet.game_night_prod.region
}

resource "digitalocean_container_registry" "registry" {
  name                   = "game-night"
  subscription_tier_slug = "starter"
  region                 = "nyc3"
}

resource "null_resource" "file_copy" {

  # This will trigger when the ID of the droplet changes (new deploy)
  triggers = {
    droplet_id = digitalocean_droplet.game_night_prod.id
  }

  connection {
    type        = "ssh"
    user        = var.ssh_user
    private_key = var.ssh_key
    host        = digitalocean_droplet.game_night_prod.ipv4_address
  }

  provisioner "file" {
    source      = "${path.module}/../images/podman-prod/configuration.nix"
    destination = "/tmp/configuration.nix"
  }

  provisioner "file" {
    source      = "${path.module}/../images/podman-prod/nginx.nix"
    destination = "/tmp/nginx.nix"
  }
}

resource "null_resource" "ssh_provisioner" {

  # This will trigger once the file_copy provisioner runs
  triggers = {
    file_copy_id = null_resource.file_copy.id
  }

  connection {
    type        = "ssh"
    user        = var.ssh_user
    private_key = var.ssh_key
    host        = digitalocean_droplet.game_night_prod.ipv4_address
  }

  # This sed command is uncommenting the nginx.nix import from the configuration.nix file
  # so that it will be applied when nixos-rebuild switch is run. This is because
  # we cannot apply that config during the Packer build or Let's Encrypt validation
  # will fail.
  # TODO - Find a better way to solve this so we can remove the sed
  provisioner "remote-exec" {
    inline = [
      "sudo mv -f /tmp/configuration.nix /etc/nixos/configuration.nix",
      "sudo mv -f /tmp/nginx.nix /etc/nixos/configuration.nix",
      <<EOT
sudo sed -i 's/\#\.\/nginx\.nix/\.\/nginx\.nix/g' /etc/nixos/configuration.nix
      EOT
      ,
      "sudo cat /etc/nixos/configuration.nix",
      "sudo mount -o discard,defaults,noatime /dev/disk/by-id/scsi-0DO_Volume_game-night-prod /mnt/game-night-prod",
      "sudo mount -o discard,defaults,noatime /dev/disk/by-id/scsi-0DO_Volume_game-night-backup /mnt/game-night-backup",
      "sudo nixos-generate-config",
      "sudo cat /etc/nixos/hardware-configuration.nix",
      "sudo nix-channel --update",
      # Trying this without NoHup again
      "sudo nixos-rebuild switch",
      "sudo nix-env --upgrade --always",
      "sudo rm -f /nix/var/nix/gcroots/auto/* \n nix-collect-garbage -d",
      "sudo nix-collect-garbage -d ",
      # nixos-rebuild switch restarts sshd and networking so it causes Terraform to disconnect
      # We run this in the background with nohup to let Terraform exit cleanly
      #"echo \"!#/bin/bash\n\n nixos-rebuild switch && nix-env --upgrade --always \n rm -f /nix/var/nix/gcroots/auto/* \n nix-collect-garbage -d \n reboot now \n\n\" >> ./switch-and-update.sh",
      #"chmod +x ./switch-and-update.sh",
      #"nohup sudo -b ./switch-and-update.sh",
    ]
  }
}


data "digitalocean_ssh_key" "ssh_key_allie" {
  name = "Allie Laptop"
}


data "digitalocean_ssh_key" "ssh_key_amy" {
  name = "Amy's Laptop"
}

data "digitalocean_ssh_key" "ssh_key_automation" {
  name = "Automation"
}

data "digitalocean_volume" "game_night_prod" {
  name = "game-night-prod"
}

data "digitalocean_volume" "game_night_backup" {
  name = "game-night-backup"
}