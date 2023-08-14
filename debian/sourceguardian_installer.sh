#!/usr/bin/env bash
# group-office.com

# Check if PHP CLI is installed
hash php 2>/dev/null || { echo >&2 "The script requires php-cli but it's not installed.  Aborting."; exit 1; }

# Find the system architecture
DPKG_ARCH=$(dpkg --print-architecture)
if [[ "$DPKG_ARCH" = "i386" ]]; then
  ARCH="x86_64"
elif [[ "$DPKG_ARCH" = "arm64" ]]; then
  ARCH="aarch64"
fi

URL=https://www.sourceguardian.com/loaders/download/loaders.linux-${ARCH}.tar.gz

echo "Downloading ${URL}"
# Download and extract
mkdir /usr/local/sourceguardian
curl "${URL}" | tar -xzf - -C /usr/local/sourceguardian
# Find PHP version
PHP_V=$(php -v)
PHP_VERSION=${PHP_V:4:3}

# Add the IonCube loader to the PHP configuration
echo "zend_extension=/usr/local/sourceguardian/ixed.${PHP_VERSION}.lin" \
    > "/etc/php/${PHP_VERSION}/mods-available/sourceguardian.ini"

phpenmod sourceguardian

#mv "/etc/php/${PHP_VERSION}/apache2/conf.d/20-sourceguardian.ini" "/etc/php/${PHP_VERSION}/apache2/conf.d/00-sourceguardian.ini"
#mv "/etc/php/${PHP_VERSION}/cli/conf.d/20-sourceguardian.ini" "/etc/php/${PHP_VERSION}/cli/conf.d/00-sourceguardian.ini"

echo "Reloading apache"

systemctl reload apache2

echo "Installed!"

php -v
