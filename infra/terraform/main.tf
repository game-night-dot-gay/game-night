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

  connection {
    type        = "ssh"
    user        = var.ssh_user
    private_key = var.ssh_key
    host        = self.ipv4_address
  }

  provisioner "remote-exec" {
    inline = [
      <<EOT
sudo sed -i 's/\#\.\/nginx\.nix/\.\/nginx\.nix/g' /etc/nixos/configuration.nix
      EOT
      ,
      "sudo nix-channel --update",
      "sudo nixos-rebuild switch",
      "sudo nix-env --upgrade --always",
      "sudo rm -f /nix/var/nix/gcroots/auto/*",
      "sudo nix-collect-garbage -d",
      "sudo mount -o discard,defaults,noatime /dev/disk/by-id/scsi-0DO_Volume_game-night-prod /mnt/game-night-prod/postgres-data",
      "echo '/dev/disk/by-id/scsi-0DO_Volume_game-night-prod /mnt/game-night-prod ext4 defaults,nofail,discard 0 0' | sudo tee -a /etc/fstab",
      "sudo mount -o discard,defaults,noatime /dev/disk/by-id/scsi-0DO_Volume_game-night-backup /mnt/game-night-backup",
      "echo '/dev/disk/by-id/scsi-0DO_Volume_game-night-backup /mnt/game_night_backup ext4 defaults,nofail,discard 0 0' | sudo tee -a /etc/fstab",
    ]
  }
}

resource "digitalocean_floating_ip" "game_night_prod" {
  droplet_id = digitalocean_droplet.game_night_prod.id
  region     = digitalocean_droplet.game_night_prod.region
}

resource "digitalocean_container_registry" "registry" {
  name                   = "game-night-registry"
  subscription_tier_slug = "starter"
  region                 = "nyc3"
}
