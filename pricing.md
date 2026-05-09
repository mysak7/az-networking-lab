# Azure Networking Lab — Monthly Pricing Summary

> All prices in **USD/month**, East US 2, pay-as-you-go, ~730 hrs/month (May 2026).
> See each module's `pricing.md` for full breakdowns and scaling options.

---

## 1-private-endpoint

VM + storage account behind a private endpoint.

| Resource | SKU | $/mo |
|---|---|---|
| Linux VM | Standard_D2als_v7 (2 vCPU, 4 GB, on-demand) | $70.08 |
| OS Disk | Standard LRS (P6, 64 GB) | $2.40 |
| Public IP | Standard Static | $3.65 |
| Private Endpoint | blob subresource | $7.30 |
| Private DNS Zone | `privatelink.blob.core.windows.net` | $0.50 |
| Storage Account | Standard LRS, boot diagnostics (<1 GB) | ~$0.02 |
| **Total** | | **~$83.95/mo** |

> Tip: running the VM only during active lab hours (8 hrs/day weekdays) cuts the VM line to ~$15.98/mo → **~$29.85/mo** total.

---

## 2-webapp

App Gateway WAF v2 → two App Services → Storage + Key Vault via private endpoints.

| Resource | SKU | $/mo |
|---|---|---|
| Application Gateway WAF v2 | 1 instance + 1 CU (min) | $185.42 |
| App Service Plan | Standard S1, Linux (hosts frontend + backend) | $73.00 |
| Public IP | Standard Static | $3.65 |
| Private Endpoint — Storage | blob subresource | $7.30 |
| Private Endpoint — Key Vault | vault subresource | $7.30 |
| Storage Account | Standard LRS, ~10 GB | ~$0.28 |
| Key Vault | Standard, ~10K ops/mo | ~$0.04 |
| Private DNS Zones (×2) | blob + vault zones | $1.00 |
| **Total** | | **~$277.99/mo** |

> App Gateway WAF v2 dominates (~67%). Replacing it with Azure Front Door + WAF policy starts at ~$35/mo if traffic is low.

---

## 3-cloudfire-web-app

App Service (Basic B1) behind Cloudflare Free as a zero-cost WAF/CDN front door.

| Resource | SKU | $/mo |
|---|---|---|
| App Service Plan | Basic B1, Linux | $13.14 |
| Cloudflare | Free plan | $0.00 |
| Azure DNS Zone | `mysak.fun` (NS delegated to Cloudflare) | $0.50 |
| **Total** | | **~$13.64/mo** |

> Cheapest architecture by far. Cloudflare Free provides DDoS protection, CDN, and SSL at no cost.

---

## Side-by-Side Comparison

| Module | Architecture | $/mo | Primary Cost Driver |
|---|---|---|---|
| 1-private-endpoint | VM + private endpoint to storage | ~$84 | VM compute (~83%) |
| 2-webapp | App Gateway WAF v2 + App Service + private endpoints | ~$278 | App Gateway WAF v2 (~67%) |
| 3-cloudfire-web-app | App Service + Cloudflare Free | ~$14 | App Service B1 (~96%) |

---

## What Is NOT Included (all modules)

- **Data egress** — $0.087/GB after first 10 GB/month free
- **Log Analytics / Azure Monitor** — ~$2–10/mo if enabled
- **Azure DNS queries** — $0.40/million (negligible for lab workloads)
- **Intra-region VNet traffic** — free
