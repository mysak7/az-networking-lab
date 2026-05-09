# 1-bicep-private-endpoint

Same infrastructure as `1-private-endpoint` rewritten in Bicep. Deploys a VM in East US 2 with a full network stack, storage account behind a private endpoint, and private DNS resolution.

## What this builds

| Resource | Purpose |
|---|---|
| Resource Group | logical container for everything |
| Virtual Network | 10.0.0.0/16 |
| VM Subnet | 10.0.1.0/24 |
| PE Subnet | 10.0.2.0/24, network policies disabled |
| NSG | inbound SSH (22) allowed |
| Public IP | Static, Standard SKU |
| NIC | VM subnet + public IP + NSG attached inline |
| Storage Account | Standard LRS, public access denied, AzureServices bypass |
| Linux VM (Standard_D2als_v7) | Ubuntu 22.04, SSH key auth, boot diagnostics |
| Private DNS Zone | `privatelink.blob.core.windows.net` |
| Private DNS Zone VNet Link | links zone to VNet for internal FQDN resolution |
| Private Endpoint | blob subresource, private IP in PE subnet |

> **Azure AD resources** — The AAD app + service principal from the Terraform version are not supported in standard Bicep. Run `setup-sp.sh` after deployment to create them via CLI.

## Prerequisites

```bash
az login
az account set --subscription <your-subscription-id>
```

## Deploy

```bash
az deployment sub create \
  --location eastus2 \
  --template-file main.bicep \
  --parameters sshPublicKey="$(cat ~/.ssh/id_rsa.pub)"
```

## Get outputs

```bash
az deployment sub show \
  --name main \
  --query 'properties.outputs' \
  --output table
```

SSH into the VM:

```bash
ssh azureuser@<publicIpAddress>
```

Verify private endpoint DNS from the VM:

```bash
nslookup milearnnetdiag.blob.core.windows.net
# resolves to 10.0.2.x — not the public endpoint
```

## Create service principal (optional)

```bash
bash setup-sp.sh mi
```

## Teardown

```bash
az group delete --name mi-learn-net-rg --yes --no-wait
```

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
