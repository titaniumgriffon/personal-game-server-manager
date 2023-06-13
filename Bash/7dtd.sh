# Copyright Amazon.com, Inc. or its affiliates. All Rights Reserved.
# SPDX-License-Identifier: MIT-0

sudo apt update && sudo apt upgrade -y 
sudo apt install unzip apt-transport-https ca-certificates curl gnupg lsb-release -y
sudo apt -y install apt-transport-https ca-certificates curl gnupg-agent software-properties-common
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
sudo apt update

#install AWS CLI
sudo curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo unzip awscliv2.zip
sudo ./aws/install

#create random string for password
VHPW=$(echo $RANDOM | md5sum | head -c 20)

#get stackname created by user data script and update SSM parameter name with this to make it unique
STACKNAME=$(</tmp/mcParamName.txt)
PARAMNAME=mc7dtdPW-$STACKNAME

#put random string into parameter store as encrypted string value
aws ssm put-parameter --name $PARAMNAME --value $VHPW --type "SecureString" --overwrite


#install docker and 7dtd app on docker
sudo apt install docker-ce docker-ce-cli containerd.io -y
sudo apt install docker-compose -y
sudo usermod -aG docker $USER
sudo mkdir /usr/games/serverconfig
cd /usr/games/serverconfig
sudo bash -c 'echo "version: \"3\"
services:
  7dtd:
    image: vinanrra/7dtd-server:latest
    ports:
      - 26900:26900/tcp
      - 26900:26900/udp
      - 26901:26901/udp
      - 26902:26902/udp
      - 8080:8080/tcp
    environment:
      - START_MODE=3
      - TimeZone=America/Chicago
      - PUID=1000
      - PGID=1000
      - VERSION=latest_experimental
      - BACKUP=YES
    volumes:
      - ./7DaysToDie:/home/sdtdserver/.local/share/7DaysToDie/ 	
      - ./ServerFiles:/home/sdtdserver/serverfiles/ 	
      - ./Logs:/home/sdtdserver/log/
      - ./BackupFolder:/home/sdtdserver/lgsm/backup/
      - ./LGSM-Config:/home/sdtdserver/lgsm/config-lgsm/sdtdserver
      " >> docker-compose.yml'
echo "@reboot root (cd /usr/games/serverconfig/ && docker-compose up)" > /etc/cron.d/awsgameserver
sudo docker-compose up
