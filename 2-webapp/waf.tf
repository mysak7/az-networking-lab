resource "azurerm_public_ip" "appgw_pip" {
  name                = "${var.prefix}-appgw-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

locals {
  backend_pool_name          = "frontend-pool"
  frontend_port_name         = "port-80"
  frontend_ip_config_name    = "appgw-pip-config"
  http_listener_name         = "http-listener"
  routing_rule_name          = "http-routing-rule"
  backend_http_settings_name = "https-backend-settings"
  probe_name                 = "frontend-probe"
}

resource "azurerm_application_gateway" "appgw" {
  name                = "${var.prefix}-appgw"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  sku {
    name     = "WAF_v2"
    tier     = "WAF_v2"
    capacity = 1
  }

  gateway_ip_configuration {
    name      = "appgw-ip-config"
    subnet_id = azurerm_subnet.appgw.id
  }

  frontend_port {
    name = local.frontend_port_name
    port = 80
  }

  frontend_ip_configuration {
    name                 = local.frontend_ip_config_name
    public_ip_address_id = azurerm_public_ip.appgw_pip.id
  }

  # Backend targets the frontend App Service over HTTPS (App Service enforces HTTPS)
  backend_address_pool {
    name  = local.backend_pool_name
    fqdns = [azurerm_linux_web_app.frontend.default_hostname]
  }

  # pick_host_name_from_backend_address is required for App Service SNI to work correctly
  backend_http_settings {
    name                                = local.backend_http_settings_name
    cookie_based_affinity               = "Disabled"
    port                                = 443
    protocol                            = "Https"
    request_timeout                     = 30
    pick_host_name_from_backend_address = true
    probe_name                          = local.probe_name
  }

  # Accept 200-499 so a fresh App Service (which returns 403) is still considered healthy
  probe {
    name                                      = local.probe_name
    protocol                                  = "Https"
    path                                      = "/"
    interval                                  = 30
    timeout                                   = 30
    unhealthy_threshold                       = 3
    pick_host_name_from_backend_http_settings = true

    match {
      status_code = ["200-499"]
    }
  }

  http_listener {
    name                           = local.http_listener_name
    frontend_ip_configuration_name = local.frontend_ip_config_name
    frontend_port_name             = local.frontend_port_name
    protocol                       = "Http"
  }

  request_routing_rule {
    name                       = local.routing_rule_name
    rule_type                  = "Basic"
    priority                   = 100
    http_listener_name         = local.http_listener_name
    backend_address_pool_name  = local.backend_pool_name
    backend_http_settings_name = local.backend_http_settings_name
  }

  # OWASP 3.2 rules in Prevention mode — blocks known exploits (SQLi, XSS, RFI, LFI, etc.)
  waf_configuration {
    enabled                  = true
    firewall_mode            = "Prevention"
    rule_set_type            = "OWASP"
    rule_set_version         = "3.2"
    request_body_check       = true
    max_request_body_size_kb = 128
    file_upload_limit_mb     = 100
  }
}
