@description('Deployment location')
param location string = resourceGroup().location

// --------------------
// 1) Virtual Network
// --------------------
@description('Virtual network name')
param vnetName string

@description('VNet address space, e.g. 10.10.0.0/16')
param vnetAddressPrefix string

@description('Array of subnets to create')
param subnets array = [
  // Example:
  // { name: 'snet-web', prefix: '10.10.1.0/24' }
]

// --------------------
// 2) Virtual Machine
// --------------------
@description('VM names to deploy')
param vmNames array

@description('VM size')
param vmSize string = 'Standard_B2s'

@description('Admin username')
param adminUsername string

@secure()
@description('Admin password (for Windows) OR temp password for labs')
param adminPassword string

@description('Subnet name for the VM NIC (must match one of the subnets above)')
param vmSubnetName string

@description('NSG name for the web subnet (shared across backend VMs)')
param webNsgName string = 'nsg-dev-eus-web'


// --------------------
// Networking resources
// --------------------
resource vnet 'Microsoft.Network/virtualNetworks@2025-01-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
    subnets: [
      for s in subnets: {
        name: s.name
        properties: {
          addressPrefix: s.prefix
          networkSecurityGroup: (s.name == vmSubnetName) ? {
            id: nsg.id} : null
        }
      }
    ]
  }
}

// NIC-level NSG (simple for learning)
resource nsg 'Microsoft.Network/networkSecurityGroups@2025-03-01' = {
  name: webNsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowVnetInBound'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '*'
          sourceAddressPrefix: 'VirtualNetwork'
          destinationAddressPrefix: 'VirtualNetwork'
        }
      }
    ]
  }
}



// NIC in the chosen subnet
resource nics 'Microsoft.Network/networkInterfaces@2025-03-01' = [
  for vm in vmNames: {
    name: 'nic-${vm}'
    location: location
    properties: {
      ipConfigurations: [
        {
          name: 'ipconfig1'
          properties: {
            privateIPAllocationMethod: 'Dynamic'
            subnet: {
              id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnet.name, vmSubnetName)
            }
            // keep public IP out for now (backend pool usually private)
          }
        }
      ]
    }
  }
]

resource vms 'Microsoft.Compute/virtualMachines@2024-11-01' = [
  for (vm, i) in vmNames: {
    name: vm
    location: location
    properties: {
      hardwareProfile: { vmSize: vmSize }
      osProfile: {
        computerName: vm
        adminUsername: adminUsername
        adminPassword: adminPassword
        linuxConfiguration: { disablePasswordAuthentication: false }
      }
      storageProfile: {
        imageReference: {
          publisher: 'Canonical'
          offer: 'ubuntu-24_04-lts'
          sku: 'server'
          version: 'latest'
        }
        osDisk: {
          createOption: 'FromImage'
          managedDisk: { storageAccountType: 'StandardSSD_LRS' }
        }
      }
      networkProfile: {
        networkInterfaces: [
          {
            id: nics[i].id
            properties: { primary: true }
          }
        ]
      }
       diagnosticsProfile: {
        bootDiagnostics: {
          enabled: true
        }
      }
    }
  }
]
