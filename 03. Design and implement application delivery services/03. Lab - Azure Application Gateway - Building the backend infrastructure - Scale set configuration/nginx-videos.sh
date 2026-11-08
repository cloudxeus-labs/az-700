#!/bin/bash

# Update packages
sudo apt-get update -y

# Install NGINX
sudo apt-get install -y nginx

VM_NAME="$(hostname -s || echo unknown)"

sudo mkdir -p /var/www/html/videos

tee /var/www/html/videos/index.html >/dev/null <<EOF
<html>
  <head><title>Videos server</title></head>
  <body>
    <h1>This is the videos web server</h1>
    <p>This page is served from VM instance: <b>${VM_NAME}</b></p>
  </body>
</html>
EOF

# Ensure NGINX starts on boot
sudo systemctl enable nginx
sudo systemctl restart nginx