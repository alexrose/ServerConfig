#!/bin/bash

if [ -z "$1" ]; then
    echo "Please specify project directory."
    exit 1
fi

BACKUP_DIR=/var/www/.backup/
APP_ROOT=/var/www/$1/

# Crete backup dir  if not present
[ ! -d "$BACKUP_DIR" ] && mkdir -p "$BACKUP_DIR"

# Determine backup type
if [ -f "$APP_ROOT/wp-config.php" ]; then
    PROJECT_TYPE="wordpress"
elif [ -f "$APP_ROOT/.env" ]; then
    PROJECT_TYPE="laravel"
else
    echo "Unknown project type."
    exit 1
fi

# Get database credentials
if [ "$PROJECT_TYPE" = "wordpress" ]; then
    DB_USER=$(grep DB_USER "$APP_ROOT/wp-config.php" | awk -F\' '{print $4}')
    DB_NAME=$(grep DB_NAME "$APP_ROOT/wp-config.php" | awk -F\' '{print $4}')
    DB_PASS=$(grep DB_PASSWORD "$APP_ROOT/wp-config.php" | awk -F\' '{print $4}')
elif [ "$PROJECT_TYPE" = "laravel" ]; then
    DB_USER=$(grep DB_USERNAME "$APP_ROOT/.env" | cut -d '=' -f2 | tr -d '"')
    DB_NAME=$(grep DB_DATABASE "$APP_ROOT/.env" | cut -d '=' -f2 | tr -d '"')
    DB_PASS=$(grep DB_PASSWORD "$APP_ROOT/.env" | cut -d '=' -f2 | tr -d '"')
fi

DB_DUMP="${BACKUP_DIR}${DB_NAME}_$(date +"%Y-%m-%d-%H-%M").sql"

# Backup database
if ! mysqldump -u "$DB_USER" -p"$DB_PASS" "$DB_NAME" > "$DB_DUMP"; then
    echo "Database backup failed!"
    exit 1
fi

# Backup files
ARCHIVE="${BACKUP_DIR}${1}_${PROJECT_TYPE}_backup_$(date +"%Y-%m-%d_%H-%M").tar.gz"
if tar -czf "$ARCHIVE" "$APP_ROOT" "$DB_DUMP"; then
    rm "$DB_DUMP"
else
    echo "File backup failed!"
    exit 1
fi

echo "Backup completed successfully for $PROJECT_TYPE!"
