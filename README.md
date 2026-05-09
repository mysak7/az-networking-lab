# az-networking-lab

Azure networking playground. Deploys a spot VM in East US 2 with a full network stack, a service principal, and a storage service endpoint — to poke around and learn.

## What this builds

| Resource | Purpose |
|---|---|
| Resource Group | logical container for everything |
| Virtual Network + Subnet | 10.0.0.0/16, subnet at 10.0.1.0/24 |
| NSG | inbound SSH (22) allowed |
| Public IP | static, Standard SKU — needed for Standard NSG |
| NIC + NSG association | wires NSG to NIC explicitly |
| Storage Account | boot diagnostics; locked to subnet via service endpoint |
| Spot VM (Standard_D2as_v4) | Ubuntu 22.04, SSH key auth, eviction → Deallocate |
| Azure AD App + Service Principal | with Contributor role on the resource group |
| Service Endpoint (Microsoft.Storage) | routes VNet→Storage traffic over Azure backbone |
| Private Endpoint (commented out) | blob private endpoint with private DNS zone |

## Prerequisites

```bash
az login
az account set --subscription <your-subscription-id>
```

The AzureAD provider also authenticates via `az login`. Make sure your account has permissions to create AAD applications (Application Administrator or higher).

> **Storage account name** — `local.storage_name` defaults to `milearnnetdiag`. Storage account names must be globally unique across all of Azure. If `terraform apply` fails on the storage account, change the `prefix` variable or edit `local.storage_name` in `main.tf`.

## Usage

```bash
terraform init
terraform plan
terraform apply
```

SSH into the VM once apply completes:

```bash
terraform output ssh_command
# copy-paste the output
```

Read the service principal credentials:

```bash
terraform output -raw service_principal_client_id
terraform output -raw service_principal_client_secret
```

## Spot VM notes

- `priority = "Spot"` + `eviction_policy = "Deallocate"` — on eviction the VM is stopped/deallocated, not deleted. Disk and IP are kept.
- `max_bid_price = -1` — you pay up to the on-demand price (safest for learning).
- East US 2 `Standard_D2as_v4` spot is typically ~$0.02–0.05/hr.

## Experimenting with private endpoints

The private endpoint block is commented out at the bottom of `main.tf`. Uncomment it to provision:
- `azurerm_private_dns_zone` — `privatelink.blob.core.windows.net`
- `azurerm_private_dns_zone_virtual_network_link` — links zone to VNet
- `azurerm_private_endpoint` — gives storage a private IP in your subnet

Then from the VM: `nslookup <storage-account>.blob.core.windows.net` — you'll see it resolve to the private IP instead of the public one.

## Teardown

```bash
terraform destroy
```
