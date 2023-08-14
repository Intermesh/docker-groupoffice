#!/bin/bash
set -e
PLATFORM=$1

if [ "$PLATFORM" = "linux/arm64" ]; then
    ARCH="aarch64";
else

    ARCH="x86_64";
fi

URL=https://www.sourceguardian.com/loaders/download/loaders.linux-${ARCH}.tar.gz

echo "Downloading ${URL}"
# Download and extract
mkdir /usr/local/sourceguardian
curl "${URL}" | tar -xzf - -C /usr/local/sourceguardian

echo "zend_extension = /usr/local/sourceguardian/ixed.${PHP_VERSION}.lin" > $PHP_INI_DIR/conf.d/20_sourceguardian.ini
