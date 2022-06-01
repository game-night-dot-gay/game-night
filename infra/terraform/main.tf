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

resource "null_resource" "ssh_provisioner" {

  # This will trigger when the Droplet id changes (new VM)
  triggers = {
    file_copy_id = digitalocean_droplet.game_night_prod.id
  }

  connection {
    type        = "ssh"
    user        = var.ssh_user
    private_key = var.ssh_key
    host        = digitalocean_droplet.game_night_prod.ipv4_address
  }

  provisioner "remote-exec" {
    inline = [
      "sudo mv -f /etc/nixos/nginx.nix /etc/nixos/nginx-base.nix",
      "sudo mv -f /etc/nixos/nginx-prod.nix /etc/nixos/nginx.nix",
      "sudo mount -o discard,defaults,noatime /dev/disk/by-id/scsi-0DO_Volume_game-night-prod /mnt/game-night-prod",
      "sudo mount -o discard,defaults,noatime /dev/disk/by-id/scsi-0DO_Volume_game-night-backup /mnt/game-night-backup",
      "sudo nixos-generate-config",
      "sudo cat /etc/nixos/hardware-configuration.nix",
      "sudo nix-channel --update",
      "sudo nixos-rebuild switch",
      "sudo nix-env --upgrade --always",
      "sudo rm -f /nix/var/nix/gcroots/auto/* \n nix-collect-garbage -d",
      "sudo nix-collect-garbage -d ",
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