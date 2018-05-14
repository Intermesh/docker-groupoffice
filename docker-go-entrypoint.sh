#!/bin/sh
set -e

chown -R www-data:www-data /var/lib/groupoffice

#call original entry point
docker-php-entrypoint "$@"
