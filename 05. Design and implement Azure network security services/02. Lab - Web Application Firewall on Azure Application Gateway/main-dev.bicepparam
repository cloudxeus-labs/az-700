using './main.bicep'

param vnetName = 'vnet-dev-eus-01'
param vnetAddressPrefix = '10.0.0.0/16'

param subnets = [
  {
    name: 'snet-images-web'
    prefix: '10.0.0.0/24'
  }
  {
    name: 'snet-videos-web'
    prefix: '10.0.1.0/24'
  }
]

param adminUsername = 'az700admin'
param adminPassword = '<your-vm-password>'

param vms = [
  {
    name: 'vm-images-01'
    subnetName: 'snet-images-web'
    nsgName: 'nsg-vm-images-01'
    vmSize: 'Standard_D2ds_v4'
    cloudInit: '''
#cloud-config
package_update: true
packages:
  - nginx

runcmd:
  - systemctl enable --now nginx
  - mkdir -p /var/www/html/images
  - echo "<h1>Images site - vm-images-01</h1>" > /var/www/html/images/index.html
'''
  }
  {
    name: 'vm-videos-01'
    subnetName: 'snet-videos-web'
    nsgName: 'nsg-vm-videos-01'
    vmSize: 'Standard_D2ds_v4'
    cloudInit: '''
#cloud-config
package_update: true
packages:
  - nginx

runcmd:
  - systemctl enable --now nginx
  - mkdir -p /var/www/html/videos
  - echo "<h1>Videos site - vm-videos-01</h1>" > /var/www/html/videos/index.html
'''
  }
]
