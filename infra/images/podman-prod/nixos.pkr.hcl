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
      "infra/nixos/",
    ]
    destination = "/tmp/"
  }

  provisioner "shell" {
    inline = [
      "mkdir -p /mnt/game-night-prod/postgres-data",
      "mkdir -p /mnt/game-night-backup/postgres-data",
      "cp -f /tmp/nixos/*.nix /etc/nixos/",
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