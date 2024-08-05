#!/usr/bin/env bash
export META_TOKEN=$(curl -s -X PUT "http://169.254.169.254/latest/api/token" -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
export PUB_DNS=$(curl -s http://169.254.169.254/latest/meta-data/public-hostname -H "X-aws-ec2-metadata-token: $META_TOKEN")
amazon-linux-extras install nginx1 -y
yum install nginx -y
systemctl enable nginx
systemctl restart nginx.service
sleep 10
sed -i.bak "s/Welcome to nginx/Wellcome to $PUB_DNS!/" /usr/share/nginx/html/index.html