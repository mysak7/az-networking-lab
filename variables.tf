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
  default     = "Standard_B2s_v2"
  description = "VM size — B2s_v2 is cheap on-demand (2 vCPU, 4GB) and widely available in East US 2"
}
