using './main.bicep'

param vnetName = 'vnet-dev-eus-01'
param vnetAddressPrefix = '10.0.0.0/16'

param subnets = [
  {
    name: 'snet-dev-eus-app'
    prefix: '10.0.0.0/24'
  }
]

param vmNames = [
  'vm-dev-app-01'
]

param vmSubnetName = 'snet-dev-eus-app'

param adminUsername = 'az700admin'
param adminPassword = '<your-vm-password>'

