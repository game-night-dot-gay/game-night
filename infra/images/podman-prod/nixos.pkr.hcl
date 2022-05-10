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
      "sudo cp /tmp/configuration.nix /etc/nixos/configuration.nix",
      "sudo cp /tmp/hardware-configuration.nix /etc/nixos/hardware-configuration.nix",
      "sudo chown -R root:root /etc/nixos/*",
      "sudo chmod 644 /etc/nixos/*",
      "sudo nix-channel --update",
      "sudo nixos-rebuild switch",
      "sudo nix-env -u --always",
      "sudo rm -f /nix/var/nix/gcroots/auto/*",
      "sudo nix-collect-garbage -d"
    ]
  }
}