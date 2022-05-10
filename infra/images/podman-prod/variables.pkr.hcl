variable "snapshot_name" {
  default = "nixos-podman-{{timestamp}}"
}

variable "do_token" {
  description = "DigitalOcean Personal Access Token"
  type        = string
}

variable "base_system_image" {
  type = string
  //ID for: "nixos-podman-base"
  //See README.md for how to get ID from DO API
  default = "107939683"
}

variable "region" {
  type    = string
  default = "nyc3"

}

variable "droplet_size" {
  type    = string
  default = "s-1vcpu-1gb"
}

variable "tags" {
  type    = list(string)
  default = ["nixos"]
}

// TODO - Replace with key info
// This is for the first run build
variable "ssh_username" {
  type    = string
  default = "root"
}

variable "ssh_password" {
  type = string
}
