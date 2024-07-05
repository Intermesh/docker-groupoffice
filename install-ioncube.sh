#!/bin/bash
set -e
PLATFORM=$1

if [ "$PLATFORM" = "linux/arm64" ]; then
    ARCH="aarch64";
else

    ARCH="x86-64";
fi

URL=https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_$ARCH.tar.gz

echo $URL;

cd /tmp
curl -O $URL
tar xvzfC /tmp/ioncube_loaders_lin_$ARCH.tar.gz /tmp/ \
    && rm /tmp/ioncube_loaders_lin_$ARCH.tar.gz \
    && mkdir -p /usr/local/ioncube \
    && cp /tmp/ioncube/ioncube_loader_lin_${PHP_VERSION%.*}.so /usr/local/ioncube  \
    && rm -rf /tmp/ioncube

echo "zend_extension = /usr/local/ioncube/ioncube_loader_lin_${PHP_VERSION%.*}.so" >> $PHP_INI_DIR/conf.d/00_ioncube.ini
