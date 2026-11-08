using './main.bicep'

param vnetName = 'vnet-onprem-dev-eus-01'
param vnetAddressPrefix = '192.168.0.0/16'

param subnets = [
  {
    name: 'snet-onprem-servers'
    prefix: '192.168.0.0/24'
  }
]

param vmName = 'vm-prem-vpn-01'
param vmSubnetName = 'snet-onprem-servers'

param adminUsername = 'az700admin'
param adminPassword = '<your-vm-password>'

param usePublicIp = true
