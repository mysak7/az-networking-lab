resource "cloudflare_dns_record" "cname" {
  zone_id = var.cloudflare_zone_id
  name    = var.subdomain
  content = azurerm_linux_web_app.app.default_hostname
  type    = "CNAME"
  proxied = true
  ttl     = 1
}

resource "cloudflare_dns_record" "verify_txt" {
  zone_id = var.cloudflare_zone_id
  name    = "asuid.${var.subdomain}"
  content = azurerm_linux_web_app.app.custom_domain_verification_id
  type    = "TXT"
  proxied = false
  ttl     = 60
}

resource "cloudflare_zone_setting" "ssl" {
  zone_id    = var.cloudflare_zone_id
  setting_id = "ssl"
  value      = "strict"
}

resource "cloudflare_zone_setting" "min_tls_version" {
  zone_id    = var.cloudflare_zone_id
  setting_id = "min_tls_version"
  value      = "1.2"
}

resource "cloudflare_zone_setting" "always_use_https" {
  zone_id    = var.cloudflare_zone_id
  setting_id = "always_use_https"
  value      = "on"
}

resource "cloudflare_ruleset" "rate_limit" {
  zone_id = var.cloudflare_zone_id
  name    = "Rate Limiting"
  kind    = "zone"
  phase   = "http_ratelimit"

  rules = [
    {
      action      = "block"
      description = "Block IPs exceeding 100 req/min"
      enabled     = true
      expression  = "true"
      action_parameters = {
        response = {
          status_code  = 429
          content_type = "text/plain"
          content      = "Too many requests"
        }
      }
      ratelimit = {
        characteristics     = ["cf.colo.id", "ip.src"]
        period              = 60
        requests_per_period = 100
        mitigation_timeout  = 60
      }
    }
  ]
}
