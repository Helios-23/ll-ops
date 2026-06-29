locals {
  effective_cloudflare_dns_records = merge(
    var.cloudflare_dns_records,
    contains(keys(var.cloudflare_dns_records), "repo") ? {
      repo = merge(var.cloudflare_dns_records["repo"], {
        value = module.hetzner_vpc.server_ipv4
      })
    } : {},
    contains(keys(var.cloudflare_dns_records), "lantern") ? {
      lantern = merge(var.cloudflare_dns_records["lantern"], {
        value = module.hetzner_vpc.web_server_ipv4
      })
    } : {},
  )
}

module "hetzner_vpc" {
  source = "./modules/hetzner_vpc"

  network_name            = var.network_name
  network_ip_range        = var.network_ip_range
  subnet_ip_range         = var.subnet_ip_range
  vswitch_subnet_ip_range = var.vswitch_subnet_ip_range
  network_zone            = var.network_zone
  vswitch_id              = var.vswitch_id
  route_destination       = var.route_destination
  route_gateway           = var.route_gateway
  create_default_route    = var.create_default_route

  ssh_key_name        = var.ssh_key_name
  ssh_public_key      = file(var.ssh_public_key_path)
  ssh_fips_public_key = file(var.ssh_fips_public_key_path)

  server_name       = var.server_name
  server_private_ip = var.server_private_ip
  server_type       = var.server_type
  server_image      = var.server_image
  server_location   = var.server_location
  devops_user       = var.devops_user

  web_server_name       = var.web_server_name
  web_server_private_ip = var.web_server_private_ip
  web_server_type       = var.web_server_type
  web_server_image      = var.web_server_image
  web_server_location   = var.web_server_location

  dedicated_server_name       = var.dedicated_server_name
  dedicated_server_public_ip  = var.dedicated_server_public_ip
  dedicated_server_private_ip = var.dedicated_server_private_ip
  dedicated_server_vlan_id    = var.dedicated_server_vlan_id
}

module "cloudflare_dns" {
  source = "./modules/cloudflare_dns"

  zone_id = var.cloudflare_zone_id
  records = local.effective_cloudflare_dns_records
}
