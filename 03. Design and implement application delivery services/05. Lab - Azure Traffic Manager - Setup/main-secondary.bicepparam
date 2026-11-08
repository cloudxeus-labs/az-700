using './main.bicep'

param vnetName = 'vnet-dev-neu-01'
param vnetAddressPrefix = '10.1.0.0/16'
param location='north europe'
param webNsgName ='nsg-dev-neu-web'
param subnets = [
  {
    name: 'snet-dev-neu-web'
    prefix: '10.1.0.0/24'
  }
]

param vmNames = [
  'vm-secondary-01'
]

param vmSubnetName = 'snet-dev-neu-web'

param adminUsername = 'az700admin'
param adminPassword = '<your-vm-password>'
