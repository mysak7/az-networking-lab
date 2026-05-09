output "cluster_name" {
  value = azurerm_kubernetes_cluster.aks.name
}

output "resource_group" {
  value = azurerm_resource_group.rg.name
}

output "get_credentials" {
  value = "az aks get-credentials --resource-group ${azurerm_resource_group.rg.name} --name ${azurerm_kubernetes_cluster.aks.name} --overwrite-existing"
}

output "kubectl_commands" {
  value = <<-EOT

    # 1. Připoj kubectl
    az aks get-credentials --resource-group ${azurerm_resource_group.rg.name} --name ${azurerm_kubernetes_cluster.aks.name} --overwrite-existing

    # 2. Nasaď Karpenter NodePool + nginx
    kubectl apply -f manifests/

    # 3. Základní příkazy
    kubectl get nodes -o wide              # zobraz nody (Karpenter přidá po deployi)
    kubectl get pods -A                    # všechny pody
    kubectl get events -w                  # sleduj events live
    kubectl describe node <node-name>      # detaily nodu

    # 4. Škálování — Karpenter přidá/odebere nody automaticky
    kubectl scale deployment nginx --replicas=10
    kubectl scale deployment nginx --replicas=1

    # 5. Karpenter NodePool
    kubectl get nodepools
    kubectl get aksnodeclasses
    kubectl get nodeclaims
  EOT
}
