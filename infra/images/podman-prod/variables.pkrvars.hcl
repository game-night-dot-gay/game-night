variable "do_token" {
  description = "DigitalOcean Personal Access Token"
}

variable "base_system_image" {
  default = "nixos-podman-base"

}

variable "region" {
  default = "nyc3"
}

variable "droplet_size" {
  default = "s-1-vcpu-1gb"
}
