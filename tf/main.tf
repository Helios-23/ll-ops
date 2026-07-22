data "google_compute_image" "ubuntu_2404" {
  family  = "ubuntu-2404-lts-amd64"
  project = "ubuntu-os-cloud"
}

locals {
  pharos_public_ipv4 = google_compute_address.pharos.address

  spaceship_dns_records = concat(
    [
      for mx in var.mx_records : {
        type       = "MX"
        name       = "@"
        ttl        = var.dns_ttl
        exchange   = mx.exchange
        preference = mx.preference
      }
    ],
    [
      {
        type    = "A"
        name    = "pharos"
        ttl     = var.dns_ttl
        address = local.pharos_public_ipv4
      }
    ]
  )
}

resource "google_project_service" "compute_api" {
  project            = var.gcp_proj_id
  service            = "compute.googleapis.com"
  disable_on_destroy = false
}

resource "google_compute_network" "ll_vpc_west" {
  name                    = var.gcp_vpc_name
  auto_create_subnetworks = false

  depends_on = [google_project_service.compute_api]
}

resource "google_compute_subnetwork" "ll_pharos_subnet" {
  name          = var.gcp_subnet_name
  ip_cidr_range = var.gcp_subnet_cidr
  region        = var.gcp_region
  network       = google_compute_network.ll_vpc_west.id

  depends_on = [google_project_service.compute_api]
}

resource "google_compute_firewall" "allow_ssh_http" {
  name    = var.gcp_firewall_name
  network = google_compute_network.ll_vpc_west.name

  direction     = "INGRESS"
  source_ranges = ["0.0.0.0/0"]

  allow {
    protocol = "tcp"
    ports    = ["22", "80", "443"]
  }

  depends_on = [google_project_service.compute_api]
}

resource "google_compute_address" "pharos" {
  name   = var.gcp_address_name
  region = var.gcp_region

  depends_on = [google_project_service.compute_api]
}

resource "google_compute_project_metadata_item" "devops_ssh_key" {
  key   = "ssh-keys"
  value = "devops:${trimspace(file(var.devops_ssh_public_key_path))}"

  depends_on = [google_project_service.compute_api]
}

resource "google_compute_instance" "pharos" {
  name         = var.gcp_instance_name
  hostname     = "${var.gcp_inventory_host_name}.${var.domain}"
  machine_type = var.gcp_machine_type
  zone         = var.gcp_zone
  tags         = var.gcp_instance_tags

  depends_on = [google_project_service.compute_api]

  boot_disk {
    initialize_params {
      image = data.google_compute_image.ubuntu_2404.self_link
    }
  }

  network_interface {
    subnetwork = google_compute_subnetwork.ll_pharos_subnet.self_link

    access_config {
      nat_ip = google_compute_address.pharos.address
    }
  }

  metadata = {
    ssh-keys = "devops:${trimspace(file(var.devops_ssh_public_key_path))}"
  }
}

resource "spaceship_dns_records" "root" {
  domain = var.domain

  records = local.spaceship_dns_records
}
