output "resource_group_name" {
  value = azurerm_resource_group.rg.name
}

output "app_service_name" {
  value = azurerm_linux_web_app.app.name
}

output "public_url" {
  value       = "https://${local.fqdn}"
  description = "Public entry point — traffic passes through Cloudflare CDN + DDoS"
}

output "app_service_direct_url" {
  value       = "https://${azurerm_linux_web_app.app.default_hostname}"
  description = "Direct App Service URL — blocked (Cloudflare IPs only)"
}

output "cloudflare_cname_target" {
  value       = azurerm_linux_web_app.app.default_hostname
  description = "CNAME value in Cloudflare DNS → this azurewebsites.net hostname"
}

output "domain_verification_id" {
  value       = azurerm_linux_web_app.app.custom_domain_verification_id
  description = "App Service domain verification ID — stored in asuid TXT record"
  sensitive   = true
}

output "log_analytics_workspace_id" {
  value       = azurerm_log_analytics_workspace.law.id
  description = "Log Analytics Workspace resource ID"
}

output "log_analytics_portal_url" {
  value       = "https://portal.azure.com/#resource${azurerm_log_analytics_workspace.law.id}/logs"
  description = "Direct link to Log Analytics query blade in Azure Portal"
}
