# CNAME: cloudfire.mysak.fun → <appservice>.azurewebsites.net (proxied)
# The orange-cloud proxy means Cloudflare terminates TLS for the browser;
# Cloudflare then connects to azurewebsites.net over HTTPS (Full SSL mode).
resource "cloudflare_record" "cname" {
  zone_id = var.cloudflare_zone_id
  name    = var.subdomain
  value   = azurerm_linux_web_app.app.default_hostname
  type    = "CNAME"
  proxied = true
  ttl     = 1 # must be 1 (auto) when proxied
}

# TXT record for App Service custom domain verification.
# asuid.<subdomain> → App Service verification ID.
# Using TXT (not CNAME) so verification works while the CNAME is already proxied.
resource "cloudflare_record" "verify_txt" {
  zone_id = var.cloudflare_zone_id
  name    = "asuid.${var.subdomain}"
  value   = azurerm_linux_web_app.app.custom_domain_verification_id
  type    = "TXT"
  proxied = false
  ttl     = 60
}

# Zone-wide SSL mode: Full — Cloudflare encrypts to the origin but does not
# validate the cert. The origin presents *.azurewebsites.net which won't match
# cloudfire.mysak.fun, so Full (Strict) would fail. Full is the correct choice here.
# NOTE: this setting applies to the entire mysak.fun zone.
resource "cloudflare_zone_settings_override" "ssl" {
  zone_id = var.cloudflare_zone_id
  settings {
    ssl            = "full"
    min_tls_version = "1.2"
    # Always redirect HTTP → HTTPS at Cloudflare edge
    always_use_https = "on"
  }
}
