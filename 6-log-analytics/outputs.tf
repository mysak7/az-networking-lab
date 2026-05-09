output "workspace_id" {
  description = "Log Analytics Workspace ID (for portal deep-link)"
  value       = azurerm_log_analytics_workspace.law.id
}

output "workspace_name" {
  description = "Log Analytics Workspace name"
  value       = azurerm_log_analytics_workspace.law.name
}

output "vm_public_ip" {
  description = "Public IP of the probe VM"
  value       = azurerm_public_ip.vm.ip_address
}

output "kql_nsg_rule_hits" {
  description = "KQL — NSG rule hit counts (last hour)"
  value       = <<-EOT
    AzureDiagnostics
    | where ResourceType == "NETWORKSECURITYGROUPS"
    | where Category == "NetworkSecurityGroupRuleCounter"
    | summarize Hits = sum(matchedConnections_d) by ruleName_s, direction_s
    | sort by Hits desc
  EOT
}

output "kql_vm_cpu" {
  description = "KQL — VM CPU utilization over time"
  value       = <<-EOT
    Perf
    | where ObjectName == "Processor Information" and CounterName == "% Processor Time"
    | summarize avg(CounterValue) by bin(TimeGenerated, 5m), Computer
    | render timechart
  EOT
}

output "kql_syslog_errors" {
  description = "KQL — recent syslog errors from the VM"
  value       = <<-EOT
    Syslog
    | where SeverityLevel in ("err", "crit", "alert", "emerg")
    | project TimeGenerated, Computer, Facility, SeverityLevel, SyslogMessage
    | sort by TimeGenerated desc
  EOT
}

output "kql_network_bytes" {
  description = "KQL — network throughput on the VM"
  value       = <<-EOT
    Perf
    | where ObjectName == "Network Interface" and CounterName == "Bytes Total/sec"
    | summarize avg(CounterValue) by bin(TimeGenerated, 5m), Computer, InstanceName
    | render timechart
  EOT
}
