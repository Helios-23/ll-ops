variable "network_name" {
  description = "Name of the Hetzner Cloud network (VPC)."
  type        = string
  default     = "epytype-vpc"
}

variable "network_ip_range" {
  description = "CIDR for the Hetzner Cloud network."
  type        = string
  default     = "10.50.0.0/16"
}

variable "subnet_ip_range" {
  description = "CIDR for the primary network subnet."
  type        = string
  default     = "10.50.1.0/24"
}

variable "network_zone" {
  description = "Hetzner network zone for the subnet (e.g. eu-central)."
  type        = string
  default     = "eu-central"
}

variable "subnet_type" {
  description = "Deprecated. Cloud server networking always uses a cloud subnet."
  type        = string
  default     = "cloud"
}

variable "vswitch_subnet_ip_range" {
  description = "CIDR for the vSwitch subnet used by dedicated servers."
  type        = string
  default     = "10.50.2.0/24"
}

variable "vswitch_id" {
  description = "Optional Hetzner Robot vSwitch ID to connect dedicated servers to this subnet."
  type        = number
  default     = 80860
}

variable "dedicated_server_vlan_id" {
  description = "VLAN ID used by the dedicated server for the Hetzner vSwitch."
  type        = number
  default     = 4000
}

variable "create_default_route" {
  description = "Whether to create a default route in the network."
  type        = bool
  default     = false
}

variable "route_destination" {
  description = "Route destination CIDR when create_default_route is true."
  type        = string
  default     = "0.0.0.0/0"
}

variable "route_gateway" {
  description = "Gateway IP in the network for the route."
  type        = string
  default     = "10.50.1.1"
}

variable "ssh_key_name" {
  description = "Name to register for the devops SSH key in Hetzner."
  type        = string
  default     = "devops.epytype.org"
}

variable "ssh_public_key_path" {
  description = "Absolute or relative path to the devops public SSH key."
  type        = string
  default     = "../keys/ssh/devops.epytype.org.pub"
}

variable "ssh_fips_public_key_path" {
  description = "Absolute or relative path to the FIPS-compatible devops public SSH key."
  type        = string
  default     = "../keys/ssh/devops.epytype.org.fips_rsa.pub"
}

variable "server_name" {
  description = "Name of the Hetzner Cloud server."
  type        = string
  default     = "repo"
}

variable "server_private_ip" {
  description = "Private IP for the repo server inside the selected subnet."
  type        = string
  default     = "10.50.1.10"
}

variable "dedicated_server_name" {
  description = "Name label for the existing dedicated server connected via vSwitch."
  type        = string
  default     = "gex44-1-dedicated"
}

variable "dedicated_server_public_ip" {
  description = "Public IPv4 address of the existing dedicated server."
  type        = string
  default     = "5.9.86.250"
}

variable "dedicated_server_private_ip" {
  description = "Private IP to configure on the dedicated server within the vSwitch subnet."
  type        = string
  default     = "10.50.2.11"
}

variable "server_type" {
  description = "Hetzner Cloud server type."
  type        = string
  default     = "cpx42"
}

variable "server_image" {
  description = "Image used to provision the server."
  type        = string
  default     = "ubuntu-22.04"
}

variable "server_location" {
  description = "Hetzner location for the server (for example nbg1, fsn1, hel1)."
  type        = string
  default     = "nbg1"
}

variable "devops_user" {
  description = "System username to create and grant sudo access."
  type        = string
  default     = "devops"
}

variable "web_server_name" {
  description = "Name of the Hetzner Cloud web server."
  type        = string
  default     = "web"
}

variable "web_server_private_ip" {
  description = "Private IP for the web server inside the selected subnet."
  type        = string
  default     = "10.50.1.11"
}

variable "web_server_type" {
  description = "Hetzner Cloud server type for the web host."
  type        = string
  default     = "cpx22"
}

variable "web_server_image" {
  description = "Image used to provision the web server."
  type        = string
  default     = "ubuntu-24.04"
}

variable "web_server_location" {
  description = "Hetzner location for the web server."
  type        = string
  default     = "nbg1"
}

variable "cloudflare_zone_id" {
  description = "Cloudflare zone ID for the domain."
  type        = string
  sensitive   = true
}

variable "cloudflare_dns_records" {
  description = "Map of DNS records to manage."
  type = map(object({
    name    = string
    value   = string
    type    = string
    ttl     = optional(number, 1)
    proxied = optional(bool, false)
  }))
  default = {
    repo = {
      name    = "repo"
      value   = "195.201.226.77"
      type    = "A"
      proxied = true
    }
  }
}
