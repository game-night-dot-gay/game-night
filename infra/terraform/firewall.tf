
resource "digitalocean_firewall" "game_night_fw" {
  name = "game-night-fw"

  droplet_ids = [digitalocean_droplet.game_night_prod.id]

  inbound_rule {
    protocol         = "tcp"
    port_range       = "22"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  inbound_rule {
    protocol                  = "tcp"
    port_range                = "80"
    source_addresses          = ["0.0.0.0/0", "::/0"]
    source_load_balancer_uids = [digitalocean_loadbalancer.game_night_lb.id]
  }

  inbound_rule {
    protocol                  = "tcp"
    port_range                = "443"
    source_addresses          = ["0.0.0.0/0", "::/0"]
    source_load_balancer_uids = [digitalocean_loadbalancer.game_night_lb.id]
  }

  inbound_rule {
    protocol                  = "tcp"
    port_range                = "2727"
    source_addresses          = ["0.0.0.0/0", "::/0"]
    source_load_balancer_uids = [digitalocean_loadbalancer.game_night_lb.id]
  }

  inbound_rule {
    protocol         = "icmp"
    source_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "53"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "udp"
    port_range            = "53"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "80"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "tcp"
    port_range            = "443"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }

  outbound_rule {
    protocol              = "icmp"
    destination_addresses = ["0.0.0.0/0", "::/0"]
  }
}