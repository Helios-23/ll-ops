locals {
  spaceship_dns_records = concat(
    [
      {
        type       = "MX"
        name       = "@"
        ttl        = var.dns_ttl
        exchange   = var.mail_exchange
        preference = var.mx_preference
      }
    ],
    var.pharos_ipv4 == null || trimspace(var.pharos_ipv4) == "" ? [] : [
      {
        type    = "A"
        name    = "pharos"
        ttl     = var.dns_ttl
        address = var.pharos_ipv4
      }
    ]
  )
}

resource "spaceship_dns_records" "root" {
  domain = var.domain

  records = local.spaceship_dns_records
}
