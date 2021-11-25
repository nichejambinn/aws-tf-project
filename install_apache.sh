#!/bin/bash
yum install httpd -y
cd /var/www/html
echo "<html><body><h1>Hello from $(hostname -f)</h1></body></html>" > index.html
systemctl restart httpd
systemctl enable httpd