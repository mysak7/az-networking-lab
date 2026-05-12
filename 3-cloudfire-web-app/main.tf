resource "random_string" "suffix" {
  length  = 6
  special = false
  upper   = false
}

data "cloudflare_ip_ranges" "cf" {}

locals {
  app_name       = "${var.prefix}-3-cloudfire-${random_string.suffix.result}"
  fqdn           = "${var.subdomain}.${var.root_domain}"
  cloudflare_ips = concat(data.cloudflare_ip_ranges.cf.ipv4_cidr_blocks, data.cloudflare_ip_ranges.cf.ipv6_cidr_blocks)
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
      node_version = "20-lts"
    }

    app_command_line = "node server.js"

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
    WEBSITES_PORT                  = "8080"
    SCM_DO_BUILD_DURING_DEPLOYMENT = "false"
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

resource "local_file" "server_js" {
  filename = "${path.module}/.deploy/server.js"
  content  = <<-JS
    const http = require('http');
    const fs   = require('fs');
    const path = require('path');
    const PORT = process.env.WEBSITES_PORT || process.env.PORT || 8080;
    const BASE = '/home/site/wwwroot';
    http.createServer((req, res) => {
      const p = req.url === '/' ? 'index.html' : req.url.replace(/^\//, '');
      fs.readFile(path.join(BASE, p), (err, data) => {
        const status = err ? 404 : 200;
        const clientIp = req.headers['cf-connecting-ip'] || req.socket.remoteAddress;
        const cfRay    = req.headers['cf-ray'] || '-';
        console.log(JSON.stringify({ ts: new Date().toISOString(), method: req.method, url: req.url, status, clientIp, cfRay }));
        if (err) { res.writeHead(404); return res.end('Not found'); }
        const mime = p.endsWith('.html') ? 'text/html' : 'text/plain';
        res.writeHead(200, { 'Content-Type': mime });
        res.end(data);
      });
    }).listen(PORT, '0.0.0.0');
  JS
}

resource "local_file" "robots_warmup" {
  filename = "${path.module}/.deploy/robots933456.txt"
  content  = ""
}

# package.json is required for the Node.js App Service container to invoke
# app_command_line ("node server.js") instead of falling back to static file serving.
resource "local_file" "package_json" {
  filename = "${path.module}/.deploy/package.json"
  content  = jsonencode({
    name    = "app"
    version = "1.0.0"
    scripts = { start = "node server.js" }
  })
}

data "archive_file" "app_zip" {
  type        = "zip"
  source_dir  = "${path.module}/.deploy"
  output_path = "${path.module}/app.zip"
  depends_on  = [local_file.index_html, local_file.server_js, local_file.robots_warmup, local_file.package_json]
}

resource "null_resource" "deploy_app" {
  triggers = {
    html_hash    = local_file.index_html.content_md5
    server_hash  = local_file.server_js.content_md5
    package_hash = local_file.package_json.content_md5
  }

  provisioner "local-exec" {
    command = "az webapp deploy --resource-group ${azurerm_resource_group.rg.name} --name ${local.app_name} --src-path ${data.archive_file.app_zip.output_path} --type zip"
  }

  depends_on = [azurerm_linux_web_app.app, data.archive_file.app_zip]
}
