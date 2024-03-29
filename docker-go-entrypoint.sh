#!/bin/sh
set -e

chown -R www-data:www-data /var/lib/groupoffice

#if [ ! -f "/etc/groupoffice/config.php" ]; then
  cp /usr/local/share/groupoffice-config.php.tpl /etc/groupoffice/config.php

  sed -i 's/{dbHost}/'${MYSQL_HOST}'/' /etc/groupoffice/config.php
  sed -i 's/{dbName}/'${MYSQL_DATABASE}'/' /etc/groupoffice/config.php
  sed -i 's/{dbUser}/'${MYSQL_USER}'/' /etc/groupoffice/config.php
  sed -i 's/{dbPass}/'${MYSQL_PASSWORD}'/' /etc/groupoffice/config.php
#fi

#call original entry point
docker-php-entrypoint "$@"
