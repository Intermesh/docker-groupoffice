#!/bin/sh
set -e

if [ ! -d /etc/groupoffice/multi_instance ]; then
    mkdir -p /etc/groupoffice/multi_instance && chown -R www-data:www-data /etc/groupoffice
fi

if [ ! -d /var/lib/groupoffice/multi_instance ]; then
    mkdir -p /var/lib/groupoffice/multi_instance && chown -R www-data:www-data /var/lib/groupoffice
fi

if [ ! -f /etc/groupoffice/config.php ]; then
    cp /usr/local/share/groupoffice-config.php /etc/groupoffice/config.php
fi

cp /usr/local/share/groupoffice-docker-config.php.tpl /etc/groupoffice/docker-config.php

sed -i 's/{dbHost}/'${MYSQL_HOST}'/' /etc/groupoffice/docker-config.php
sed -i 's/{dbName}/'${MYSQL_DATABASE}'/' /etc/groupoffice/docker-config.php
sed -i 's/{dbUser}/'${MYSQL_USER}'/' /etc/groupoffice/docker-config.php
sed -i 's/{dbPass}/'${MYSQL_PASSWORD}'/' /etc/groupoffice/docker-config.php

#call original entry point
docker-php-entrypoint "$@"
