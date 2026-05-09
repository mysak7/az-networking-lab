output "hub_vnet_id" {
  description = "Resource ID of the Hub VNet."
  value       = azurerm_virtual_network.hub.id
}

output "spoke_app_vnet_id" {
  description = "Resource ID of the App Spoke VNet."
  value       = azurerm_virtual_network.spoke_app.id
}

output "spoke_mgmt_vnet_id" {
  description = "Resource ID of the Management Spoke VNet."
  value       = azurerm_virtual_network.spoke_mgmt.id
}

output "spoke_app_subnet_ids" {
  description = "Subnet IDs in the App Spoke VNet."
  value       = { for k, v in azurerm_subnet.spoke_app : k => v.id }
}

output "private_dns_zone_ids" {
  description = "Resource IDs of the private DNS zones."
  value       = { for k, v in azurerm_private_dns_zone.this : k => v.id }
}
