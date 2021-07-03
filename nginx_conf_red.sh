#!/bin/bash

sudo yum update -y
# this command install nginx on the basic aws linux machine
sudo amazon-linux-extras install nginx1 -y
sudo systemctl start nginx
sudo yum install curl -y
sudo yum install unzip -y
sudo curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo /usr/bin/unzip awscliv2.zip
sudo ./aws/install
# copyiing the files from my bucket
sudo /usr/bin/aws s3 cp s3://glebbucket/red/ ./ --recursive
# replacing the html file with my file
sudo cp ./index.html /usr/share/nginx/html/
# replacing the nginx configuration file with my configuration
sudo cp ./nginx.conf /etc/nginx/
sudo systemctl reload nginx
