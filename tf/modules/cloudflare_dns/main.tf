terraform {
  required_version = ">= 1.5.0"

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
}

resource "cloudflare_record" "dns_records" {
  for_each = var.records

  zone_id = var.zone_id
  name    = each.value.name
  content = each.value.value
  type    = each.value.type
  ttl     = lookup(each.value, "ttl", 1)
  proxied = lookup(each.value, "proxied", false)
}
