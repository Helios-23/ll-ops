output "domain" {
  description = "Domain managed by Spaceship DNS."
  value       = var.domain
}

output "pharos_fqdn" {
  description = "Preferred hostname for the future VPC/public IP anchor."
  value       = "pharos.${var.domain}"
}

output "dns_records" {
  description = "DNS records configured for the domain."
  value       = local.spaceship_dns_records
}
