using './main.bicep'

param hubVnetName = 'vnet-hub-eus-01'
param hubVnetAddressPrefix = '10.0.0.0/16'

param hubSubnets = [
  {
    // REQUIRED name for Azure Firewall
    name: 'AzureFirewallSubnet'
    prefix: '10.0.0.0/24'
  }
  {
    // optional shared subnet (jumpbox/dns later)
    name: 'snet-hub-shared'
    prefix: '10.0.1.0/24'
  }
]

param spokeVnetName = 'vnet-spoke-app-eus-01'
param spokeVnetAddressPrefix = '10.1.0.0/16'

param spokeSubnets = [
  {
    name: 'snet-spoke-web'
    prefix: '10.1.0.0/24'
  }
]

param adminUsername = 'az700admin'
param adminPassword = '<your-vm-password>'

param spokeVms = [
  {
    name: 'vm-spoke-web-01'
    subnetName: 'snet-spoke-web'
    nsgName: 'nsg-vm-spoke-web-01'
    vmSize: 'Standard_B2s'
    cloudInit: '''
#cloud-config
package_update: true
packages:
  - nginx

runcmd:
  - systemctl enable --now nginx
  - echo "<h1>Spoke Web VM - vm-spoke-web-01</h1>" > /var/www/html/index.html
'''
  }
]
