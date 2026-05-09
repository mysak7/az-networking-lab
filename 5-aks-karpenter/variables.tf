variable "prefix" {
  default     = "mi"
  description = "Prefix for all resource names — must be lowercase alphanumeric"
}

variable "location" {
  default     = "swedencentral"
  description = "Azure region"
}

variable "subscription_id" {
  description = "Azure Subscription ID — set via TF_VAR_subscription_id or ARM_SUBSCRIPTION_ID env var"
}
