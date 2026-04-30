output "record_ids" {
  description = "Map of Cloudflare DNS record IDs by record name."
  value       = { for k, v in cloudflare_record.dns_records : k => v.id }
}
