output "domain" {
  description = "Domain managed by Spaceship DNS."
  value       = var.domain
}

output "pharos_fqdn" {
  description = "Preferred public hostname for the GCP Pharos instance."
  value       = "pharos.${var.domain}"
}

output "dns_records" {
  description = "DNS records configured for the domain."
  value       = local.spaceship_dns_records
}

output "gcp_network_name" {
  description = "Name of the created GCP VPC."
  value       = google_compute_network.ll_vpc_west.name
}

output "gcp_subnet_name" {
  description = "Name of the created GCP subnet."
  value       = google_compute_subnetwork.ll_pharos_subnet.name
}

output "gcp_firewall_name" {
  description = "Name of the ingress firewall rule."
  value       = google_compute_firewall.allow_ssh_http.name
}

output "gcp_instance_name" {
  description = "GCP instance resource name."
  value       = google_compute_instance.pharos.name
}

output "gcp_instance_public_ip" {
  description = "Reserved public IPv4 address of the Pharos instance."
  value       = google_compute_address.pharos.address
}

output "gcp_inventory_host_name" {
  description = "host_name value to assign to the web0 inventory entry."
  value       = var.gcp_inventory_host_name
}
