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

variable "pharos_ipv4" {
  description = "Optional IPv4 address for pharos.llight.io. Leave null until the new VPC has a public IP."
  type        = string
  default     = null
}

variable "mail_exchange" {
  description = "Mail exchanger hostname for the root domain."
  type        = string
  default     = "mail.llight.io"
}

variable "mx_preference" {
  description = "Preference value for the root MX record."
  type        = number
  default     = 10
}

variable "dns_ttl" {
  description = "Default TTL for managed DNS records in seconds."
  type        = number
  default     = 3600
}
