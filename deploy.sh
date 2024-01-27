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

# edit default user/pass
printf "\n\nEnter initial email login: "
read loginemail
printf "\n"
printf "Enter initial web interface password (required to change at first login): "
read initialpass
userpass="${initialpass}${loginemail}"
passhash=$(echo -n "${userpass}"|shasum -a 256 | cut -d" " -f1)

echo "AUTHENTICATION_DEFAULT_USERNAME=${loginemail}" | sudo tee -a /opt/openwifi/docker-compose/owsec.env > /dev/null
echo "AUTHENTICATION_DEFAULT_PASSWORD=${passhash}" | sudo tee -a /opt/openwifi/docker-compose/owsec.env > /dev/null

# setup ENV variables for public deployment

printf "\n\nEnter FQDN for public accessibility (Blank for private self-signed only, domain must exist): "

read fqdn 

# if FQDN exists, set env variables for LetsEncrypt cert pull

if [ -n "$fqdn" ]; then
	printf "\n\nEnter email for LetsEncrypt certificate: "
	read leemail
	
cat <<EOF |  sudo tee -a /etc/environment > /dev/null
SDKHOSTNAME=$fqdn
DEFAULT_UCENTRALSEC_URL=https://$fqdn:16001
SYSTEM_URI_UI=https://$fqdn:16001
OWGW_FILEUPLOADER_HOST_NAME=$fqdn
OWGW_FILEUPLOADER_URI=https://$fqdn:16003
OWGW_SYSTEM_URI_PUBLIC=https://$fqdn:16002
OWGW_RTTY_SERVER=$fqdn
OWSEC_SYSTEM_URI_PUBLIC=https://$fqdn:16001
OWFMS_SYSTEM_URI_PUBLIC=https://$fqdn:16004
OWPROV_SYSTEM_URI_PUBLIC=https://$fqdn:16005
OWANALYTICS_SYSTEM_URI_PUBLIC=https://$fqdn:16009
OWSUB_SYSTEM_URI_PUBLIC=https://$fqdn:16006
OWRRM_SERVICECONFIG_PRIVATEENDPOINT=https://openwifi.wlan.local:16789
OWRRM_SERVICECONFIG_PUBLICENDPOINT=https://$fqdn:16789
TRAEFIK_TAG=latest
INTERNAL_OWGW_HOSTNAME=openwifi.wlan.local
INTERNAL_OWPROVUI_HOSTNAME=openwifi.wlan.local
OWRRM_TAG=main
INTERNAL_OWRRM_HOSTNAME=openwifi.wlan.local
TRAEFIK_CERTIFICATESRESOLVERS_OPENWIFI_ACME_EMAIL=${leemail}
EOF
fi	



# deploy controller
cd /opt/openwifi/docker-compose/
sudo ./deploy.sh
