source "digitalocean" "nixos" {
  api_token = var.do_token
  image     = var.base_system_image
  region    = var.region
  size      = var.droplet_size
}

build {
  sources = ["source.digitalocean.nixos"]
}