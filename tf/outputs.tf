output "network_id" {
  description = "ID of the Hetzner Cloud network."
  value       = module.hetzner_vpc.network_id
}

output "network_name" {
  description = "Name of the Hetzner Cloud network."
  value       = module.hetzner_vpc.network_name
}

output "subnet_id" {
  description = "ID of the primary subnet."
  value       = module.hetzner_vpc.subnet_id
}

output "ssh_key_id" {
  description = "ID of the registered devops SSH key."
  value       = module.hetzner_vpc.ssh_key_id
}

output "server_id" {
  description = "ID of the provisioned server."
  value       = module.hetzner_vpc.server_id
}

output "server_name" {
  description = "Name of the provisioned server."
  value       = var.server_name
}

output "server_ipv4" {
  description = "Public IPv4 address of the provisioned server."
  value       = module.hetzner_vpc.server_ipv4
}

output "server_private_ip" {
  description = "Private IP address of the provisioned cloud server."
  value       = module.hetzner_vpc.server_private_ip
}

output "dedicated_server" {
  description = "Metadata for the existing dedicated server expected in the same subnet."
  value       = module.hetzner_vpc.dedicated_server
}

output "dns_records" {
  description = "IDs of managed Cloudflare DNS records."
  value       = module.cloudflare_dns.record_ids
}

output "dns_record_values" {
  description = "DNS records with their names and values for inventory mapping."
  value       = var.cloudflare_dns_records
}
