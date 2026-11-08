@description('Deployment location')
param location string = resourceGroup().location

@description('Hub VNet name')
param hubVnetName string

@description('Hub VNet address space (e.g. 10.0.0.0/16)')
param hubVnetAddressPrefix string

@description('Hub subnets array: [{ name: ..., prefix: ... }]')
param hubSubnets array

@description('Spoke VNet name')
param spokeVnetName string

@description('Spoke VNet address space (e.g. 10.1.0.0/16)')
param spokeVnetAddressPrefix string

@description('Spoke subnets array: [{ name: ..., prefix: ... }]')
param spokeSubnets array

@description('Admin username')
param adminUsername string

@secure()
@description('Admin password (for labs)')
param adminPassword string

@description('Spoke VM definitions (one object per VM)')
param spokeVms array
/*
Example shape:
[
  {
    name: 'vm-spoke-web-01'
    subnetName: 'snet-spoke-web'
    vmSize: 'Standard_B2s'
    nsgName: 'nsg-vm-spoke-web-01'
    cloudInit: '...cloud-config...'
  }
]
*/

@description('Default VM size if not specified per VM')
param defaultVmSize string = 'Standard_B2s'

// --------------------
// 1) Hub VNet + subnets
// --------------------
resource hubVnet 'Microsoft.Network/virtualNetworks@2025-01-01' = {
  name: hubVnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        hubVnetAddressPrefix
      ]
    }
    subnets: [
      for s in hubSubnets: {
        name: s.name
        properties: {
          addressPrefix: s.prefix
        }
      }
    ]
  }
}

// --------------------
// 2) Spoke VNet + subnets
// --------------------
resource spokeVnet 'Microsoft.Network/virtualNetworks@2025-01-01' = {
  name: spokeVnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        spokeVnetAddressPrefix
      ]
    }
    subnets: [
      for s in spokeSubnets: {
        name: s.name
        properties: {
          addressPrefix: s.prefix
        }
      }
    ]
  }
}

// --------------------
// 3) VNet Peering (Hub <-> Spoke)
// Keep minimal, but enable forwarded traffic for future Firewall UDR lab.
// --------------------
resource peerHubToSpoke 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2025-01-01' = {
  name: '${hubVnet.name}/peer-hub-to-spoke'
  properties: {
    remoteVirtualNetwork: {
      id: spokeVnet.id
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
  }
}

resource peerSpokeToHub 'Microsoft.Network/virtualNetworks/virtualNetworkPeerings@2025-01-01' = {
  name: '${spokeVnet.name}/peer-spoke-to-hub'
  properties: {
    remoteVirtualNetwork: {
      id: hubVnet.id
    }
    allowVirtualNetworkAccess: true
    allowForwardedTraffic: true
  }
}

// --------------------
// 4) NSG per Spoke VM (attached to NIC)
// --------------------
resource spokeNsgs 'Microsoft.Network/networkSecurityGroups@2025-03-01' = [
  for (vm, i) in spokeVms: {
    name: contains(vm, 'nsgName') ? vm.nsgName : 'nsg-${vm.name}'
    location: location
    properties: {
      securityRules: [
        // allow VNet traffic (peering included)
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
        // allow SSH for admin (lock down later if needed)
        {
          name: 'AllowSSH'
          properties: {
            priority: 110
            direction: 'Inbound'
            access: 'Allow'
            protocol: 'Tcp'
            sourcePortRange: '*'
            destinationPortRange: '22'
            sourceAddressPrefix: '*'
            destinationAddressPrefix: '*'
          }
        }
        // allow HTTP (for NGINX test)
        {
          name: 'AllowHTTP'
          properties: {
            priority: 120
            direction: 'Inbound'
            access: 'Allow'
            protocol: 'Tcp'
            sourcePortRange: '*'
            destinationPortRange: '80'
            sourceAddressPrefix: '*'
            destinationAddressPrefix: '*'
          }
        }
      ]
    }
  }
]

// --------------------
// 5) NIC per Spoke VM (in spoke subnet) + attach NSG
// --------------------
resource spokeNics 'Microsoft.Network/networkInterfaces@2025-03-01' = [
  for (vm, i) in spokeVms: {
    name: 'nic-${vm.name}'
    location: location
    properties: {
      networkSecurityGroup: {
        id: spokeNsgs[i].id
      }
      ipConfigurations: [
        {
          name: 'ipconfig1'
          properties: {
            privateIPAllocationMethod: 'Dynamic'
            subnet: {
              id: resourceId('Microsoft.Network/virtualNetworks/subnets', spokeVnet.name, vm.subnetName)
            }
          }
        }
      ]
    }
  }
]

// --------------------
// 6) VM(s) in Spoke (cloud-init)
// --------------------
resource spokeVmsRes 'Microsoft.Compute/virtualMachines@2024-11-01' = [
  for (vm, i) in spokeVms: {
    name: vm.name
    location: location
    properties: {
      hardwareProfile: {
        vmSize: contains(vm, 'vmSize') ? vm.vmSize : defaultVmSize
      }
      osProfile: {
        computerName: vm.name
        adminUsername: adminUsername
        adminPassword: adminPassword
        customData: base64(vm.cloudInit)
        linuxConfiguration: {
          disablePasswordAuthentication: false
        }
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
          managedDisk: {
            storageAccountType: 'StandardSSD_LRS'
          }
        }
      }
      networkProfile: {
        networkInterfaces: [
          {
            id: spokeNics[i].id
            properties: {
              primary: true
            }
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
