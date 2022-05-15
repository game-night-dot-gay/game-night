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
      "hardware-configuration.nix",
    ]
    destination = "/tmp/"
  }

  provisioner "shell" {
    inline = [
      "cp /tmp/configuration.nix /etc/nixos/configuration.nix",
      "cp /tmp/hardware-configuration.nix /etc/nixos/hardware-configuration.nix",
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