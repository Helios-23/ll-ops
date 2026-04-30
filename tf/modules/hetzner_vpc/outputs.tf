output "network_id" {
  description = "ID of the created Hetzner network."
  value       = hcloud_network.this.id
}

output "network_name" {
  description = "Name of the created Hetzner network."
  value       = hcloud_network.this.name
}

output "subnet_id" {
  description = "ID of the created Hetzner cloud subnet."
  value       = hcloud_network_subnet.cloud.id
}

output "vswitch_subnet_id" {
  description = "ID of the created Hetzner vswitch subnet (if enabled)."
  value       = try(hcloud_network_subnet.vswitch[0].id, null)
}

output "ssh_key_id" {
  description = "ID of the registered SSH key."
  value       = hcloud_ssh_key.devops.id
}

output "server_id" {
  description = "ID of the provisioned server."
  value       = hcloud_server.this.id
}

output "server_ipv4" {
  description = "Public IPv4 address of the provisioned server."
  value       = hcloud_server.this.ipv4_address
}

output "server_private_ip" {
  description = "Private IP address of the provisioned cloud server."
  value       = hcloud_server_network.private.ip
}

output "dedicated_server" {
  description = "Metadata for the existing dedicated server expected in the same subnet."
  value       = terraform_data.dedicated_server.output
}
