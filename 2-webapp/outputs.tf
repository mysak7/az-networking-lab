output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "app_url" {
  value       = "http://${azurerm_public_ip.appgw_pip.ip_address}"
  description = "Public entry point — traffic passes through WAF + Application Gateway"
}

output "app_gateway_public_ip" {
  value = azurerm_public_ip.appgw_pip.ip_address
}

output "frontend_hostname" {
  value       = azurerm_linux_web_app.frontend.default_hostname
  description = "Frontend App Service hostname (direct access — locked to App Gateway subnet only)"
}

output "backend_hostname" {
  value       = azurerm_linux_web_app.backend.default_hostname
  description = "Backend App Service hostname (direct access — locked to frontend subnet only)"
}

output "storage_account_name" {
  value = azurerm_storage_account.storage.name
}

output "key_vault_uri" {
  value = azurerm_key_vault.kv.vault_uri
}
