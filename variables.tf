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
  default     = "Standard_DS1_v2"
  description = "VM size — DS1_v2 is cheap on-demand (1 vCPU, 3.5GB) from standardDSv2Family which has broad quota availability"
}
