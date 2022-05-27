// DigitalOcean PAT
variable "do_token" {}

variable "ssh_user" {}
variable "ssh_key" {}

variable "image_id" {
  type = string
  //ID for: "nixos-podman-base"
  //See README.md for how to get ID from DO API
}