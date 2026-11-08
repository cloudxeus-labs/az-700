@description('Deployment location')
param location string = resourceGroup().location

// --------------------
// 1) Virtual Network
// --------------------
@description('Virtual network name')
param vnetName string

@description('VNet address space, e.g. 10.0.0.0/16')
param vnetAddressPrefix string

@description('Array of subnets to create')
param subnets array

// --------------------
// 2) Virtual Machines (one object per VM)
// --------------------
@description('VM definitions. Each item deploys one VM + NIC + NIC-level NSG.')
param vms array
/*
Example shape:
[
  {
    name: 'vm-dev-web-01'
    subnetName: 'snet-dev-web'
    vmSize: 'Standard_B2s' // optional, defaults if omitted
    nsgName: 'nsg-vm-dev-web-01' // optional, defaults if omitted
    cloudInit: '...cloud-config...'
  }
]
*/

@description('Default VM size if not specified per VM')
param defaultVmSize string = 'Standard_B2s'

@description('Admin username')
param adminUsername string

@secure()
@description('Admin password (for labs)')
param adminPassword string

// --------------------
// VNET + subnets (NO subnet NSG assignment anymore)
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

// --------------------
// NSG per VM (one per NIC)
// --------------------
resource nsgs 'Microsoft.Network/networkSecurityGroups@2025-03-01' = [
  for (vm, i) in vms: {
    name: contains(vm, 'nsgName') ? vm.nsgName : 'nsg-${vm.name}'
    location: location
    properties: {
      securityRules: [
        // KEEP THIS SIMPLE FOR TRAINING: allow VNet-to-VNet traffic
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

        // OPTIONAL: if this VM is your "web" VM, you might add SSH/HTTP here.
        // For exam/labs, you can also manage rules per role by extending the vm object.
      ]
    }
  }
]

// --------------------
// NIC per VM (NIC is placed in the VM's subnet) + attach the per-VM NSG
// --------------------
resource nics 'Microsoft.Network/networkInterfaces@2025-03-01' = [
  for (vm, i) in vms: {
    name: 'nic-${vm.name}'
    location: location
    properties: {
      networkSecurityGroup: {
        id: nsgs[i].id
      }
      ipConfigurations: [
        {
          name: 'ipconfig1'
          properties: {
            privateIPAllocationMethod: 'Dynamic'
            subnet: {
              id: resourceId('Microsoft.Network/virtualNetworks/subnets', vnet.name, vm.subnetName)
            }
          }
        }
      ]
    }
  }
]

// --------------------
// VM per VM definition (per-VM cloud-init)
// --------------------
resource virtualMachines 'Microsoft.Compute/virtualMachines@2024-11-01' = [
  for (vm, i) in vms: {
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

        // Each VM can pass its own cloud-init
        // Ensure you pass the raw YAML string in the parameter file
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

