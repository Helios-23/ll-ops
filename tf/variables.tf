variable "spaceship_api_key" {
  description = "Spaceship API key. Prefer passing this via TF_VAR_spaceship_api_key or a generated tfvars file."
  type        = string
  sensitive   = true
}

variable "spaceship_api_secret" {
  description = "Spaceship API secret. Prefer passing this via TF_VAR_spaceship_api_secret or a generated tfvars file."
  type        = string
  sensitive   = true
}

variable "domain" {
  description = "Root domain managed in Spaceship DNS."
  type        = string
  default     = "llight.io"
}

variable "mx_records" {
  description = "MX records for the root domain."
  type = list(object({
    exchange   = string
    preference = number
  }))
  default = [
    {
      exchange   = "mx1.improvmx.com"
      preference = 10
    },
    {
      exchange   = "mx2.improvmx.com"
      preference = 20
    }
  ]
}

variable "dns_ttl" {
  description = "Default TTL for managed DNS records in seconds."
  type        = number
  default     = 3600
}

variable "gcp_org_id" {
  description = "GCP organization ID for the Logical Light environment."
  type        = string
}

variable "gcp_proj_id" {
  description = "GCP project ID where resources will be created."
  type        = string
}

variable "gcp_region" {
  description = "GCP region for regional resources."
  type        = string
}

variable "gcp_zone" {
  description = "GCP zone for zonal resources."
  type        = string
}

variable "gcp_vpc_name" {
  description = "Name of the custom GCP VPC."
  type        = string
  default     = "ll-vpc-west"
}

variable "gcp_subnet_name" {
  description = "Name of the Pharos subnet in GCP."
  type        = string
  default     = "ll-pharos-subnet"
}

variable "gcp_subnet_cidr" {
  description = "CIDR range for the Pharos subnet in GCP."
  type        = string
  default     = "10.0.1.0/24"
}

variable "gcp_firewall_name" {
  description = "Firewall rule allowing SSH and HTTP/S access to instances in the VPC."
  type        = string
  default     = "allow-ssh-http"
}

variable "gcp_address_name" {
  description = "Name of the reserved public IP for the Pharos instance."
  type        = string
  default     = "pharos-llight-io-ip"
}

variable "gcp_instance_name" {
  description = "GCP instance resource name. GCE names cannot contain dots, so this is the RFC1035-safe form of pharos.llight.io."
  type        = string
  default     = "pharos-llight-io"
}

variable "gcp_inventory_host_name" {
  description = "host_name value to write for the web0 inventory entry."
  type        = string
  default     = "pharos01"
}

variable "gcp_machine_type" {
  description = "GCP machine type for the Pharos instance."
  type        = string
  default     = "e2-medium"
}

variable "gcp_instance_tags" {
  description = "Optional network tags to assign to the GCP instance."
  type        = list(string)
  default     = []
}

variable "devops_ssh_public_key_path" {
  description = "Path to the devops public SSH key used for GCP SSH access."
  type        = string
  default     = "../keys/ssh/devops.llight.io.pub"
}
