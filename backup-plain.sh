#!/bin/bash

if [ -z "$1" ]
  then
    echo "Please specify WP directory."
	exit 1
fi

BACKUP_DIR=/var/www/.backup/
APP_ROOT=/var/www/$1/

DB_USER=$(grep DB_USER $APP_ROOT/wp-config.php | awk -F\' '{print$4}')
DB_NAME=$(grep DB_NAME $APP_ROOT/wp-config.php | awk -F\' '{print$4}')
DB_PASS=$(grep DB_PASSWORD $APP_ROOT/wp-config.php | awk -F\' '{print$4}')
DB_DUMP="$BACKUP_DIR""$DB_NAME"_$(date +"%Y-%m-%d-%H-%M").sql

mysqldump -u $DB_USER -p$DB_PASS $DB_NAME > $DB_DUMP

tar -czf "$BACKUP_DIR$1"_wpfiles_$(date +"%Y-%m-%d_%H-%M").tar.gz $APP_ROOT $DB_DUMP

rm $DB_DUMP
