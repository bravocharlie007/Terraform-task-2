#!/bin/bash
sudo su
yum update -y
yum install httpd -y
systemctl start httpd
systemctl enable httpd
echo 'Welcome to Instance' >> /var/www/html/index.html
# SECURITY FIX: Disabled password authentication - use key-based auth only
# sed -i 's/^PasswordAuthentication no/PasswordAuthentication yes/' /etc/ssh/sshd_config
# systemctl restart sshd
