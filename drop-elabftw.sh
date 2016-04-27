#!/bin/bash
# http://www.elabftw.net

# exit on error
set -e

# exit if variable isn't set
set -u

# root only
if [ $EUID != 0 ];then
    echo "Why u no root?"
    exit 1
fi

logfile='elabftw.log'

# mysql passwords
rootpass=$(tr -dc A-Za-z0-9 < /dev/urandom | head -c 12 | xargs)
pass=$(tr -dc A-Za-z0-9 < /dev/urandom | head -c 12 | xargs)
ip=$(dig +short myip.opendns.com @resolver1.opendns.com)

# display ascii logo
clear
echo ""
echo "  ___ | |  ____ | |__   / _|| |_ __      __"
echo " / _ \| | / _ ||| |_ \ | |_ | __|\ \ /\ / /"
echo "|  __/| || (_| || |_) ||  _|| |_  \ V  V / "
echo " \___||_| \__,_||_.__/ |_|   \__|  \_/\_/  "
echo ""

# get info for letsencrypt and nginx
echo "[:)] Welcome to the install of elabftw!"
echo ""
echo "[?] What is the domain name of this server?"
echo "[*] Example : elabftw.ktu.edu"
echo "[*] Example : $ip"
read -p "[?] Your domain name: " domain
echo "[*] You can follow the status of the install with"
echo "[*] Ctrl-b, release and press '%'"
echo "[$] tail -f $logfile"
echo ""

echo "[*] Updating packages list"
apt-get update >> $logfile 2>&1

echo "[*] Installing python-pip"
DEBIAN_FRONTEND=noninteractive apt-get -y install \
    python-pip >> $logfile 2>&1

echo "[*] Installing docker-compose"
pip install -U docker-compose >> $logfile 2>&1

echo "[*] Creating folder structure"
mkdir -pvm 777 /elabftw/{web,mysql} >> $logfile 2>&1

echo "[*] Grabbing the docker-compose configuration file"
wget -q https://raw.githubusercontent.com/elabftw/docker-elabftw/master/src/docker-compose.yml-EXAMPLE -O docker-compose.yml

echo "[*] Adjusting configuration"
# elab config
secret_key=$(curl -s https://demo.elabftw.net/install/generateSecretKey.php)
sed -i -e "s/SECRET_KEY=/SECRET_KEY=$secret_key/" docker-compose.yml
sed -i -e "s/SERVER_NAME=localhost/SERVER_NAME=$domain/" docker-compose.yml
sed -i -e "s:/dok/uploads:/elabftw/web:" docker-compose.yml

# mysql config
sed -i -e "s/MYSQL_ROOT_PASSWORD=secr3t/MYSQL_ROOT_PASSWORD=$rootpass/" docker-compose.yml
sed -i -e "s/MYSQL_PASSWORD=secr3t/MYSQL_PASSWORD=$pass/" docker-compose.yml
sed -i -e "s/DB_PASSWORD=secr3t/DB_PASSWORD=$pass/" docker-compose.yml
sed -i -e "s:/dok/mysql:/elabftw/mysql:" docker-compose.yml

echo "[*] Launching docker"
docker-compose up -d

echo "[*] Run elabftw after reboot"
sed -i -e "s:exit 0:cd /root && /usr/local/bin/docker-compose -d:" /etc/rc.local

echo "Congratulations, eLabFTW is now running! :)\n
echo "It might take a minute to run at first.\n"
====> Go to https://$ip/install now ! <====\n
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%"
