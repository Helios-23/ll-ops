variable "network_name" {
  description = "Name of the Hetzner Cloud network."
  type        = string
}

variable "network_ip_range" {
  description = "CIDR for the Hetzner Cloud network."
  type        = string
}

variable "subnet_ip_range" {
  description = "CIDR for the cloud subnet used by hcloud servers."
  type        = string
}

variable "vswitch_subnet_ip_range" {
  description = "CIDR for the vswitch subnet used by dedicated servers."
  type        = string
}

variable "network_zone" {
  description = "Hetzner network zone (for example eu-central)."
  type        = string
}

variable "vswitch_id" {
  description = "Optional Hetzner Robot vSwitch ID for subnet type \"vswitch\"."
  type        = number
  default     = null
}

variable "create_default_route" {
  description = "Whether to create a route resource."
  type        = bool
}

variable "route_destination" {
  description = "Destination CIDR for the optional route."
  type        = string
}

variable "route_gateway" {
  description = "Gateway IP for the optional route."
  type        = string
}

variable "ssh_key_name" {
  description = "Name used for the SSH key in Hetzner."
  type        = string
}

variable "ssh_public_key" {
  description = "Public key content used for server access."
  type        = string
}

variable "ssh_fips_public_key" {
  description = "FIPS-compatible public key content used for server access."
  type        = string
}

variable "server_name" {
  description = "Name of the Hetzner Cloud server."
  type        = string
}

variable "server_private_ip" {
  description = "Private IP address for the cloud server inside the subnet."
  type        = string
}

variable "server_type" {
  description = "Hetzner Cloud server type."
  type        = string
}

variable "server_image" {
  description = "Image used to provision the server."
  type        = string
}

variable "server_location" {
  description = "Hetzner location for the server (for example nbg1, fsn1, hel1)."
  type        = string
}

variable "devops_user" {
  description = "System username to create for operations access."
  type        = string
}

variable "dedicated_server_name" {
  description = "Name label for the existing dedicated server connected via vSwitch."
  type        = string
}

variable "dedicated_server_public_ip" {
  description = "Public IPv4 address of the existing dedicated server."
  type        = string
}

variable "dedicated_server_private_ip" {
  description = "Private IP to configure on the dedicated server in the same subnet."
  type        = string
}

variable "dedicated_server_vlan_id" {
  description = "VLAN ID used on the dedicated server for the vSwitch."
  type        = number
}
