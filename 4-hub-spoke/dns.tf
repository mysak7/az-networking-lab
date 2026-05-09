locals {
  private_dns_zones = toset([
    "privatelink.blob.core.windows.net",
    "privatelink.vaultcore.azure.net",
  ])
}

resource "azurerm_private_dns_zone" "this" {
  for_each            = local.private_dns_zones
  name                = each.key
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "hub" {
  for_each = local.private_dns_zones

  name                  = "link-hub-${replace(each.key, ".", "-")}"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.this[each.key].name
  virtual_network_id    = azurerm_virtual_network.hub.id
  registration_enabled  = false
  tags                  = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "spoke_app" {
  for_each = local.private_dns_zones

  name                  = "link-spoke-app-${replace(each.key, ".", "-")}"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.this[each.key].name
  virtual_network_id    = azurerm_virtual_network.spoke_app.id
  registration_enabled  = false
  tags                  = local.tags
}

resource "azurerm_private_dns_zone_virtual_network_link" "spoke_mgmt" {
  for_each = local.private_dns_zones

  name                  = "link-spoke-mgmt-${replace(each.key, ".", "-")}"
  resource_group_name   = azurerm_resource_group.rg.name
  private_dns_zone_name = azurerm_private_dns_zone.this[each.key].name
  virtual_network_id    = azurerm_virtual_network.spoke_mgmt.id
  registration_enabled  = false
  tags                  = local.tags
}
