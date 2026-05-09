variable "prefix" {
  default     = "mi"
  description = "Prefix for resource names — lowercase alphanumeric"
}

variable "location" {
  default     = "eastus2"
  description = "Azure region"
}

variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID for mysak.fun — found in the Cloudflare dashboard Overview tab, right side panel"
}

variable "subdomain" {
  default     = "cloudfire"
  description = "Subdomain to create — results in cloudfire.mysak.fun"
}

variable "root_domain" {
  default     = "mysak.fun"
  description = "Root domain managed in Cloudflare"
}

variable "cloudflare_api_token" {
  description = "Cloudflare API token — set via TF_VAR_cloudflare_api_token or CLOUDFLARE_API_TOKEN env var"
  sensitive   = true
}
