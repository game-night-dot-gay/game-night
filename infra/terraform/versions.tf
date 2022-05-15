terraform {
  required_version = ">= 1.1.9"

  cloud {
    organization = "be-gay-do-crime"

    workspaces {
      name = "game-night"
    }
  }

  required_providers {
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
  }
}
