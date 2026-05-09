output "resource_group_name" {
  value = azurerm_resource_group.mi_rg.name
}

output "public_ip_address" {
  value = azurerm_public_ip.mi_public_ip.ip_address
}

output "vm_name" {
  value = azurerm_linux_virtual_machine.mi_vm.name
}

output "ssh_command" {
  value = "ssh ${var.admin_username}@${azurerm_public_ip.mi_public_ip.ip_address}"
}

output "service_principal_client_id" {
  value     = azuread_application.mi_app.client_id
  sensitive = true
}

output "service_principal_client_secret" {
  value     = azuread_service_principal_password.mi_sp_password.value
  sensitive = true
}
