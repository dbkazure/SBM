#!/bin/bash
sudo apt-get update
sudo apt-get install -y nginx
sudo systemctl start nginx
sudo systemctl enable nginx
cat > /var/www/html/index.html << EOF
<HTML><H1>$(heading_one)</HTML></H1>
EOF
sudo systemctl restart nginx