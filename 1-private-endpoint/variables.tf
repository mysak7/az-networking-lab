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
  default     = "Standard_D2als_v7"
  description = "VM size — D2als_v7 is cheap on-demand (2 vCPU, 4GB AMD) confirmed available in eastus2 with no capacity/quota restrictions"
}
