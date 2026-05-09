locals {
  # storage account names must be lowercase alphanumeric, globally unique
  storage_name = "${var.prefix}learnnetdiag"
}

# Create resource group
resource "azurerm_resource_group" "mi_rg" {
  name     = "${var.prefix}-learn-net-rg"
  location = var.location
}

# Create virtual network
resource "azurerm_virtual_network" "mi_vnet" {
  name                = "${var.prefix}-vnet"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.mi_rg.location
  resource_group_name = azurerm_resource_group.mi_rg.name
}

# Create subnet for VMs
resource "azurerm_subnet" "mi_subnet" {
  name                 = "${var.prefix}-subnet"
  resource_group_name  = azurerm_resource_group.mi_rg.name
  virtual_network_name = azurerm_virtual_network.mi_vnet.name
  address_prefixes     = ["10.0.1.0/24"]
}

# Dedicated subnet for private endpoints (network policies must be disabled)
resource "azurerm_subnet" "mi_pe_subnet" {
  name                 = "${var.prefix}-pe-subnet"
  resource_group_name  = azurerm_resource_group.mi_rg.name
  virtual_network_name = azurerm_virtual_network.mi_vnet.name
  address_prefixes     = ["10.0.2.0/24"]

  private_endpoint_network_policies = "Disabled"
}

# Create public IP
resource "azurerm_public_ip" "mi_public_ip" {
  name                = "${var.prefix}-public-ip"
  location            = azurerm_resource_group.mi_rg.location
  resource_group_name = azurerm_resource_group.mi_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Create Network Security Group — allow SSH inbound
resource "azurerm_network_security_group" "mi_nsg" {
  name                = "${var.prefix}-nsg"
  location            = azurerm_resource_group.mi_rg.location
  resource_group_name = azurerm_resource_group.mi_rg.name

  security_rule {
    name                       = "SSH"
    priority                   = 1001
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

# Create network interface
resource "azurerm_network_interface" "mi_nic" {
  name                = "${var.prefix}-nic"
  location            = azurerm_resource_group.mi_rg.location
  resource_group_name = azurerm_resource_group.mi_rg.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.mi_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.mi_public_ip.id
  }
}

# Connect the security group to the network interface
resource "azurerm_network_interface_security_group_association" "nsg-nic-association" {
  network_interface_id      = azurerm_network_interface.mi_nic.id
  network_security_group_id = azurerm_network_security_group.mi_nsg.id
}

# Create storage account for boot diagnostics
resource "azurerm_storage_account" "mi_storage_account" {
  name                     = local.storage_name
  location                 = azurerm_resource_group.mi_rg.location
  resource_group_name      = azurerm_resource_group.mi_rg.name
  account_tier             = "Standard"
  account_replication_type = "LRS"

  # deny all public access; private endpoint handles VNet access
  # AzureServices bypass allows boot diagnostics to be written by Azure platform
  network_rules {
    default_action = "Deny"
    bypass         = ["AzureServices"]
  }
}

# Create spot Linux virtual machine
resource "azurerm_linux_virtual_machine" "mi_vm" {
  name                            = "${var.prefix}-learn-vm"
  location                        = azurerm_resource_group.mi_rg.location
  resource_group_name             = azurerm_resource_group.mi_rg.name
  size                            = var.vm_size
  admin_username                  = var.admin_username
  disable_password_authentication = true

  network_interface_ids = [
    azurerm_network_interface.mi_nic.id,
  ]

  admin_ssh_key {
    username   = var.admin_username
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  boot_diagnostics {
    storage_account_uri = azurerm_storage_account.mi_storage_account.primary_blob_endpoint
  }
}

# Create Azure AD application for the service principal
resource "azuread_application" "mi_app" {
  display_name = "${var.prefix}-learn-app"
}

# Create service principal
resource "azuread_service_principal" "mi_sp" {
  client_id = azuread_application.mi_app.client_id
}

# Create service principal password (client secret)
resource "azuread_service_principal_password" "mi_sp_password" {
  service_principal_id = azuread_service_principal.mi_sp.id
}

# Get current subscription for role scope
data "azurerm_subscription" "current" {}

# Assign Contributor role to service principal on resource group
resource "azurerm_role_assignment" "mi_sp_role" {
  scope                = azurerm_resource_group.mi_rg.id
  role_definition_name = "Contributor"
  principal_id         = azuread_service_principal.mi_sp.object_id
}

# Private DNS zone — resolves storage FQDN to private IP inside the VNet
resource "azurerm_private_dns_zone" "mi_dns_zone" {
  name                = "privatelink.blob.core.windows.net"
  resource_group_name = azurerm_resource_group.mi_rg.name
}

# Link DNS zone to the VNet so VMs can resolve private storage FQDN
resource "azurerm_private_dns_zone_virtual_network_link" "mi_dns_link" {
  name                  = "${var.prefix}-dns-link"
  resource_group_name   = azurerm_resource_group.mi_rg.name
  private_dns_zone_name = azurerm_private_dns_zone.mi_dns_zone.name
  virtual_network_id    = azurerm_virtual_network.mi_vnet.id
  registration_enabled  = false
}

# Private endpoint — gives storage a private IP (10.0.2.x) inside mi_pe_subnet
resource "azurerm_private_endpoint" "mi_storage_pe" {
  name                = "${var.prefix}-storage-pe"
  location            = azurerm_resource_group.mi_rg.location
  resource_group_name = azurerm_resource_group.mi_rg.name
  subnet_id           = azurerm_subnet.mi_pe_subnet.id

  private_service_connection {
    name                           = "${var.prefix}-storage-psc"
    private_connection_resource_id = azurerm_storage_account.mi_storage_account.id
    subresource_names              = ["blob"]
    is_manual_connection           = false
  }

  private_dns_zone_group {
    name                 = "default"
    private_dns_zone_ids = [azurerm_private_dns_zone.mi_dns_zone.id]
  }
}
