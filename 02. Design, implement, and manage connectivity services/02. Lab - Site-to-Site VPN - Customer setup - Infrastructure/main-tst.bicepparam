using './main.bicep'

param vnetName = 'vnet-tst-eus-01'
param vnetAddressPrefix = '10.1.0.0/16'

param subnets = [
  {
    name: 'snet-tst-eus-app'
    prefix: '10.1.0.0/24'
  }
]

param vmName = 'vm-tst-app-01'
param vmSubnetName = 'snet-tst-eus-app'

param adminUsername = 'az700admin'
param adminPassword = '<your-vm-password>'

param usePublicIp = false
