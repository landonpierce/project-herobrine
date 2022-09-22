#!/bin/bash

#Install docker
sudo apt-get update -y
sudo apt-get install \
	ca-certificates \
	curl \
	gnupg \
	lsb-release -y
sudo mkdir -p /etc/apt/keyrings

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo chmod a+r /etc/apt/keyrings/docker.gpg
sudo apt-get update -y
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-compose-plugin -y

#Install Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

#Install Azcopy

wget https://aka.ms/downloadazcopy-v10-linux
tar -xvf downloadazcopy-v10-linux
sudo cp ./azcopy_linux_amd64_10.16.0/azcopy /usr/bin/

#Authorize Azcopy

azcopy login --identity
azcopy copy https://{storageAccountName}.blob.core.windows.net/{pathToWorld/world.tar.gz} ./  ##if file isn't found, nothing happens


