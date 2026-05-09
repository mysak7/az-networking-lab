targetScope = 'subscription'

@description('Prefix for all resource names — must be lowercase alphanumeric for storage account compatibility')
param prefix string = 'mi'

@description('Azure region — East US 2 has some of the cheapest spot pricing')
param location string = 'eastus2'

@description('Admin username for the virtual machine')
param adminUsername string = 'azureuser'

@description('VM size — D2als_v7 is cheap on-demand (2 vCPU, 4GB AMD) confirmed available in eastus2')
param vmSize string = 'Standard_D2als_v7'

@description('SSH public key for VM authentication — pass via: sshPublicKey="$(cat ~/.ssh/id_rsa.pub)"')
param sshPublicKey string

resource rg 'Microsoft.Resources/resourceGroups@2022-09-01' = {
  name: '${prefix}-learn-net-rg'
  location: location
}

module resources 'resources.bicep' = {
  name: 'resources-deployment'
  scope: rg
  params: {
    prefix: prefix
    location: location
    adminUsername: adminUsername
    vmSize: vmSize
    sshPublicKey: sshPublicKey
  }
}

output resourceGroupName string = rg.name
output publicIpAddress string = resources.outputs.publicIpAddress
output vmName string = resources.outputs.vmName
output sshCommand string = resources.outputs.sshCommand
