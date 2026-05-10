resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

locals {
  app_name = "${var.prefix}-3-cloudfire-${random_string.suffix.result}"
  fqdn     = "${var.subdomain}.${var.root_domain}"

  # Cloudflare published IP ranges — https://www.cloudflare.com/ips/
  # Keep in sync with cloudflare.com/ips if ranges change
  cloudflare_ips = [
    "173.245.48.0/20",
    "103.21.244.0/22",
    "103.22.200.0/22",
    "103.31.4.0/22",
    "141.101.64.0/18",
    "108.162.192.0/18",
    "190.93.240.0/20",
    "188.114.96.0/20",
    "197.234.240.0/22",
    "198.41.128.0/17",
    "162.158.0.0/15",
    "104.16.0.0/13",
    "104.24.0.0/14",
    "172.64.0.0/13",
    "131.0.72.0/22",
    "2400:cb00::/32",
    "2606:4700::/32",
    "2803:f800::/32",
    "2405:b500::/32",
    "2405:8100::/32",
    "2a06:98c0::/29",
    "2c0f:f248::/32",
  ]
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-3-cloudfire-rg"
  location = var.location
}

resource "azurerm_service_plan" "plan" {
  name                = "${var.prefix}-3-cloudfire-plan"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  sku_name            = "B1"
}

resource "azurerm_linux_web_app" "app" {
  name                = local.app_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.plan.id
  https_only          = true

  site_config {
    minimum_tls_version           = "1.2"
    ip_restriction_default_action = "Deny"

    application_stack {
      python_version = "3.11"
    }

    app_command_line = "python3 -m http.server 8080 --bind 0.0.0.0 --directory /home/site/wwwroot"

    # SCM (Kudu/deploy endpoint) keeps separate open restrictions so
    # az webapp deploy below is not blocked by the main-site rule.
    scm_use_main_ip_restriction = false

    # Allow Azure's internal warmup/health probe (168.63.129.16 is Azure's platform IP)
    ip_restriction {
      name       = "azure-platform"
      action     = "Allow"
      priority   = 50
      ip_address = "168.63.129.16/32"
    }

    # Allow only Cloudflare IPs — direct access to azurewebsites.net is blocked
    dynamic "ip_restriction" {
      for_each = { for idx, ip in local.cloudflare_ips : ip => idx }
      content {
        name       = "CF-${ip_restriction.value}"
        action     = "Allow"
        priority   = 100 + ip_restriction.value
        ip_address = ip_restriction.key
      }
    }
  }

  app_settings = {
    WEBSITES_PORT = "8080"
  }
}

# Custom domain binding — TXT record (asuid.*) is used for verification so
# it works even with Cloudflare proxy (orange cloud) switched on from day 1.
resource "azurerm_app_service_custom_hostname_binding" "cloudfire" {
  hostname            = local.fqdn
  app_service_name    = azurerm_linux_web_app.app.name
  resource_group_name = azurerm_resource_group.rg.name
  depends_on          = [cloudflare_dns_record.verify_txt]
}

# ── Landing page deployment ──────────────────────────────────────────────────
# Writes landing.html into .deploy/, zips it, pushes via az webapp deploy.

resource "local_file" "index_html" {
  filename = "${path.module}/.deploy/index.html"
  content  = file("${path.module}/landing.html")
}

# Empty requirements.txt so Oryx recognises this as a Python app and
# runs app_command_line instead of the default hostingstart handler.
resource "local_file" "requirements_txt" {
  filename = "${path.module}/.deploy/requirements.txt"
  content  = ""
}

data "archive_file" "app_zip" {
  type        = "zip"
  source_dir  = "${path.module}/.deploy"
  output_path = "${path.module}/app.zip"
  depends_on  = [local_file.index_html, local_file.requirements_txt]
}

resource "null_resource" "deploy_app" {
  triggers = {
    html_hash = local_file.index_html.content_md5
  }

  provisioner "local-exec" {
    command = "az webapp deploy --resource-group ${azurerm_resource_group.rg.name} --name ${local.app_name} --src-path ${data.archive_file.app_zip.output_path} --type zip --async true"
  }

  depends_on = [azurerm_linux_web_app.app, data.archive_file.app_zip]
}
