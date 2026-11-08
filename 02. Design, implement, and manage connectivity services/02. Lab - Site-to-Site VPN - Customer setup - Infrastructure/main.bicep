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
@description('VM name')
param vmName string

@description('VM size')
param vmSize string = 'Standard_B2s'

@description('Admin username')
param adminUsername string

@secure()
@description('Admin password (for Windows) OR temp password for labs')
param adminPassword string

@description('Subnet name for the VM NIC (must match one of the subnets above)')
param vmSubnetName string

@description('Deploy a Public IP for the VM? (Typically false when teaching Bastion/NAT)')
param usePublicIp bool = false

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
        }
      }
    ]
  }
}

// NIC-level NSG (simple for learning)
resource nsg 'Microsoft.Network/networkSecurityGroups@2025-03-01' = {
  name: 'nsg-${vmName}-nic'
  location: location
  properties: {
    securityRules: [
      // Keep it minimal for now (you can add RDP/SSH rules later if you want)
      // Note: For “no public IP” labs, students won't need inbound rules.
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

// Optional Public IP
resource pip 'Microsoft.Network/publicIPAddresses@2025-03-01' = if (usePublicIp) {
  name: 'pip-${vmName}'
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'  
  }
}

// NIC in the chosen subnet
resource nic 'Microsoft.Network/networkInterfaces@2025-03-01' = {
  name: 'nic-${vmName}'
  location: location
  properties: {
    networkSecurityGroup: {
      id: nsg.id
    }
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            // Reference the subnet by name from the VNet we created
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnet.name, vmSubnetName)
          }
          publicIPAddress: usePublicIp ? {
            id: pip.id
          } : null
        }
      }
    ]
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2024-11-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword     
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer:     'WindowsServer'
        sku:       '2025-datacenter'
        version:   'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
          properties: {
            primary: true
          }
        }
      ]
    }
  }
}


