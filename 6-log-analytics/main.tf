locals {
  tags = {
    Project   = "az-networking-lab"
    Lab       = "6-log-analytics"
    ManagedBy = "terraform"
  }

  # cloud-init: install nginx, generate HTTP traffic every minute so NSG & syslog fill up
  cloud_init = <<-EOT
    #cloud-config
    packages:
      - nginx
      - curl
    runcmd:
      - systemctl enable --now nginx
      - echo "* * * * * azureuser curl -s http://localhost/ > /dev/null" >> /etc/crontab
      - echo "* * * * * azureuser curl -s http://10.6.1.1/ > /dev/null" >> /etc/crontab
  EOT
}

# ── Resource Group ──────────────────────────────────────────────────────────────

resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-6-log-analytics-rg"
  location = var.location
  tags     = local.tags
}

# ── Log Analytics Workspace ─────────────────────────────────────────────────────
# PerGB2018: first 5 GB/day free, then ~$2.30/GB. 30-day retention is included.

resource "azurerm_log_analytics_workspace" "law" {
  name                = "${var.prefix}-6-law"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
  tags                = local.tags
}

# ── Networking ──────────────────────────────────────────────────────────────────

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-6-vnet"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.6.0.0/16"]
  tags                = local.tags
}

resource "azurerm_subnet" "frontend" {
  name                 = "sn-frontend"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.6.1.0/24"]
}

resource "azurerm_network_security_group" "frontend" {
  name                = "${var.prefix}-6-nsg-frontend"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.tags

  security_rule {
    name                       = "allow-ssh"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "allow-http"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "80"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  security_rule {
    name                       = "deny-all-inbound"
    priority                   = 4000
    direction                  = "Inbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_subnet_network_security_group_association" "frontend" {
  subnet_id                 = azurerm_subnet.frontend.id
  network_security_group_id = azurerm_network_security_group.frontend.id
}

# NSG diagnostic logs → Log Analytics
# Captures: which rules fired (Event) and how many times each rule matched (RuleCounter)
resource "azurerm_monitor_diagnostic_setting" "nsg" {
  name                       = "nsg-to-law"
  target_resource_id         = azurerm_network_security_group.frontend.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.law.id

  enabled_log {
    category = "NetworkSecurityGroupEvent"
  }

  enabled_log {
    category = "NetworkSecurityGroupRuleCounter"
  }
}

# ── Virtual Machine ─────────────────────────────────────────────────────────────

resource "azurerm_public_ip" "vm" {
  name                = "${var.prefix}-6-pip-vm"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = local.tags
}

resource "azurerm_network_interface" "vm" {
  name                = "${var.prefix}-6-nic-vm"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.tags

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.frontend.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = azurerm_public_ip.vm.id
  }
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                            = "${var.prefix}-6-vm"
  location                        = azurerm_resource_group.rg.location
  resource_group_name             = azurerm_resource_group.rg.name
  size                            = "Standard_B1s"
  admin_username                  = "azureuser"
  disable_password_authentication = var.ssh_public_key != ""
  tags                            = local.tags

  network_interface_ids = [azurerm_network_interface.vm.id]

  dynamic "admin_ssh_key" {
    for_each = var.ssh_public_key != "" ? [1] : []
    content {
      username   = "azureuser"
      public_key = var.ssh_public_key
    }
  }

  # fallback: password auth when no SSH key provided (not recommended for production)
  admin_password = var.ssh_public_key == "" ? "Lab@2024!Change" : null

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

  # SystemAssigned identity required for Azure Monitor Agent
  identity {
    type = "SystemAssigned"
  }

  custom_data = base64encode(local.cloud_init)
}

# ── Azure Monitor Agent ─────────────────────────────────────────────────────────

resource "azurerm_virtual_machine_extension" "ama" {
  name                       = "AzureMonitorLinuxAgent"
  virtual_machine_id         = azurerm_linux_virtual_machine.vm.id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorLinuxAgent"
  type_handler_version       = "1.0"
  auto_upgrade_minor_version = true
  tags                       = local.tags

  depends_on = [azurerm_linux_virtual_machine.vm]
}

# Data Collection Rule: syslog (auth/kern/syslog warnings+) and perf counters (60s)
resource "azurerm_monitor_data_collection_rule" "dcr" {
  name                = "${var.prefix}-6-dcr"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = local.tags

  destinations {
    log_analytics {
      workspace_resource_id = azurerm_log_analytics_workspace.law.id
      name                  = "law-destination"
    }
  }

  data_flow {
    streams      = ["Microsoft-Syslog", "Microsoft-Perf"]
    destinations = ["law-destination"]
  }

  data_sources {
    syslog {
      facility_names = ["auth", "kern", "syslog"]
      log_levels     = ["Warning", "Error", "Critical", "Alert", "Emergency"]
      name           = "syslog-source"
      streams        = ["Microsoft-Syslog"]
    }

    performance_counter {
      streams                       = ["Microsoft-Perf"]
      sampling_frequency_in_seconds = 60
      counter_specifiers = [
        "\\Processor Information(_Total)\\% Processor Time",
        "\\Memory\\Available Bytes",
        "\\Network Interface(*)\\Bytes Total/sec",
        "\\Logical Disk(*)\\% Free Space",
      ]
      name = "perf-source"
    }
  }
}

resource "azurerm_monitor_data_collection_rule_association" "dcra" {
  name                    = "${var.prefix}-6-dcra"
  target_resource_id      = azurerm_linux_virtual_machine.vm.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.dcr.id
}
