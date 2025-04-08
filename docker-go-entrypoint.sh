#!/bin/sh
set -e

cp /usr/local/share/groupoffice-docker-config.php.tpl /etc/groupoffice/docker-config.php

sed -i 's/{dbHost}/'${MYSQL_HOST}'/' /etc/groupoffice/docker-config.php
sed -i 's/{dbName}/'${MYSQL_DATABASE}'/' /etc/groupoffice/docker-config.php
sed -i 's/{dbUser}/'${MYSQL_USER}'/' /etc/groupoffice/docker-config.php
sed -i 's/{dbPass}/'${MYSQL_PASSWORD}'/' /etc/groupoffice/docker-config.php


#call original entry point
docker-php-entrypoint "$@"
