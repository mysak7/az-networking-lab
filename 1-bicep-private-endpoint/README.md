# 1-bicep-private-endpoint

Deploys a VM in East US 2 with a full network stack, a storage account behind a private endpoint, and private DNS resolution — written in Bicep. Same infrastructure as the Terraform version in `../3-cloudfire-web-app`.

## What this builds

| Resource | Details |
|---|---|
| Resource Group | `mi-learn-net-rg` in East US 2 |
| Virtual Network | `10.0.0.0/16` |
| VM Subnet | `10.0.1.0/24` |
| PE Subnet | `10.0.2.0/24`, network policies disabled |
| NSG | Inbound SSH (port 22) allowed |
| Public IP | Static, Standard SKU |
| NIC | VM subnet + public IP + NSG attached inline |
| Storage Account | Standard LRS, public access denied, AzureServices bypass |
| Linux VM | Ubuntu 22.04, `Standard_D2als_v7`, SSH key auth, boot diagnostics |
| Private DNS Zone | `privatelink.blob.core.windows.net` |
| Private DNS Zone VNet Link | Links zone to VNet for internal FQDN resolution |
| Private Endpoint | Blob subresource, private IP in PE subnet (`10.0.2.x`) |

---

## Prerequisites

### 1. Install Azure CLI

```bash
# Ubuntu / Debian
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

# Verify
az --version
```

### 2. Install Bicep

```bash
az bicep install
az bicep version
```

### 3. Log in to Azure

```bash
az login
```

### 4. Select your subscription

```bash
# List available subscriptions
az account list --output table

# Set the one you want to use
az account set --subscription <your-subscription-id>

# Confirm
az account show --output table
```

### 5. SSH key

The VM uses SSH key authentication. Make sure you have a key pair:

```bash
# Generate one if you don't have it yet
ssh-keygen -t rsa -b 4096 -f ~/.ssh/id_rsa

# Verify
ls ~/.ssh/id_rsa.pub
```

---

## Deploy

### Dry run (what-if)

Preview what will be created without touching anything:

```bash
az deployment sub what-if \
  --location eastus2 \
  --template-file main.bicep \
  --parameters main.bicepparam \
  --parameters sshPublicKey="$(cat ~/.ssh/id_rsa.pub)"
```

### Full deployment

```bash
az deployment sub create \
  --location eastus2 \
  --template-file main.bicep \
  --parameters main.bicepparam \
  --parameters sshPublicKey="$(cat ~/.ssh/id_rsa.pub)"
```

This takes ~3-5 minutes. When it finishes, outputs are printed automatically.

### Watch deployment progress (optional second terminal)

```bash
az deployment sub list --output table
```

---

## After deployment

### Get outputs

```bash
az deployment sub show \
  --name main \
  --query 'properties.outputs' \
  --output json
```

You'll get:
- `publicIpAddress` — VM's public IP
- `vmName` — VM name
- `sshCommand` — ready-to-paste SSH command

### SSH into the VM

```bash
ssh azureuser@<publicIpAddress>

# Or use the sshCommand output directly:
$(az deployment sub show --name main --query 'properties.outputs.sshCommand.value' --output tsv)
```

### Verify private endpoint DNS resolution (from inside the VM)

Once SSH'd in, run:

```bash
nslookup milearnnetdiag.blob.core.windows.net
```

The address should resolve to `10.0.2.x` (private IP), not the public Azure storage endpoint. This confirms that private DNS is working correctly.

---

## Service principal (optional)

Azure AD resources are not natively supported in Bicep. Run the helper script after deployment to create an app registration and service principal via CLI:

```bash
bash setup-sp.sh mi
```

---

## Teardown

Delete the resource group and everything inside it:

```bash
az group delete --name mi-learn-net-rg --yes --no-wait
```

`--no-wait` returns immediately; deletion runs in the background (~2-3 min).

Verify it's gone:

```bash
az group show --name mi-learn-net-rg
# Should return: ResourceGroupNotFound
```

---

## Parameters reference

Defined in `main.bicepparam`. Override any at deploy time with `--parameters key=value`.

| Parameter | Default | Description |
|---|---|---|
| `prefix` | `mi` | Prefix for all resource names — must be lowercase alphanumeric |
| `location` | `eastus2` | Azure region |
| `adminUsername` | `azureuser` | VM admin username |
| `vmSize` | `Standard_D2als_v7` | VM size (2 vCPU, 4 GB RAM, AMD) |
| `sshPublicKey` | *(required)* | Pass via `sshPublicKey="$(cat ~/.ssh/id_rsa.pub)"` |

---

## Terraform vs Bicep differences

| Aspect | Terraform | Bicep |
|---|---|---|
| State management | `terraform.tfstate` | None — ARM manages state |
| Resource group | `azurerm_resource_group` resource | `Microsoft.Resources/resourceGroups` at subscription scope |
| AAD app + SP | `azuread_*` provider | Not natively supported — use `setup-sp.sh` |
| NSG-NIC wiring | Separate `azurerm_network_interface_security_group_association` | Inline `networkSecurityGroup` in NIC |
| Subnets | Separate `azurerm_subnet` resources | Child resources of the VNet |
| SSH public key | `file("~/.ssh/id_rsa.pub")` | Required parameter at deploy time |
| PE network policies | `private_endpoint_network_policies = "Disabled"` | `privateEndpointNetworkPolicies: 'Disabled'` |
