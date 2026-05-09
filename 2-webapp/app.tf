resource "azurerm_service_plan" "plan" {
  name                = "${var.prefix}-webapp-plan"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  sku_name            = var.app_service_sku_name
}

# Frontend — publicly reachable only through App Gateway (WAF)
resource "azurerm_linux_web_app" "frontend" {
  name                      = "${var.prefix}-frontend-${random_string.suffix.result}"
  location                  = azurerm_resource_group.rg.location
  resource_group_name       = azurerm_resource_group.rg.name
  service_plan_id           = azurerm_service_plan.plan.id
  https_only                = true
  virtual_network_subnet_id = azurerm_subnet.frontend.id

  identity {
    type = "SystemAssigned"
  }

  site_config {
    minimum_tls_version           = "1.2"
    ip_restriction_default_action = "Deny"

    # Only allow inbound from App Gateway subnet (service endpoint enforces VNet origin)
    ip_restriction {
      name                      = "AllowAppGateway"
      action                    = "Allow"
      priority                  = 100
      virtual_network_subnet_id = azurerm_subnet.appgw.id
    }

    application_stack {
      node_version = "18-lts"
    }
  }

  app_settings = {
    BACKEND_URL              = "https://${azurerm_linux_web_app.backend.default_hostname}"
    WEBSITE_RUN_FROM_PACKAGE = "1"
  }
}

# Backend API — reachable only from frontend VNet integration subnet
resource "azurerm_linux_web_app" "backend" {
  name                      = "${var.prefix}-backend-${random_string.suffix.result}"
  location                  = azurerm_resource_group.rg.location
  resource_group_name       = azurerm_resource_group.rg.name
  service_plan_id           = azurerm_service_plan.plan.id
  https_only                = true
  virtual_network_subnet_id = azurerm_subnet.backend.id

  identity {
    type = "SystemAssigned"
  }

  site_config {
    minimum_tls_version           = "1.2"
    ip_restriction_default_action = "Deny"

    # Frontend calls backend via VNet integration — outbound IPs come from frontend-subnet
    ip_restriction {
      name       = "AllowFrontendSubnet"
      action     = "Allow"
      priority   = 100
      ip_address = "10.0.2.0/24"
    }

    application_stack {
      node_version = "18-lts"
    }
  }

  app_settings = {
    STORAGE_ACCOUNT_NAME = azurerm_storage_account.storage.name
    STORAGE_BLOB_ENDPOINT = azurerm_storage_account.storage.primary_blob_endpoint
    # Key Vault reference — Azure resolves this at runtime using the app's managed identity
    STORAGE_CONNECTION_STRING = "@Microsoft.KeyVault(SecretUri=${azurerm_key_vault_secret.storage_connection.versionless_id})"
    WEBSITE_RUN_FROM_PACKAGE  = "1"
  }
}
