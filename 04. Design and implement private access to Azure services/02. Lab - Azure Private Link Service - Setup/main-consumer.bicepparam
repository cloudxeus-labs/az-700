using './main.bicep'

param vnetName = 'vnet-app-eus-01'
param location='east us'
param webNsgName ='nsg-app-eus-web'
param vnetAddressPrefix = '10.20.0.0/16'

param subnets = [
  {
    name: 'snet-app-eus'
    prefix: '10.20.0.0/24'
  }
]

param vmNames = [
  'vm-app-01'
]

param vmSubnetName = 'snet-app-eus'

param adminUsername = 'az700admin'
param adminPassword = '<your-vm-password>'

