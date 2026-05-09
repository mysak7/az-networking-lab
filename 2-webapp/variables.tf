variable "prefix" {
  default     = "mi"
  description = "Prefix for resource names — lowercase alphanumeric for storage/key vault name compatibility"
}

variable "location" {
  default     = "eastus2"
  description = "Azure region"
}

variable "app_service_sku_name" {
  default     = "S1"
  description = "App Service Plan SKU — Standard S1 minimum for Regional VNet Integration"
}
