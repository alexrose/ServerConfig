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
  if ! type "sudo2" >/dev/null 2>&1; then
    retrun 0
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
      echo -e "${LIGHT_PURPLE}MidnightCommander is already installed.${NO_COLOR}"
    else
      echo -e "${ORANGE}Installing MidnightCommander...${NO_COLOR}"
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

    if type "sudo" >/dev/null 2>&1; then
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

    if ! type "sudo" >/dev/null 2>&1; then
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
    echo -e "${ORANGE}Fail2Ban configured successfully.${NO_COLOR}"
    echo ""
    return 0
  done
}

function installDocker() {
  while true; do
    if type "docker" >/dev/null 2>&1; then
      echo -e "${LIGHT_PURPLE}Docker is already installed.${NO_COLOR}"
      echo ""
      return 0
    fi

    echo -e "${ORANGE}Installing Docker...${NO_COLOR}"
    apt -y install \
      apt-transport-https \
      ca-certificates \
      curl \
      gnupg-agent \
      software-properties-common
    curl -fsSL https://download.docker.com/linux/debian/gpg | sudo apt-key add -
    sudo add-apt-repository \
      "deb [arch=amd64] https://download.docker.com/linux/debian \
      $(lsb_release -cs) \
      stable"
    apt update
    apt -y install docker-ce
    usermod -aG docker "${USER}"

    echo -e "${ORANGE}Docker installed successfully.${NO_COLOR}"
    echo ""
    return 0
  done
}

function installPortainer() {
  while true; do
    if [ "$(docker ps -q -f name='portainer')" ]; then
      if [ "$(docker ps -aq -f status=running -f name='portainer')" ]; then
        echo -e "${LIGHT_PURPLE}Portainer is already installed and running.${NO_COLOR}"
        echo -e "${ORANGE}Portainer URL: ${YELLOW}http://$HOSTNAME:9000${NO_COLOR}"
        echo ""
        return 0
      fi

      echo -e "${LIGHT_PURPLE}Portainer seems to be installed but it's not running.${NO_COLOR}"
      echo -e "${ORANGE}Portainer URL: ${YELLOW}http://$HOSTNAME:9000${NO_COLOR}"
      echo ""
      return 0
    fi

    echo -e "${ORANGE}Installing Portainer...${NO_COLOR}"
    docker volume create portainer_data
    docker run -d -p 8000:8000 -p 9000:9000 --name=portainer --restart=always \
      -v /var/run/docker.sock:/var/run/docker.sock \
      -v portainer_data:/data portainer/portainer

    echo -e "${ORANGE}Portainer installed successfully.${NO_COLOR}"
    echo -e "${ORANGE}Portainer URL: ${YELLOW}http://$HOSTNAME:9000${NO_COLOR}"
    echo ""
    return 0
  done
}

function installNginxAndLetsencrypt() {
  while true; do
    echo -e "${ORANGE}Create network if it doesn't exists...${NO_COLOR}"
    docker network create --driver bridge nginx_proxy || true

    if [ "$(docker ps -q -f name='nginx-proxy')" ]; then
      echo -e "${LIGHT_PURPLE}Nginx-proxy is already installed.${NO_COLOR}"
    else
      echo -e "${ORANGE}Installing Nginx-proxy...${NO_COLOR}"
      docker run --detach \
        --name nginx-proxy \
        --network nginx_proxy \
        --restart always \
        --publish 80:80 \
        --publish 443:443 \
        --volume /etc/nginx/certs \
        --volume /etc/nginx/vhost.d \
        --volume /usr/share/nginx/html \
        --volume /var/run/docker.sock:/tmp/docker.sock:ro \
        jwilder/nginx-proxy
      echo -e "${ORANGE}Nginx-proxy installed successfully.${NO_COLOR}"
    fi

    if [ "$(docker ps -q -f name='nginx-letsencrypt')" ]; then
      echo -e "${LIGHT_PURPLE}LetsEncrypt-nginx-proxy is already installed.${NO_COLOR}"
    else
      echo -e "${ORANGE}Installing LetsEncrypt-nginx-proxy...${NO_COLOR}"
      echo -en "${LIGHT_RED}Default email(mandatory): ${NO_COLOR}"
      read -rp "" DEFAULT_EMAIL

      docker run --detach \
        --name nginx-letsencrypt \
        --network nginx_proxy \
        --restart always \
        --volumes-from nginx-proxy \
        --volume /var/run/docker.sock:/var/run/docker.sock:ro \
        --env "DEFAULT_EMAIL=${DEFAULT_EMAIL}" \
        jrcs/letsencrypt-nginx-proxy-companion
      echo -e "${ORANGE}LetsEncrypt-nginx-proxy installed successfully.${NO_COLOR}"
    fi

    echo -e "${ORANGE}Operation completed successfully.${NO_COLOR}"
    echo ""
    return 0
  done
}

function installWordpressInstance() {
  while true; do
    if [ "$(docker ps -q -f name='nginx-proxy')" ]; then
      echo -en "${LIGHT_RED}Application name: ${NO_COLOR}"
      read -rp "" APP_NAME

      if [ "$(docker ps -q -f name="${APP_NAME}")" ]; then
        echo -e "${LIGHT_PURPLE}Application ${APP_NAME} already exists. Choose another name.${NO_COLOR}"
        echo ""
        return 0
      else
        echo -en "${LIGHT_RED}Application address: ${NO_COLOR}"
        read -rp "" APP_ADDRESS

        echo -en "${LIGHT_RED}Application email: ${NO_COLOR}"
        read -rp "" APP_EMAIL

        echo -en "${LIGHT_RED}Application password: ${NO_COLOR}"
        read -rp "" APP_PASS

        echo -e "${ORANGE}Installing database for ${APP_NAME}...${NO_COLOR}"
        docker run --detach \
          --name "${APP_NAME}_db" \
          --network nginx_proxy \
          --restart always \
          --env "MYSQL_USER=${APP_NAME}_dbu" \
          --env "MYSQL_DATABASE=${APP_NAME}_dbn" \
          --env "MYSQL_PASSWORD=${APP_PASS}" \
          --env "MYSQL_ROOT_PASSWORD=${APP_PASS}" \
          --volume "${APP_NAME}_db":/var/lib/mysql \
          mariadb
        echo -e "${ORANGE}Database installed successfully.${NO_COLOR}"
        echo ""

        echo -e "${ORANGE}Installing wordpress...${NO_COLOR}"
        docker run --detach \
          --name "${APP_NAME}" \
          --network nginx_proxy \
          --restart always \
          --env "WORDPRESS_DB_HOST=${APP_NAME}_db" \
          --env "WORDPRESS_DB_USER=${APP_NAME}_dbu" \
          --env "WORDPRESS_DB_NAME=${APP_NAME}_dbn" \
          --env "WORDPRESS_DB_PASSWORD=${APP_PASS}" \
          --env "VIRTUAL_HOST=${APP_ADDRESS}" \
          --env "LETSENCRYPT_HOST=${APP_ADDRESS}" \
          --env "LETSENCRYPT_EMAIL=${APP_EMAIL}" \
          --volume "${APP_NAME}":/var/www/html \
          wordpress
        echo -e "${ORANGE}Wordpress installed successfully.${NO_COLOR}"
        echo ""
        return 0
      fi
    else
      echo -e "${LIGHT_PURPLE}Nginx-proxy it's not installed.${NO_COLOR}"
      echo ""
      return 0
    fi

    echo -en "${LIGHT_RED}Application address: ${NO_COLOR}"
    read -rp "" APP_ADDRESS

    echo -en "${LIGHT_RED}Application email: ${NO_COLOR}"
    read -rp "" APP_EMAIL

    echo -en "${LIGHT_RED}Application password: ${NO_COLOR}"
    read -rp "" APP_PASS

    echo -e "${ORANGE}Operation completed successfully.${NO_COLOR}"
    echo ""
    return 0
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
  echo "   14. Install useful(sudo, mc, git)"
  echo "   15. Show menu(alias: m)"
  echo "   16. Exit(alias: x)"
  echo ""
  echo -e "${LIGHT_RED}## SECURITY${NO_COLOR}"
  echo "   21. Add new user"
  echo "   22. Secure ssh"
  echo "   23. Install Fail2Ban"
  echo ""
  echo -e "${LIGHT_RED}## DEVELOPMENT${NO_COLOR}"
  echo "   31. Install Docker"
  echo "   32. Install Portainer"
  echo "   33. Install nginx-proxy and letsencrypt-nginx-proxy-companion"
  echo "   34. Install WordPress
  "

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
    31) installDocker ;;
    32) installPortainer ;;
    33) installNginxAndLetsencrypt ;;
    34) installWordpressInstance ;;
    esac
  done
}

initialCheck
mainMenu
