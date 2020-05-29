#!/bin/bash

# Define colors
NO_COLOR='\033[0m'
YELLOW='\033[1;33m'
ORANGE='\033[0;33m'
LIGHT_RED='\033[1;31m'
LIGHT_PURPLE='\033[1;35m'

# initial checks
function isRoot() {
  if [ "$EUID" -ne 0 ]; then
    return 1
  fi
}

function checkOS() {
  if [[ -e /etc/debian_version ]]; then
    OS="debian"

    if [[ $ID == "ubuntu" ]]; then
      OS="ubuntu"
    fi
  else
    echo -e "${LIGHT_PURPLE}OS not supported. Please use  Debian or Ubuntu.${NO_COLOR}"
    quit
  fi
}

function isSudoInstalled() {
  if ! type "sudo" >/dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

function initialCheck() {
  if ! isRoot; then
    echo -e "${LIGHT_PURPLE}Sorry, you need to run this script as root.${NO_COLOR}"
    quit
  fi

  checkOS
}

## GENERAL SECTION
function updateSystem() {
  while true; do
    echo -e "${ORANGE}Updating system packages...${NO_COLOR}"
    apt-get update
    apt -y upgrade
    echo -e "${ORANGE}System update completed successfully.${NO_COLOR}"
    echo ""
    return 0
  done
}

function updateHostname() {
  while true; do
    echo -e "${ORANGE}Updating system hostname...${NO_COLOR}"

    echo -en "${LIGHT_RED}New hostname: ${NO_COLOR}"
    read -rp "" NEW_HOSTNAME

    echo "$NEW_HOSTNAME" >/etc/hostname
    sed -i "s/$HOSTNAME/$NEW_HOSTNAME/" /etc/hosts
    hostname "$NEW_HOSTNAME"
    echo -e "${ORANGE}Hostname updated successfully.${NO_COLOR}"
    echo ""
    return 0
  done
}

function clearMotd() {
  while true; do
    echo -e "${ORANGE}Updating system MOTD...${NO_COLOR}"
    echo >/etc/motd
    echo -e "${ORANGE}MOTD updated successfully.${NO_COLOR}"
    echo ""
    return 0
  done
}

function installUseful() {
  while true; do
    if type "mc" >/dev/null 2>&1; then
      echo -e "${LIGHT_PURPLE}Midnight Commander is already installed.${NO_COLOR}"
    else
      echo -e "${ORANGE}Installing Midnight Commander...${NO_COLOR}"
      apt -y install mc
      echo -e "${ORANGE}Done.${NO_COLOR}"
    fi

    if type "git" >/dev/null 2>&1; then
      echo -e "${LIGHT_PURPLE}Git is already installed.${NO_COLOR}"
    else
      echo -e "${ORANGE}Installing Git...${NO_COLOR}"
      apt -y install git
      echo -e "${ORANGE}Done.${NO_COLOR}"
    fi

    if isSudoInstalled; then
      echo -e "${LIGHT_PURPLE}Sudo is already installed.${NO_COLOR}"
    else
      echo -e "${ORANGE}Installing Sudo...${NO_COLOR}"
      apt -y install sudo
      echo -e "${ORANGE}Done.${NO_COLOR}"
    fi

    echo ""
    return 0
  done
}

function quit() {
  echo -e "${ORANGE}My work here is done! *flies away*${NO_COLOR}"
  exit 0
}

## SECURITY SECTION
function addNewUser() {
  while true; do
    echo -e "${ORANGE}Check if sudo is installed...${NO_COLOR}"

    if ! isSudoInstalled; then
      echo -e "${LIGHT_PURPLE}Sorry, you need to install sudo before adding a new user.${NO_COLOR}"
      echo ""
      return 0
    fi

    echo -e "${ORANGE}Sudo is installed. Let's add a new system user.${NO_COLOR}"

    echo -en "${LIGHT_RED}New username: ${NO_COLOR}"
    read -rp "" USERNAME

    adduser "$USERNAME"
    usermod -aG sudo "$USERNAME"

    echo -e "${ORANGE}User '$USERNAME' added successfully.${NO_COLOR}"
    echo ""
    return 0
  done
}

function secureSSH() {
  while true; do
    echo -e "${ORANGE}Securing ssh. Please ensure you have another user that can connect to ssh,${NO_COLOR}"
    echo -e "${ORANGE}as we will disable ssh login for root user.${NO_COLOR}"

    echo -en "${LIGHT_RED}New ssh port: ${NO_COLOR}"
    read -rp "" PORT

    echo -e "${ORANGE}Updating ssh port...${NO_COLOR}"
    sed -i "s/#Port 22/Port $PORT/" /etc/ssh/sshd_config
    echo -e "${ORANGE}Disable ssh access for root...${NO_COLOR}"
    sed -i "s/PermitRootLogin yes/PermitRootLogin no/" /etc/ssh/sshd_config
    service ssh restart

    echo -e "${ORANGE}SSH secured.${NO_COLOR}"
    echo ""
    return 0
  done
}

function installFail2Ban() {
  while true; do
    if type "fail2ban-client" >/dev/null 2>&1; then
      echo -e "${LIGHT_PURPLE}Fail2Ban is already installed.${NO_COLOR}"
      echo ""
      return 0
    fi

    echo -e "${ORANGE}Installing fail2ban and enable ssh watch...${NO_COLOR}"

    echo -en "${LIGHT_RED}SSH port: ${NO_COLOR}"
    read -rp "" PORT

    apt -y install fail2ban
    echo -e "${ORANGE}Fail2ban is now installed.${NO_COLOR}"

    cp /etc/fail2ban/jail.conf /etc/fail2ban/jail.local
    sed -i 's/bantime  = 10m/bantime  = 48h/' /etc/fail2ban/jail.local
    sed -i 's/#ignorself = true/ignorself = true/' /etc/fail2ban/jail.local
    sed -i "s/= ssh/= $PORT/" /etc/fail2ban/jail.local
    service fail2ban restart
    echo -e "${ORANGE}Fail2ban configured successfully.${NO_COLOR}"
    echo ""
    return 0
  done
}

function addSwapPartition() {
  swapon --show | grep '/swapfile' &>/dev/null
  if [ $? == 0 ]; then
    echo -e "${LIGHT_PURPLE}Swap partition already configured.${NO_COLOR}"
    echo ""
    return 0
  else
    echo -e "${ORANGE}Installing swap partition...${NO_COLOR}"
    echo -en "${LIGHT_RED}Swap size(e.g. 8G): ${NO_COLOR}"
    read -rp "" SWAPSIZE

    fallocate -l "${SWAPSIZE}" /swapfile
    chmod 600 /swapfile
    mkswap /swapfile
    swapon /swapfile
    cp /etc/fstab /etc/fstab.bak
    echo '/swapfile none swap sw 0 0' | tee -a /etc/fstab
    sysctl vm.swappiness=10
    echo 'vm.swappiness=10' | tee -a /etc/sysctl.conf
    sysctl vm.vfs_cache_pressure=50
    echo 'vm.vfs_cache_pressure = 50' | tee -a /etc/sysctl.conf

    echo -e "${ORANGE}Swap partition configured successfully.${NO_COLOR}"
    echo ""
    return 0
  fi

}

function installCertbot() {
  if type "certbot" >/dev/null 2>&1; then
    echo -e "${LIGHT_PURPLE}Certbot is already installed. Just run: 'sudo certbot --nginx'${NO_COLOR}"
    echo ""
    return 0
  fi

  echo -e "${ORANGE}Installing Certbot...${NO_COLOR}"
  apt -y install certbot python-certbot-nginx

  echo -e "${ORANGE}Certbot installed successfully. Use 'sudo certbot --nginx'${NO_COLOR}"
  echo ""
  return 0
}

function installLemp() {
  if type "nginx" >/dev/null 2>&1; then
    echo -e "${LIGHT_PURPLE}Nginx is already installed.${NO_COLOR}"
  else
    echo -e "${ORANGE}Installing Nginx...${NO_COLOR}"
    apt -y install nginx
    echo -e "${ORANGE}Done.${NO_COLOR}"
  fi

  if type "mariadb" >/dev/null 2>&1; then
    echo -e "${LIGHT_PURPLE}MariaDB is already installed.${NO_COLOR}"
  else
    echo -e "${ORANGE}Installing MariaDB...${NO_COLOR}"
    apt -y install mariadb-server
    mysql_secure_installation
    echo -e "${ORANGE}Done.${NO_COLOR}"
  fi

  if type "php" >/dev/null 2>&1; then
    echo -e "${LIGHT_PURPLE}PHP is already installed.${NO_COLOR}"
  else
    echo -e "${ORANGE}Installing PHP...${NO_COLOR}"
    apt -y install php-fpm php-mysql
    usermod -aG www-data "$USER"

    PHP_VERSION=ls /etc/php
    echo '# Custom PHP settings' | tee -a "/etc/php/${PHP_VERSION}/fpm/php.ini"
    echo 'post_max_size = 128M' | tee -a "/etc/php/${PHP_VERSION}/fpm/php.ini"
    echo 'upload_max_filesize = 128M' | tee -a "/etc/php/${PHP_VERSION}/fpm/php.ini"
    systemctl restart php"${PHP_VERSION}"-fpm

    echo 'client_max_body_size 128M;' | tee -a "/etc/nginx/conf.d/nginx.conf"

    echo 'ssl_session_cache shared:SSL:5m; # holds approx 4000 sessions' | tee -a "/etc/nginx/conf.d/nginx.conf"
    echo 'ssl_session_timeout 1h; # 1 hour during which sessions can be re-used.' | tee -a "/etc/nginx/conf.d/nginx.conf"
    echo 'ssl_session_tickets off; #https://github.com/mozilla/server-side-tls/issues/135' | tee -a "/etc/nginx/conf.d/nginx.conf"
    echo 'ssl_protocols TLSv1.1 TLSv1.2 TLSv1.3;' | tee -a "/etc/nginx/conf.d/nginx.conf"
    echo 'ssl_buffer_size 4k;' | tee -a "/etc/nginx/conf.d/nginx.conf"


#ssl_stapling on;
#ssl_stapling_verify on;
#ssl_trusted_certificate /path/to/your/CA/chain.pem;
#resolver 8.8.8.8 8.8.4.4 valid=300s;
#resolver_timeout 5s;
#
#ssl_protocols TLSv1.1 TLSv1.2 ;
#ssl_ciphers 'EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH';
#ssl_ecdh_curve secp384r1;
#ssl_session_cache shared:SSL:5m;
#ssl_session_timeout 24h;
#ssl_session_tickets off;
#ssl_buffer_size 4k;





    systemctl restart nginx

    echo -e "${ORANGE}Done.${NO_COLOR}"
  fi
}

function installClean() {
  //
}

function mainMenu() {
  clear >$(tty)
  echo -e "${ORANGE}"
  echo -e "################################################################"
  echo -e "# Howdy stranger!"
  echo -e "#"
  echo -e "# Git repo: ${YELLOW}https://github.com/alexrose/ServerConfig/ ${ORANGE}"
  echo -e "# Hostname: ${YELLOW}$HOSTNAME ${ORANGE}"
  echo -e "################################################################"
  echo -e "${NO_COLOR}"
  echo -e "${LIGHT_RED}## GENERAL${NO_COLOR}"
  echo "   11. Update system"
  echo "   12. Update hostname"
  echo "   13. Clear MOTD"
  echo "   14. Install useful(sudo, mc, git)"
  echo "   15. Show menu(alias: m)"
  echo "   16. Exit(alias: x)"
  echo ""
  echo -e "${LIGHT_RED}## SECURITY${NO_COLOR}"
  echo "   21. Add new user"
  echo "   22. Secure ssh"
  echo "   23. Install Fail2Ban"
  echo "   24. Add swap partition"
  echo ""
  echo -e "${LIGHT_RED}## DEVELOPMENT${NO_COLOR}"
  echo "   31. Install LEMP(Nginx,MariaDB,PHP-FPM)"
  echo "   32. Install Certbot"

  while :; do
    echo -en "${LIGHT_RED}Select an option: ${NO_COLOR}"
    read -rp "" MENU_OPTION

    case $MENU_OPTION in
    11) updateSystem ;;
    12) updateHostname ;;
    13) clearMotd ;;
    14) installUseful ;;
    15 | m) mainMenu ;;
    16 | x) quit ;;
    21) addNewUser ;;
    22) secureSSH ;;
    23) installFail2Ban ;;
    24) addSwapPartition ;;
    31) installLemp ;;
    32) installCertbot ;;
    33) installWordPress ;;
    34) installClean ;;
    esac
  done
}

initialCheck
mainMenu