#!/bin/bash

# Define colors
NO_COLOR="\033[0m"
YELLOW="\033[1;33m"
ORANGE="\033[0;33m"
LIGHT_RED="\033[1;31m"
LIGHT_PURPLE="\033[1;35m"

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
    sed -i "s/127.0.0.1 localhost/127.0.0.1 localhost $NEW_HOSTNAME/" /etc/hosts
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

    if type "htop" >/dev/null 2>&1; then
      echo -e "${LIGHT_PURPLE}Htop is already installed.${NO_COLOR}"
    else
      echo -e "${ORANGE}Installing Htop...${NO_COLOR}"
      apt -y install htop
      echo -e "${ORANGE}Done.${NO_COLOR}"
    fi

    if type "netstat" >/dev/null 2>&1; then
      echo -e "${LIGHT_PURPLE}Net-tools is already installed.${NO_COLOR}"
    else
      echo -e "${ORANGE}Installing Net-tools...${NO_COLOR}"
      apt -y install net-tools
      echo -e "${ORANGE}Done.${NO_COLOR}"
    fi

    if type "sudo" >/dev/null 2>&1; then
      echo -e "${LIGHT_PURPLE}Sudo is already installed.${NO_COLOR}"
    else
      echo -e "${ORANGE}Installing Sudo...${NO_COLOR}"
      apt -y install sudo
      echo -e "${ORANGE}Done.${NO_COLOR}"
    fi

    if type "openssl" >/dev/null 2>&1; then
      echo -e "${LIGHT_PURPLE}OpenSSL is already installed.${NO_COLOR}"
    else
      echo -e "${ORANGE}Installing OpenSSL...${NO_COLOR}"
      apt -y install openssl
      echo -e "${ORANGE}Done.${NO_COLOR}"
    fi

    apt -y install gnupg

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

    if type "sudo" >/dev/null 2>&1; then
      echo -e "${ORANGE}Sudo is installed. Let's add a new system user.${NO_COLOR}"

      echo -en "${LIGHT_RED}New username: ${NO_COLOR}"
      read -rp "" USERNAME

      adduser "$USERNAME"
      usermod -aG sudo "$USERNAME"

      echo -e "${ORANGE}User '$USERNAME' added successfully.${NO_COLOR}"
      echo ""
      return 0
    else
      echo -e "${LIGHT_PURPLE}Sorry, you need to install sudo before adding a new user.${NO_COLOR}"
      echo ""
      return 0
    fi    
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
    systemctl restart ssh

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

    wget https://raw.githubusercontent.com/alexrose/ServerConfig/master/templates/jail.local
    mv jail.local "/etc/fail2ban/jail.local"

    sed -i "s/= 22/= $PORT/" /etc/fail2ban/jail.local
    systemctl restart fail2ban
    echo -e "${ORANGE}Fail2ban configured successfully.${NO_COLOR}"
    echo ""
    return 0
  done
}

function addSwapPartition() {
  swapon --show | grep "/swapfile" &>/dev/null
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
    echo "/swapfile none swap sw 0 0" | tee -a /etc/fstab
    sysctl vm.swappiness=10
    echo "vm.swappiness=10" | tee -a /etc/sysctl.conf
    sysctl vm.vfs_cache_pressure=50
    echo "vm.vfs_cache_pressure = 50" | tee -a /etc/sysctl.conf

    echo -e "${ORANGE}Swap partition configured successfully.${NO_COLOR}"
    echo ""
    return 0
  fi
}

function installRedis() {
  if type "redis-cli" >/dev/null 2>&1; then
    echo -e "${LIGHT_PURPLE}Redis is already installed.${NO_COLOR}"
  else
    sudo apt -y install redis-server
    sudo cp /etc/redis/redis.conf /etc/redis/redis.backup
    sed -i -e '$asupervised systemd' /etc/redis/redis.conf
    sed -i -e '$amaxmemory 2048mb' /etc/redis/redis.conf
    sed -i -e '$amaxmemory-policy allkeys-lru' /etc/redis/redis.conf

    systemctl restart redis
  fi
}

function installLemp() {
  if type "nginx" >/dev/null 2>&1; then
    echo -e "${LIGHT_PURPLE}Nginx is already installed.${NO_COLOR}"
  else
    echo -e "${ORANGE}Installing Nginx...${NO_COLOR}"
    apt -y install nginx
    echo -e "${ORANGE}Done.${NO_COLOR}"

    echo -e "${ORANGE}Generating a self signed certificate...${NO_COLOR}"
    sudo openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout /etc/ssl/private/nginx-selfsigned.key -out /etc/ssl/certs/nginx-selfsigned.crt
    sudo openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048
    sudo echo "ssl_certificate /etc/ssl/certs/nginx-selfsigned.crt;" | tee -a "/etc/nginx/snippets/self-signed.conf"
    sudo echo "ssl_certificate_key /etc/ssl/private/nginx-selfsigned.key;" | tee -a "/etc/nginx/snippets/self-signed.conf"
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

  # if type "certbot" >/dev/null 2>&1; then
  #   echo -e "${LIGHT_PURPLE}Certbot is already installed.${NO_COLOR}"
  # else
  #   echo -e "${ORANGE}Installing Certbot...${NO_COLOR}"
  #   apt -y install certbot python-certbot-nginx
  #   echo -e "${ORANGE}Done.${NO_COLOR}"
  # fi

  echo -e "${ORANGE}Adding PHP repository...${NO_COLOR}"
  sudo apt -y install lsb-release apt-transport-https ca-certificates
  wget -O /etc/apt/trusted.gpg.d/php.gpg https://packages.sury.org/php/apt.gpg
  echo "deb https://packages.sury.org/php/ $(lsb_release -sc) main" | sudo tee /etc/apt/sources.list.d/php.list
  sudo apt update -y

  echo -e "${ORANGE}Done.${NO_COLOR}"

  if type "php" >/dev/null 2>&1; then
    echo -e "${LIGHT_PURPLE}PHP is already installed.${NO_COLOR}"
  else
    echo -e "${ORANGE}Installing PHP...${NO_COLOR}"
    apt -y install php8.3-{fpm,cli,curl,common,gd,igbinary,imagick,mbstring,mysql,opcache,readline,redis,tidy,xml,xsl,zip}
    apt -y install php8.4-{fpm,cli,curl,common,gd,igbinary,imagick,mbstring,mysql,opcache,readline,redis,tidy,xml,xsl,zip}

    usermod -aG www-data "$USER"
    echo "Europe/Bucharest" | sudo tee /etc/timezone
    sudo dpkg-reconfigure --frontend noninteractive tzdata

    for PHP_VERSION in /etc/php/*/ ;
    do
      echo "# Custom PHP settings" | tee -a "${PHP_VERSION}/fpm/conf.d/live.ini"
      echo "post_max_size = 128M" | tee -a "${PHP_VERSION}/fpm/conf.d/live.ini"
      echo "upload_max_filesize = 128M" | tee -a "${PHP_VERSION}/fpm/conf.d/live.ini"
      echo "max_file_uploads = 20M" | tee -a "${PHP_VERSION}/fpm/conf.d/live.ini"
      echo "zend.exception_ignore_args = On" | tee -a "${PHP_VERSION}/fpm/conf.d/live.ini"
      systemctl restart php"${PHP_VERSION}"-fpm
      systemctl disable apache2 && systemctl stop apache2
    done

    echo "server_tokens off;" | tee -a "/etc/nginx/conf.d/nginx.conf"
    echo "client_max_body_size 128M;" | tee -a "/etc/nginx/conf.d/nginx.conf"
    echo "ssl_session_tickets off;" | tee -a "/etc/nginx/conf.d/nginx.conf" #https://github.com/mozilla/server-side-tls/issues/135

    wget https://raw.githubusercontent.com/alexrose/ServerConfig/master/templates/vhost-default
    mv vhost-default "/etc/nginx/sites-available/default"
    systemctl restart nginx

    echo -e "${ORANGE}Done.${NO_COLOR}"
  fi
}

function installClean() {

  while true; do
    echo -en "${LIGHT_RED}Application folder(relative to /var/www/): ${NO_COLOR}"
    read -rp "" APP_FOLDER

    APP_PATH="/var/www/${APP_FOLDER}"
    # shellcheck disable=SC2006
    AVAILABLE_PHP_VERSION=`ls /etc/php`

    echo -en "${LIGHT_RED}Choose PHP version:\n ${AVAILABLE_PHP_VERSION}: ${NO_COLOR}"
    read -rp "" PHP_VERSION

    if [ -d "$APP_PATH" ]; then
      echo -e "${LIGHT_PURPLE}Application folder ${APP_FOLDER} already exists. Choose another name.${NO_COLOR}"
      echo ""
      return 0
    else
      echo -en "${LIGHT_RED}Application name(alphanumeric): ${NO_COLOR}"
      read -rp "" APP_NAME

      echo -en "${LIGHT_RED}Application URL(separated by space if multiple): ${NO_COLOR}"
      read -rp "" APP_ADDRESS

      # shellcheck disable=SC2006
      SQL_PASS=`tr -cd '[:alnum:]' < /dev/urandom | fold -w12 | head -n1`
      SQL_NAME="${APP_NAME}_dbn"
      SQL_USER="${APP_NAME}_dbu"
      SQL_QUERY="CREATE DATABASE ${SQL_NAME};GRANT ALL ON ${SQL_NAME}.* TO '${SQL_USER}'@'localhost' IDENTIFIED BY '${SQL_PASS}' WITH GRANT OPTION;FLUSH PRIVILEGES;"
      mkdir "${APP_PATH}"
      chown -R www-data:www-data "${APP_PATH}"
      echo "${SQL_QUERY}" | mariadb

      wget https://raw.githubusercontent.com/alexrose/ServerConfig/master/templates/vhost-template
      mv vhost-template "${APP_NAME}"
      sed -i "s/{DEFAULT_SERVER_FOLDER}/${APP_FOLDER}/" "${APP_NAME}"
      sed -i "s/{DEFAULT_SERVER_NAME}/${APP_ADDRESS}/" "${APP_NAME}"
      sed -i "s/{DEFAULT_SERVER_LOGNAME}/${APP_NAME}/" "${APP_NAME}"
      sed -i "s/{PHP_VERSION}/${PHP_VERSION}/" "${APP_NAME}"
      mv "${APP_NAME}" "/etc/nginx/sites-available/${APP_NAME}"
      ln -s "/etc/nginx/sites-available/${APP_NAME}" "/etc/nginx/sites-enabled/${APP_NAME}"

      # generate self signed certificate instead of certbot
      # certbot --nginx --agree-tos -d "${APP_ADDRESS// /,}"
      sudo openssl req -x509 -nodes -days 3650 -newkey rsa:2048 -keyout /etc/nginx/ssl/${APP_NAME}.key -out /etc/nginx/ssl/${APP_NAME}.crt

      systemctl restart nginx

      echo -e "${ORANGE}Application configured successfully.${NO_COLOR}"
      echo -e "${ORANGE}Sql database: ${SQL_NAME}${NO_COLOR}"
      echo -e "${ORANGE}Sql username: ${SQL_USER}${NO_COLOR}"
      echo -e "${ORANGE}Sql password: ${SQL_PASS}${NO_COLOR}"
      echo ""
      return 0
    fi
  done
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
  echo "   14. Install useful(sudo, mc, git, htop, net-tools)"
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
  echo "   30. Install Redis"
  echo "   31. Install LEMP(Nginx,MariaDB,PHP-FPM)"
  echo "   32. Install empty environment"
  echo "   33. Install WordPress"
  echo "   34. Install Laravel"
  echo "   35. Install Lumen"

  while :; do
    echo -en "${LIGHT_RED}Select an option([m]enu e[x]it): ${NO_COLOR}"
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
    30) installRedis ;;
    31) installLemp ;;
    32) installClean ;;
    33) installWordPress ;;
    34) installLaravel ;;
    35) installLumen ;;

    esac
  done
}

initialCheck
mainMenu
