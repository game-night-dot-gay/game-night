data "digitalocean_ssh_keys" "ssh_key_allie" {
  name = "Allie SSH Key"
}

/* TODO - Amy add ssh key
data "digitalocean_ssh_keys" "ssh_key_amy" {
  name = "Amy SSH Key"
}
*/

data "digitalocean_ssh_keys" "ssh_key_automation" {
  name = "Automation"
}



resource "digitalocean_droplet" "web" {
  image  = "ubuntu-20-04-x64"
  name   = "rancheros-prod"
  region = "fra1"
  size   = "s-1vcpu-1gb"
  ssh_keys = [
    data.digitalocean_ssh_key.ssh_key_allie.id,
    data.digitalocean_ssh_key.ssh_key_automation.id
  ]
}