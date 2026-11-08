using './main.bicep'

param vnetName = 'vnet-dev-eus-01'
param vnetAddressPrefix = '10.0.0.0/16'

param subnets = [
  {
    name: 'snet-dev-web'
    prefix: '10.0.0.0/24'
  }
  {
    name: 'snet-dev-db'
    prefix: '10.0.1.0/24'
  }
]

param adminUsername = 'az700admin'
param adminPassword = '<your-vm-password>'

param vms = [
  {
    name: 'vm-dev-web-01'
    subnetName: 'snet-dev-web'
    nsgName: 'nsg-vm-dev-web-01'
    vmSize: 'Standard_D2ds_v4'
    cloudInit: '''
#cloud-config
package_update: true
packages:
  - nginx

runcmd:
  - systemctl enable --now nginx
  - echo "<h1>This is the web server</h1>" > /var/www/html/index.html
'''
  }
  {
    name: 'vm-dev-db-01'
    subnetName: 'snet-dev-db'
    nsgName: 'nsg-vm-dev-db-01'
    vmSize: 'Standard_D2ds_v4'
    cloudInit: '''
#cloud-config
package_update: true
packages:
  - mysql-server
  - mysql-client

runcmd:
  - systemctl enable --now mysql

  # Overwrite server config safely
  - |
    cat <<EOF > /etc/mysql/mysql.conf.d/mysqld.cnf
    [mysqld]
    bind-address = 0.0.0.0
    EOF

  - systemctl restart mysql

  - |
    mysql <<'EOF'
    CREATE USER IF NOT EXISTS 'dbadmin'@'%' IDENTIFIED BY '<your-db-password>';
    GRANT ALL PRIVILEGES ON *.* TO 'dbadmin'@'%' WITH GRANT OPTION;
    FLUSH PRIVILEGES;

    CREATE DATABASE IF NOT EXISTS coursesdb;
    USE coursesdb;

    CREATE TABLE IF NOT EXISTS courses (
      id INT PRIMARY KEY AUTO_INCREMENT,
      name VARCHAR(200) NOT NULL,
      rating DECIMAL(3,1) NOT NULL
    );

    INSERT INTO courses (name, rating) VALUES
    ('Docker and Kubernetes', 4.5),
    ('AI-102 Azure AI Engineer', 4.6),
    ('AZ-104 Azure Administrator', 4.7);
    EOF
  '''
  }
]
