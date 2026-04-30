variable "zone_id" {
  description = "Cloudflare zone ID for the domain."
  type        = string
}

variable "records" {
  description = "Map of DNS records to create. Each record needs: name, value, type. Optional: ttl, proxied."
  type = map(object({
    name    = string
    value   = string
    type    = string
    ttl     = optional(number, 1)
    proxied = optional(bool, false)
  }))
}
