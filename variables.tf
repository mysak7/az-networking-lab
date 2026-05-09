variable "prefix" {
  default     = "mi"
  description = "Prefix for all resource names — must be lowercase alphanumeric for storage account compatibility"
}

variable "location" {
  default     = "eastus2"
  description = "Azure region — East US 2 has some of the cheapest spot pricing"
}

variable "admin_username" {
  default     = "azureuser"
  description = "Admin username for the virtual machine"
}

variable "vm_size" {
  default     = "Standard_D2as_v4"
  description = "VM size — D2as_v4 is cheap and widely available as spot in East US 2"
}
