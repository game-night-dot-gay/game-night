# Domain gamenight.gay
data "digitalocean_domain" "game-night-dot-gay" {
  name = "gamenight.gay"
}

# A record for gamenight.gay
resource "digitalocean_record" "base" {
  domain = data.digitalocean_domain.game-night-dot-gay.id
  type   = "A"
  name   = "@"
  value  = digitalocean_floating_ip.game_night_prod.ip_address
}

resource "digitalocean_record" "www" {
  domain = data.digitalocean_domain.game-night-dot-gay.id
  type   = "CNAME"
  name   = "www"
  value  = digitalocean_record.base.fqdn
}

resource "digitalocean_record" "prod" {
  domain = data.digitalocean_domain.game-night-dot-gay.id
  type   = "CNAME"
  name   = "prod"
  value  = digitalocean_record.base.fqdn
}

# Send Grid Validation
resource "digitalocean_record" "send_grid_1" {
  domain = data.digitalocean_domain.game-night-dot-gay.id
  type   = "CNAME"
  name   = "s1._domainkey"
  value  = "s1.domainkey.u26892863.wl114.sendgrid.net."
}

# Send Grid Validation
resource "digitalocean_record" "send_grid_2" {
  domain = data.digitalocean_domain.game-night-dot-gay.id
  type   = "CNAME"
  name   = "s2._domainkey"
  value  = "s2.domainkey.u26892863.wl114.sendgrid.net."
}

# Send Grid Validation
resource "digitalocean_record" "send_grid_3" {
  domain = data.digitalocean_domain.game-night-dot-gay.id
  type   = "CNAME"
  name   = "em4460"
  value  = "u26892863.wl114.sendgrid.net."
}