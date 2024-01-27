#!/bin/bash

# Add Docker's official GPG key:
sudo apt-get update
sudo apt-get install ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

# Add the repository to Apt sources:
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
sudo apt-get update

# Install docker-ce and docker-compose
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin docker-compose

# clone openwifi controller to /opt/openwifi
sudo git clone https://github.com/Telecominfraproject/wlan-cloud-ucentral-deploy.git /opt/openwifi
sudo docker-compose --project-directory /top/openwifi/docker-compose pull

# edit default user/pass
printf "\n\nEnter initial email login:\n"
read loginemail
printf "\n"
printf "Enter initial password:\n"
read initialpass
userpass="${initialpass}${loginemail}"
passhash=$(echo -n "${userpass}"|shasum -a 256 | cut -d" " -f1)


echo "AUTHENTICATION_DEFAULT_USERNAME=${loginemail}" | sudo tee -a /opt/openwifi/docker-compose/owsec.env > /dev/null
echo "AUTHENTICATION_DEFAULT_PASSWORD=${passhash}" | sudo tee -a /opt/openwifi/docker-compose/owsec.env > /dev/null


# deploy controller
sudo docker-compose --project-directory /opt/openwifi/docker-compose up -d
