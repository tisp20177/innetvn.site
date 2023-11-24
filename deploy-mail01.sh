cat << EOL > /etc/netplan/00-installer-config.yaml
# This is the network config written by 'subiquity'
network:
  ethernets:
    ens33:
      addresses: [192.168.1.82/24]
      gateway4: 192.168.1.254
      nameservers:
        addresses: [192.168.1.81, 8.8.8.8]
  version: 2
EOL
sudo netplan apply
sleep 10s


sudo wget -O /root/.ssh/authorized_keys https://github.com/tisp20177.keys
sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
sudo service ssh restart


sudo hostname mail01
sudo echo "$(hostname)" > /etc/hostname


cp /etc/hosts /etc/hosts.bak
current_ip=$(hostname -I | awk '{print $1}')
echo "127.0.0.1 localhost" > /etc/hosts
echo "127.0.1.1 $(hostname)" >> /etc/hosts
echo "$current_ip dc01.sysnetcyber.com" >> /etc/hosts


#### Update Cache and Install Docker####
apt update && apt -y install docker.io docker-compose-v2


#### Install Lazy ####
LAZYDOCKER_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazydocker/releases/latest" | grep -Po '"tag_name": "v\K[0-9.]+')
curl -Lo lazydocker.tar.gz "https://github.com/jesseduffield/lazydocker/releases/latest/download/lazydocker_${LAZYDOCKER_VERSION}_Linux_x86_64.tar.gz"
mkdir lazydocker-temp
tar xf lazydocker.tar.gz -C lazydocker-temp
sudo mv ./lazydocker-temp/lazydocker /usr/local/bin
rm -rf lazydocker.tar.gz lazydocker-temp
#### Deploy Mail Server
git clone https://github.com/mailcow/mailcow-dockerized
mv mailcow-dockerized service && cd service
./generate_config.sh

sudo sed -i 's/HTTP_PORT=80/HTTP_PORT=8080/' /root/service/mailcow.conf
sudo sed -i 's/HTTP_BIND=/HTTP_BIND=192.168.1.82/' /root/service/mailcow.conf
sudo sed -i 's/HTTPS_PORT=443/HTTPS_PORT=8443/' /root/service/mailcow.conf
sudo sed -i 's/HTTPS_BIND=/HTTPS_BIND=192.168.1.82/' /root/service/mailcow.conf
sudo sed -i 's/DOCKER_COMPOSE_VERSION=native/DOCKER_COMPOSE_VERSION=2/' /root/service/mailcow.conf
sudo sed -i 's/SKIP_LETS_ENCRYPT=n/SKIP_LETS_ENCRYPT=y/' /root/service/mailcow.conf

#HTTP_PORT=80
#HTTP_BIND=192.168.1.82
#HTTPS_PORT=443
#HTTPS_BIND=192.168.1.82
#DOCKER_COMPOSE_VERSION=2
#SKIP_LETS_ENCRYPT=y
##### SKIP_CLAMD=n , USE_WATCHDOG=y

docker compose pull
#docker compose up -d

