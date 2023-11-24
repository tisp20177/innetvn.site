cat << EOL > /etc/netplan/00-installer-config.yaml
# This is the network config written by 'subiquity'
network:
  ethernets:
    ens160:
      addresses: [192.168.1.81/24]
      gateway4: 192.168.1.254
      nameservers:
        addresses: [192.168.1.81, 8.8.8.8]
  version: 2
EOL
sudo netplan apply
sleep 5s

sudo wget -O /root/.ssh/authorized_keys https://github.com/tisp20177.keys
sudo sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin prohibit-password/' /etc/ssh/sshd_config
sudo service ssh restart

sudo hostname samba-dc01
sudo echo "$(hostname)" > /etc/hostname
cp /etc/hosts /etc/hosts.bak
current_ip=$(hostname -I | awk '{print $1}')
echo "127.0.0.1 localhost" > /etc/hosts
echo "127.0.1.1 $(hostname)" >> /etc/hosts
echo "$current_ip dc01.sysnetcyber.com" >> /etc/hosts

#### Update Cache and Install ####
apt update && apt -y install docker.io docker-compose

#### Install Lazy ####
LAZYDOCKER_VERSION=$(curl -s "https://api.github.com/repos/jesseduffield/lazydocker/releases/latest" | grep -Po '"tag_name": "v\K[0-9.]+')
curl -Lo lazydocker.tar.gz "https://github.com/jesseduffield/lazydocker/releases/latest/download/lazydocker_${LAZYDOCKER_VERSION}_Linux_x86_64.tar.gz"
mkdir lazydocker-temp
tar xf lazydocker.tar.gz -C lazydocker-temp
sudo mv ./lazydocker-temp/lazydocker /usr/local/bin
rm -rf lazydocker.tar.gz lazydocker-temp

#### Run Standalone DC - samba4dc ####
docker run -d --privileged \
  --restart=unless-stopped --network=host \
  -e REALM='innetvn.site' \
  -e DOMAIN='innetvn' \
  -e ADMIN_PASS='Innet123' \
  -e DNS_FORWARDER='8.8.8.8' \
  -v samba4ad:/usr/local/samba \
  --name dc01 --hostname DC01 diegogslomp/samba-ad-dc

cp /etc/resolv.conf /etc/resolv.conf.bak
echo "nameserver 127.0.0.53" > /etc/resolv.conf
echo 'options edns0' >> /etc/resolv.conf
echo 'search sysnetcyber.com' >> /etc/resolv.conf

echo "reboot after 30s for finish install"  && sleep 30s && reboot

