# Pricing Estimate — 2-webapp (East US 2)

> All prices in **USD/month** based on Azure public pricing (East US 2, May 2026).
> Assumes ~730 hours/month, 1 App Gateway instance, minimal traffic/storage.
> Actual costs vary with traffic volume, data transfer, and WAF rule evaluations.

---

## Monthly Cost Breakdown

| Service | SKU / Config | Unit Price | Est. Monthly |
|---|---|---|---|
| **Application Gateway WAF v2** | 1 instance (fixed) | $0.246 / hr | $179.58 |
| Application Gateway WAF v2 | 1 Capacity Unit (min) | $0.008 / CU-hr | $5.84 |
| **App Service Plan (Standard S1)** | 1 core, 1.75 GB RAM, Linux | $0.10 / hr | $73.00 |
| **Public IP (Standard Static)** | 1 address, static | $0.005 / hr | $3.65 |
| **Private Endpoint — Storage** | 1 endpoint NIC | $0.01 / hr | $7.30 |
| **Private Endpoint — Key Vault** | 1 endpoint NIC | $0.01 / hr | $7.30 |
| **Storage Account (Standard LRS)** | 10 GB blob | $0.0184 / GB | $0.18 |
| Storage Account — operations | ~10K write + 100K read | tiered | ~$0.10 |
| **Key Vault (Standard)** | ~10K operations/mo | $0.04 / 10K ops | $0.04 |
| **Private DNS Zones (×2)** | 2 zones, minimal queries | $0.50 / zone | $1.00 |
| **VNet** | — | Free | $0.00 |

### Total Estimate

| | |
|---|---|
| **Base (no traffic)** | **~$278 / month** |
| **Primary driver** | App Gateway WAF v2 fixed + CU (~$185, 67% of total) |

---

## Cost by Category

```
App Gateway WAF v2    ████████████████████████████████  ~$185  (66%)
App Service Plan S1   ██████████████                    ~$73   (26%)
Private Endpoints     ███                               ~$15    (5%)
Everything else                                         ~$5     (2%)
```

---

## Scaling Considerations

### App Service Plan
The S1 plan hosts **both** frontend and backend App Services — no additional per-app charge.
Scaling out adds another S1 instance at $73/month each.

| SKU | vCores | RAM | Monthly | Notes |
|-----|--------|-----|---------|-------|
| S1  | 1      | 1.75 GB | ~$73  | Minimum for Regional VNet Integration |
| S2  | 2      | 3.5 GB  | ~$146 | 2× cost, 2× compute |
| S3  | 4      | 7 GB    | ~$292 | High-traffic production workloads |
| P1v3 | 2    | 8 GB    | ~$124 | Better perf/$ for production; supports autoscale |

### Application Gateway WAF v2
WAF v2 autoscales by capacity unit. Each CU handles ~2,500 persistent connections or 2.22 Mbps throughput.

| Load | CUs | Additional Monthly |
|------|-----|-------------------|
| Dev / idle | 1 | $0 (min included) |
| ~5K req/min | ~2–3 | +$6–12 |
| ~50K req/min | ~8–10 | +$42–58 |

### Storage Account
Blob storage cost scales with data stored and operations. Private endpoint cost ($7.30) is fixed regardless of usage — dominant at low data volumes.

| Data Stored | Storage Cost | PE Cost | Total Storage |
|-------------|-------------|---------|---------------|
| 10 GB | $0.18 | $7.30 | ~$7.50 |
| 100 GB | $1.84 | $7.30 | ~$9.14 |
| 1 TB | $18.43 | $7.30 | ~$25.73 |

---

## Cost Reduction Options

| Option | Saving | Trade-off |
|---|---|---|
| Replace WAF v2 with Azure Front Door + WAF policy | Varies (~$35+/mo base) | Global, but different feature set; may cost more at scale |
| Use Azure Container Apps instead of App Service | ~$0 when idle | Cold starts; no persistent state without external storage |
| Switch App Service Plan to **B2** | ~$35/mo savings | B-tier has no SLA and no VNet integration — not viable for this architecture |
| Switch to **P0v3** (dev SKU, VNet Integration supported) | ~$38/mo savings | Preview SKU; limited availability; 0.5 vCore |
| Enable **autoscale** on App Gateway (min 0 CU) | Saves CU cost when idle | Minimum 0 CU means scale-in to 0 is possible; cold latency |
| Use **Reserved Instances** (1-year) on App Service | ~40% savings (~$29/mo) | Commit to 1-year term |

---

## What Is NOT Included

- **Data egress** — outbound data from Azure to internet charged at $0.087/GB (first 10 GB free)
- **App Gateway data processed** — $0.008/GB inbound/outbound
- **Log Analytics / Azure Monitor** — if enabled for WAF diagnostics and App Service logs (~$2–10/mo typical)
- **Azure DNS** (public zone) — $0.50/zone + $0.40/million queries if a custom domain is added
- **Certificates** — App Service managed certificates are free; custom certs via Key Vault add cost
- **Bandwidth between App Services and private endpoints** — intra-region VNet traffic is free
