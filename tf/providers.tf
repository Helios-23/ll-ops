terraform {
  required_version = ">= 1.5.0"

  required_providers {
    spaceship = {
      source  = "namecheap/spaceship"
      version = ">= 0.4.0"
    }
  }
}

provider "spaceship" {
  api_key    = var.spaceship_api_key
  api_secret = var.spaceship_api_secret
}
