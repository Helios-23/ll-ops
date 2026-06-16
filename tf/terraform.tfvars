cloudflare_zone_id = "245d6a95015f03d3d5f9e9aa24ef06bd"

cloudflare_dns_records = {
  repo = {
    name    = "repo"
    value   = "195.201.226.77"
    type    = "A"
    proxied = true
  }
  ai = {
    name    = "ai"
    value   = "5.9.86.250"
    type    = "A"
    proxied = true
  }
  lantern = {
    name    = "lantern"
    value   = "5.9.86.250"
    type    = "A"
    proxied = true
  }
}
