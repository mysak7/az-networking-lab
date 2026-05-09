locals {
  tags = {
    Project   = "az-networking-lab"
    Lab       = "5-aks-karpenter"
    ManagedBy = "terraform"
  }
}

resource "azurerm_resource_group" "rg" {
  name     = "${var.prefix}-5-aks-karpenter-rg"
  location = var.location
  tags     = local.tags
}

# ── Networking ─────────────────────────────────────────────────────────────────

resource "azurerm_virtual_network" "vnet" {
  name                = "${var.prefix}-vnet-aks"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.10.0.0/16"]
  tags                = local.tags
}

resource "azurerm_subnet" "nodes" {
  name                 = "sn-nodes"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.10.1.0/24"]
}

# ── AKS Cluster ────────────────────────────────────────────────────────────────
# Node Auto-Provisioning (NAP) = managed Karpenter — scales workload nodes
# automatically based on pending pods; system pool runs only control-plane addons.

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "${var.prefix}-5-aks"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  dns_prefix          = "${var.prefix}-5-aks"
  tags                = local.tags

  sku_tier = "Standard"

  oidc_issuer_enabled       = true
  workload_identity_enabled = true

  node_provisioning_profile {
    mode = "Auto"
  }

  default_node_pool {
    name                         = "system"
    node_count                   = 2
    vm_size                      = "Standard_D2s_v3"
    vnet_subnet_id               = azurerm_subnet.nodes.id
    only_critical_addons_enabled = true

    upgrade_settings {
      max_surge = "10%"
    }
  }

  identity {
    type = "SystemAssigned"
  }

  network_profile {
    network_plugin      = "azure"
    network_plugin_mode = "overlay"
    pod_cidr            = "192.168.0.0/16"
    service_cidr        = "172.16.0.0/16"
    dns_service_ip      = "172.16.0.10"
  }
}
