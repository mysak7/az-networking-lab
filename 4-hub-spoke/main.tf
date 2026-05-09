locals {
  tags = {
    Project   = "az-networking-lab"
    Lab       = "4-hub-spoke"
    ManagedBy = "terraform"
  }

  spoke_app_subnets = {
    web = { name = "sn-web", cidr = "10.1.1.0/24" }
    app = { name = "sn-app", cidr = "10.1.2.0/24" }
    pep = { name = "sn-pep", cidr = "10.1.3.0/24" }
  }
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-4-hub-spoke-rg"
  location = var.location
  tags     = local.tags
}

# ── Hub VNet ─────────────────────────────────────────────────────────────────

resource "azurerm_virtual_network" "hub" {
  name                = "${var.prefix}-vnet-hub"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.0.0.0/16"]
  tags                = local.tags
}

resource "azurerm_subnet" "hub_shared" {
  name                 = "sn-shared"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.0.1.0/24"]
}

resource "azurerm_subnet" "hub_dns" {
  name                 = "sn-dns"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.hub.name
  address_prefixes     = ["10.0.2.0/24"]
}

# ── App Spoke VNet ────────────────────────────────────────────────────────────

resource "azurerm_virtual_network" "spoke_app" {
  name                = "${var.prefix}-vnet-spoke-app"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.1.0.0/16"]
  tags                = local.tags
}

resource "azurerm_subnet" "spoke_app" {
  for_each = local.spoke_app_subnets

  name                 = each.value.name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.spoke_app.name
  address_prefixes     = [each.value.cidr]
}

# ── Mgmt Spoke VNet ───────────────────────────────────────────────────────────

resource "azurerm_virtual_network" "spoke_mgmt" {
  name                = "${var.prefix}-vnet-spoke-mgmt"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.2.0.0/16"]
  tags                = local.tags
}

resource "azurerm_subnet" "spoke_mgmt" {
  name                 = "sn-tools"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.spoke_mgmt.name
  address_prefixes     = ["10.2.1.0/24"]
}

# ── NSGs ──────────────────────────────────────────────────────────────────────

resource "azurerm_network_security_group" "spoke_app" {
  name                = "${var.prefix}-nsg-spoke-app"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.tags
}

resource "azurerm_network_security_group" "spoke_mgmt" {
  name                = "${var.prefix}-nsg-spoke-mgmt"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.tags
}

resource "azurerm_subnet_network_security_group_association" "spoke_app" {
  for_each = local.spoke_app_subnets

  subnet_id                 = azurerm_subnet.spoke_app[each.key].id
  network_security_group_id = azurerm_network_security_group.spoke_app.id
}

resource "azurerm_subnet_network_security_group_association" "spoke_mgmt" {
  subnet_id                 = azurerm_subnet.spoke_mgmt.id
  network_security_group_id = azurerm_network_security_group.spoke_mgmt.id
}

# ── VNet Peering (hub ↔ app, hub ↔ mgmt) ─────────────────────────────────────

resource "azurerm_virtual_network_peering" "hub_to_spoke_app" {
  name                         = "peer-hub-to-spoke-app"
  resource_group_name          = azurerm_resource_group.rg.name
  virtual_network_name         = azurerm_virtual_network.hub.name
  remote_virtual_network_id    = azurerm_virtual_network.spoke_app.id
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
}

resource "azurerm_virtual_network_peering" "spoke_app_to_hub" {
  name                         = "peer-spoke-app-to-hub"
  resource_group_name          = azurerm_resource_group.rg.name
  virtual_network_name         = azurerm_virtual_network.spoke_app.name
  remote_virtual_network_id    = azurerm_virtual_network.hub.id
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
}

resource "azurerm_virtual_network_peering" "hub_to_spoke_mgmt" {
  name                         = "peer-hub-to-spoke-mgmt"
  resource_group_name          = azurerm_resource_group.rg.name
  virtual_network_name         = azurerm_virtual_network.hub.name
  remote_virtual_network_id    = azurerm_virtual_network.spoke_mgmt.id
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
}

resource "azurerm_virtual_network_peering" "spoke_mgmt_to_hub" {
  name                         = "peer-spoke-mgmt-to-hub"
  resource_group_name          = azurerm_resource_group.rg.name
  virtual_network_name         = azurerm_virtual_network.spoke_mgmt.name
  remote_virtual_network_id    = azurerm_virtual_network.hub.id
  allow_forwarded_traffic      = true
  allow_virtual_network_access = true
}
