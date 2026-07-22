terraform {
  required_version = ">= 1.5.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
    spaceship = {
      source  = "namecheap/spaceship"
      version = ">= 0.4.0"
    }
  }
}

provider "google" {
  project = var.gcp_proj_id
  region  = var.gcp_region
  zone    = var.gcp_zone
}

provider "spaceship" {
  api_key    = var.spaceship_api_key
  api_secret = var.spaceship_api_secret
}
