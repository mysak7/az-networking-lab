using 'main.bicep'

param prefix = 'mi'
param location = 'eastus2'
param adminUsername = 'azureuser'
param vmSize = 'Standard_D2als_v7'
// Set at deploy time: --parameters sshPublicKey="$(cat ~/.ssh/id_rsa.pub)"
param sshPublicKey = ''
