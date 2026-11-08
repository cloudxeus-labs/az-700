@description('Deployment location')
param location string

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
param webNsgName string


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
      {
        name: 'AllowHTTP'
        properties: {
          priority: 400
          direction: 'Inbound'
          access: 'Allow'
          protocol: '*'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource pips 'Microsoft.Network/publicIPAddresses@2025-03-01' = [
  for vm in vmNames: {
    name: 'pip-${vm}'
    location: location
    sku: {
      name: 'Standard'
    }
    properties: {
      publicIPAllocationMethod: 'Static'
    }
  }
]


// NIC in the chosen subnet
resource nics 'Microsoft.Network/networkInterfaces@2025-03-01' = [
  for (vm, i) in vmNames: {
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

            // Optional Public IP (lab scenarios)
            publicIPAddress: {
              id: pips[i].id
            } 
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
      hardwareProfile: {
        vmSize: vmSize
      }
      osProfile: {
        computerName: vm
        adminUsername: adminUsername
        adminPassword: adminPassword
      }
      storageProfile: {
        imageReference: {
          publisher: 'MicrosoftWindowsServer'
          offer: 'WindowsServer'
          sku: '2025-datacenter'
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
            id: nics[i].id
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


resource iisExt 'Microsoft.Compute/virtualMachines/extensions@2024-11-01' = [
  for (vm, i) in vmNames: {
    name: '${vm}/iis-setup'
    location: location
    properties: {
      publisher: 'Microsoft.Compute'
      type: 'CustomScriptExtension'
      typeHandlerVersion: '1.10'
      autoUpgradeMinorVersion: true
      settings: {
  commandToExecute: '''
powershell -ExecutionPolicy Bypass -Command "Install-WindowsFeature Web-Server -IncludeManagementTools; $p='C:\inetpub\wwwroot\index.html'; $html='<html><head><title>IIS Web Server</title></head><body style="font-family:Segoe UI"><h1>It works!</h1><p>Computer Name: ' + $env:COMPUTERNAME + '</p></body></html>'; $html | Out-File -FilePath $p -Encoding utf8 -Force; iisreset"
'''
}
    }
    dependsOn: [
      vms[i]
    ]
  }
]

