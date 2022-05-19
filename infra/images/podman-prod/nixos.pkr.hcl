source "digitalocean" "nixos" {
  snapshot_name = var.snapshot_name
  api_token     = var.do_token
  image         = var.base_system_image
  region        = var.region
  size          = var.droplet_size
  tags          = var.tags
  ssh_username  = var.ssh_username
  ssh_password  = var.ssh_password
}



build {
  sources = ["source.digitalocean.nixos"]

  provisioner "file" {
    sources = [
      "configuration.nix",
    ]
    destination = "/tmp/"
  }

  provisioner "shell" {
    inline = [
      "mkdir -p /mnt/game-night-prod/postgres-data",
      "mkdir -p /mnt/game-night-backup/postgres-data",
      "mount -o discard,defaults,noatime /dev/disk/by-id/scsi-0DO_Volume_game-night-prod /mnt/game-night-prod",
      "mount -o discard,defaults,noatime /dev/disk/by-id/scsi-0DO_Volume_game-night-backup /mnt/game-night-backup",
      "cp /tmp/configuration.nix /etc/nixos/configuration.nix",
      "nixos-generate-config",
      "chown -R root:root /etc/nixos/*",
      "chmod 644 /etc/nixos/*",
      "nix-channel --update",
      "nixos-rebuild switch",
      "nix-env --upgrade --always",
      "rm -f /nix/var/nix/gcroots/auto/*",
      "nix-collect-garbage -d"
    ]
  }
}