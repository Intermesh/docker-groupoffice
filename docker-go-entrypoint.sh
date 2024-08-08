#!/bin/sh
set -e

chown -R www-data:www-data /var/lib/groupoffice

#if [ ! -f "/etc/groupoffice/config.php" ]; then
  cp /usr/local/share/groupoffice-docker-config.php.tpl /etc/groupoffice/docker-config.php

  sed -i 's/{dbHost}/'${MYSQL_HOST}'/' /etc/groupoffice/docker-config.php
  sed -i 's/{dbName}/'${MYSQL_DATABASE}'/' /etc/groupoffice/docker-config.php
  sed -i 's/{dbUser}/'${MYSQL_USER}'/' /etc/groupoffice/docker-config.php
  sed -i 's/{dbPass}/'${MYSQL_PASSWORD}'/' /etc/groupoffice/docker-config.php
#fi

#call original entry point
docker-php-entrypoint "$@"
