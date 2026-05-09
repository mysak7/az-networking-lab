variable "prefix" {
  default     = "mi"
  description = "Prefix for all resource names — must be lowercase alphanumeric"
}

variable "location" {
  default     = "swedencentral"
  description = "Azure region"
}

variable "ssh_public_key" {
  description = "SSH public key for azureuser on the VM (e.g. file(\"~/.ssh/id_rsa.pub\"))"
  default     = ""
}
