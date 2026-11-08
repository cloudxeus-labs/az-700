using './main.bicep'

param vnetName = 'vnet-dev-eus-01'
param location='east us'
param webNsgName ='nsg-dev-eus-web'
param vnetAddressPrefix = '10.0.0.0/16'

param subnets = [
  {
    name: 'snet-dev-eus-web'
    prefix: '10.0.0.0/24'
  }
]

param vmNames = [
  'vm-dev-web-01'
  'vm-dev-web-02'
]

param vmSubnetName = 'snet-dev-eus-web'

param adminUsername = 'az700admin'
param adminPassword = '<your-vm-password>'

