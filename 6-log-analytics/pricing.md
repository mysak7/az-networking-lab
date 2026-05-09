# Pricing — 6-log-analytics

All prices in USD, Sweden Central region, approximate.

## Always-on resources

| Resource | SKU / tier | $/month |
|---|---|---|
| Log Analytics Workspace | PerGB2018, first 5 GB/day free | ~$0 – $5 |
| Linux VM | Standard_B1s (1 vCPU, 1 GB RAM) | ~$7.59 |
| OS disk | Standard_LRS, 30 GB | ~$1.20 |
| Public IP | Standard, Static | ~$3.65 |
| VNet, NSG, subnets | — | free |

**Estimated total: ~$12 – $17 / month**

Most of that is the VM. If you deallocate it when not in use (`az vm deallocate`), you only pay for the disk and IP (~$5/month).

## Log Analytics ingestion

The 5 GB/day free tier is generous for a single VM sending syslog + perf counters.  
Overage rate: **$2.30 / GB** after the free allowance.

## Cost-saving tips

```bash
# Stop the VM overnight (disk + IP still charged, compute stops)
az vm deallocate --resource-group mi-6-log-analytics-rg --name mi-6-vm

# Start it again
az vm start --resource-group mi-6-log-analytics-rg --name mi-6-vm
```

## Tear down

```bash
terraform destroy
```
