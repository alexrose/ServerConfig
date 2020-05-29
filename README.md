# Server-Docker

Just a small bash script, to manage a small web server(debian/ubuntu & docker).

### Usage
- `wget https://raw.githubusercontent.com/alexrose/ServerConfig/master/server-docker.sh`
- `chmod +x server-docker.sh`
- `sudo ./server-docker.sh`

### Available options
* __GENERAL__
  * Update system
  * Update hostname
  * Clear MOTD
  * Install useful(sudo, mc, git)
  * Show menu(alias: m)
  * Exit(alias: x)
* __SECURITY__
  * Add new user
  * Secure ssh
  * Install Fail2Ban
* __DEVELOPMENT__
  * Install Docker
  * Install Portainer
  * Install nginx-proxy and letsencrypt-nginx-proxy-companion"
  * New wordpress container
  * New adminer container

# Backup-Docker

Just a small bash script to backup a WordPress container(sql and files)

### Usage
- `wget https://raw.githubusercontent.com/alexrose/ServerConfig/master/backup-docker.sh`
- `chmod +x backup-docker.sh`
- `sudo ./backup-docker.sh --db docker_db_container_name --path /path/to/docker/volume/`
