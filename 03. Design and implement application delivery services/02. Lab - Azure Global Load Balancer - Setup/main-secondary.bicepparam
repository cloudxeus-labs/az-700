using './main.bicep'

param vnetName = 'vnet-dev-neu-01'
param location='north europe'
param webNsgName ='nsg-dev-neu-web'
param vnetAddressPrefix = '10.1.0.0/16'

param subnets = [
  {
    name: 'snet-dev-neu-web'
    prefix: '10.1.0.0/24'
  }
]

param vmNames = [
  'vm-dev-web-03'
  'vm-dev-web-04'
]

param vmSubnetName = 'snet-dev-neu-web'

param adminUsername = 'az700admin'
param adminPassword = '<your-vm-password>'

