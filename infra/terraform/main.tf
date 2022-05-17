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

resource "digitalocean_certificate" "certificate" {
  name    = "game-night-wildcard"
  type    = "lets_encrypt"
  domains = ["gamenight.gay", "*.gamenight.gay"]
} 