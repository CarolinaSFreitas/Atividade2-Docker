#!/bin/bash

sudo yum update -y
sudo yum install docker -y
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -aG docker ec2-user
sudo chkconfig docker on
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo mv /usr/local/bin/docker-compose /bin/docker-compose
sudo yum install nfs-utils -y
sudo mkdir /mnt/efs/
sudo chmod +rwx /mnt/efs/
