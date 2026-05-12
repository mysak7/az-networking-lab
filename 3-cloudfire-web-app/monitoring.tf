resource "azurerm_log_analytics_workspace" "law" {
  name                = "${var.prefix}-3-cloudfire-law"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

# App Service diagnostic logs → Log Analytics
# AppServiceHTTPLogs      — every HTTP request: method, URI, status, duration, client IP (Cloudflare)
# AppServiceConsoleLogs   — Node.js stdout/stderr
# AppServiceIPSecAuditLogs — which IP restriction rule allowed/blocked each request
# AppServicePlatformLogs  — deployment and platform events
resource "azurerm_monitor_diagnostic_setting" "app" {
  name                       = "app-to-law"
  target_resource_id         = azurerm_linux_web_app.app.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  enabled_log { category = "AppServiceHTTPLogs" }
  enabled_log { category = "AppServiceConsoleLogs" }
  enabled_log { category = "AppServiceIPSecAuditLogs" }
  enabled_log { category = "AppServicePlatformLogs" }

  metric {
    category = "AllMetrics"
  }
}
