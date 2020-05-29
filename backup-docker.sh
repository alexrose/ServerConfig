#!/bin/bash

db=${db}
path=${path}

while [ $# -gt 0 ]; do

  if [[ $1 == *"--"* ]]; then
    param="${1/--/}"
    declare "$param"="$2"
  fi
  shift
done

function dbCheck() {
  if [[ $db == "" ]]; then
    echo "Docker database name is missing; use '--db docker_db_name'"
    exit 0
  fi
}
function pathCheck() {
  if [[ $path == "" ]]; then
    echo "Files path is missing; use '--path /path/to/html/'"
    exit 0
  fi
}

dbCheck
pathCheck

if [ "$(docker ps -a -q -f name="${db}")" ]; then
  backupFile=${db}_$(date "+%Y_%m_%d")
  docker exec "${db}" sh -c 'exec mysqldump --databases "$MYSQL_DATABASE" -u"$MYSQL_USER" -p"$MYSQL_ROOT_PASSWORD"' >"${backupFile}.sql"
  gzip "${backupFile}.sql"
  echo "Database dumped successfully."
else
  echo "Docker database not found."
  exit 0
fi
echo "${path}"
tar -czf "${backupFile}.tar.gz" "${path}"

echo "Files compressed successfully."
exit 0