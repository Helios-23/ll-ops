dns_ttl = 3600

mx_records = [
  {
    exchange   = "mx1.improvmx.com"
    preference = 10
  },
  {
    exchange   = "mx2.improvmx.com"
    preference = 20
  }
]

gcp_vpc_name            = "ll-vpc-west"
gcp_subnet_name         = "ll-pharos-subnet"
gcp_subnet_cidr         = "10.0.1.0/24"
gcp_firewall_name       = "allow-ssh-http"
gcp_address_name        = "pharos-llight-io-ip"
gcp_instance_name       = "pharos-llight-io"
gcp_inventory_host_name = "pharos01"
gcp_machine_type        = "e2-medium"
devops_ssh_public_key_path = "../keys/ssh/devops.llight.io.pub"
