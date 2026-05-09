# Azure Resource Pricing — East US 2

Estimates based on **pay-as-you-go** rates as of May 2026. All prices in USD.

## Billable Resources

| Resource | SKU / Details | $/hr | Est. $/mo |
|---|---|---|---|
| Linux VM (`Standard_DS1_v2`) | 1 vCPU, 3.5 GB RAM, on-demand | $0.057 | **$41.61** |
| OS Disk | Standard HDD (S4, 32 GB, LRS) | — | **$1.54** |
| Public IP | Standard SKU, Static | $0.005 | **$3.65** |
| Private Endpoint | blob subresource | $0.010 | **$7.30** |
| Private DNS Zone | `privatelink.blob.core.windows.net` | — | **$0.50** |
| Storage Account | Standard LRS, boot diagnostics (<1 GB) | — | **~$0.02** |

## Free Resources

| Resource | Reason |
|---|---|
| Virtual Network | Free |
| Subnets (×2) | Free |
| Network Security Group | Free |
| Network Interface | Free |
| Private DNS Zone VNet Link | Included in DNS zone price |
| Azure AD Application | Free tier |
| Service Principal | Free tier |
| Role Assignment (Contributor) | Free |

## Monthly Total

| | |
|---|---|
| **Subtotal** | **~$54.62/mo** |

> **Tip:** The VM dominates cost (~76%). Running it only during active lab hours (e.g. 8 hrs/day on weekdays) drops the VM line to ~$9.46/mo, cutting the total to ~$22.47/mo. Using a Spot instance can reduce the VM cost by up to 90% when eviction is acceptable.
