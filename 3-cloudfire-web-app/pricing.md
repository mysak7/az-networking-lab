# Pricing Estimate — 3-cloudfire-web-app (East US 2)

> All prices in **USD/month** based on Azure public pricing (East US 2, May 2026).
> Assumes ~730 hours/month, minimal traffic.
> Cloudflare Free plan has no usage-based charges.

---

## Monthly Cost Breakdown

| Service | SKU / Config | Unit Price | Est. Monthly |
|---|---|---|---|
| **Azure App Service Plan (Basic B1)** | 1 core, 1.75 GB RAM, Linux | $0.018 / hr | $13.14 |
| **Cloudflare** | Free plan | — | $0.00 |

### Total Estimate

| | |
|---|---|
| **Monthly** | **~$13.14 / month** |
| **Primary driver** | App Service Plan B1 (100% of total) |

---

## Cost by Category

```
App Service B1   ████████████████████████████████  ~$13.14  (100%)
Cloudflare Free  (free)                              $0.00
```

---

## Why B1 and not Free F1?

| Feature | F1 (Free) | B1 (Basic ~$13/mo) |
|---|---|---|
| Custom domain binding | ✗ | ✓ |
| Always On (no sleep) | ✗ | ✓ |
| Dedicated infrastructure | ✗ (shared) | ✓ |
| SLA | None | 99.95% |

Custom domain binding is **required** so App Service accepts requests with
`Host: cloudfire.mysak.fun` from Cloudflare. Without it, App Service rejects
the request before it reaches the app. F1 cannot be used in this architecture.

---

## Cloudflare Free vs Paid

| Feature | Free | Pro ($20/mo) | Business ($200/mo) |
|---|---|---|---|
| CDN | ✓ | ✓ | ✓ |
| DDoS (L3/L4/L7) | ✓ unmetered | ✓ | ✓ |
| SSL for custom domain | ✓ | ✓ | ✓ |
| WAF (managed rules) | ✗ | ✓ | ✓ |
| Rate limiting | ✗ | ✓ | ✓ |
| Advanced analytics | ✗ | ✓ | ✓ |
| Bot management | Basic | Standard | Advanced |
| Host header rewrite | ✗ | ✓ (Transform Rules) | ✓ |

For a landing page lab, **Free** is sufficient.

---

## Scaling Considerations

### App Service Plan
The single App Service is the only Azure compute resource.

| SKU | vCores | RAM | Monthly | Notes |
|-----|--------|-----|---------|-------|
| B1  | 1      | 1.75 GB | ~$13  | This lab — minimum for custom domains |
| B2  | 2      | 3.5 GB  | ~$26  | More headroom, same tier |
| S1  | 1      | 1.75 GB | ~$73  | Standard — adds VNet integration, autoscale |

### App Service Plan (Reserved)
| Commitment | Savings | Monthly |
|------------|---------|---------|
| Pay-as-you-go | — | ~$13 |
| 1-year reserved | ~55% | ~$6 |
| 3-year reserved | ~72% | ~$4 |

---

## What Is NOT Included

- **Data egress** — outbound data from Azure to Cloudflare: first 100 GB/month free (Cloudflare peering), then $0.087/GB
- **Cloudflare egress** — Cloudflare Free has unmetered bandwidth to end users
- **Azure DNS queries** — $0.40/million queries (negligible for a lab)
- **Log Analytics** — if enabled for App Service diagnostics (~$2–5/mo typical)
