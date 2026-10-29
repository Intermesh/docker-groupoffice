# Image intermesh/groupoffice

# To build test image:

# Disable build kit to make docker compose use the local image
# DOCKER_BUILDKIT=0 && docker buildx build --load . -t intermesh/groupoffice:local
# DOCKER_BUILDKIT=0 && docker compose build serviceusingtesting

FROM php:8.4-apache

ENV MYSQL_USER=groupoffice
ENV MYSQL_DATABASE=groupoffice
ENV MYSQL_HOST=db

EXPOSE 80
EXPOSE 443

ARG DEBIAN_FRONTEND=noninteractive

# Install PHP build deps, Filesearch utils and mariadb-client is needed for mysqldump in multi_instance module
# dnsutils is used for nslookups by maildomains module

# Everything is done in a single layer so that build dependencies, apt lists and
# PHP sources that are removed at the end do not end up in the image.
RUN apt-get update --allow-releaseinfo-change \
    && apt-get dist-upgrade -y \
    # needed for compiling
    && apt-get install -y libxml2-dev libpng-dev libfreetype6-dev libjpeg62-turbo-dev libldap2-dev \
        libzip-dev zlib1g-dev libicu-dev \
    # needed for documents module
    # catdoc unzip tar imagemagick tesseract-ocr tesseract-ocr-eng poppler-utils exiv2
    # needed for runtime
    && apt-get install -y zip tnef ssl-cert mariadb-client dnsutils libldap-common libzip5 \
    # heif support
    && apt-get install -y libheif-dev libheif1 libmagickwand-dev libgomp1 imagemagick \
    #sysvshm sysvsem sysvmsg pcntl are for z-push
    && docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-configure ldap \
    && docker-php-ext-install -j$(nproc) soap pdo pdo_mysql calendar gd sysvshm sysvsem sysvmsg ldap intl pcntl zip bcmath exif \
    && pecl install imagick apcu \
    && docker-php-ext-enable imagick apcu \
    && curl -sSLf \
        -o /usr/local/bin/install-php-extensions \
        https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions \
    && chmod +x /usr/local/bin/install-php-extensions \
    && install-php-extensions sourceguardian \
    #mem cached
    #&& yes "" | pecl install memcached && echo "extension=memcached.so" > $PHP_INI_DIR/conf.d/docker-php-ext-memcached.ini \
    # cleanup
    && docker-php-source delete \
    # keep the runtime libraries the compiled extensions link against so autoremove won't purge them
    && find /usr/local/lib/php/extensions -name '*.so' -exec ldd {} + \
        | awk '/=>/ { so = $(NF-1); if (index(so, "/usr/local/") == 1) { next }; gsub("^/(usr/)?", "", so); print so }' \
        | sort -u \
        | xargs -r dpkg-query --search \
        | cut -d: -f1 \
        | sort -u \
        | xargs -r apt-mark manual \
    && apt-get purge -y binutils binutils-common cpp dpkg-dev g++ gcc \
        libitm1 liblsan0 libmpc3 libmpfr6 \
        libpng-tools libubsan1 libxml2-dev libpng-dev libfreetype6-dev libjpeg62-turbo-dev libldap2-dev \
        libzip-dev zlib1g-dev libicu-dev patch libmagickwand-dev libheif-dev --autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/pear ~/.pearrc

RUN a2enmod ssl

# SSL volume can be used to replace SSL config and certificates
COPY ./etc/ssl/groupoffice/apache.conf /etc/ssl/groupoffice/apache.conf
COPY ./etc/ssl/openssl.cnf /etc/ssl/openssl.cnf
VOLUME /etc/ssl/groupoffice

COPY ./etc/php.ini $PHP_INI_DIR

#configure apache
COPY ./etc/apache2/sites-available/000-default.conf $APACHE_CONFDIR/sites-available/000-default.conf

#default group-office config
COPY ./etc/groupoffice/docker-config.php.tpl /usr/local/share/groupoffice-docker-config.php.tpl
COPY ./etc/groupoffice/config.php /usr/local/share/groupoffice-config.php

RUN mkdir -p /etc/groupoffice/multi_instance && chown -R www-data:www-data /etc/groupoffice
RUN cp -a /usr/local/share/groupoffice-config.php /etc/groupoffice/config.php

#For persistant configuration
VOLUME /etc/groupoffice

RUN mkdir -p /var/lib/groupoffice/multi_instance && chown -R www-data:www-data /var/lib/groupoffice
#Group-Office data:
VOLUME /var/lib/groupoffice

COPY docker-go-entrypoint.sh /usr/local/bin/

ARG VERSION=26.0.56
ARG PACKAGE=groupoffice-$VERSION

#Download package from GitHub. Streamed through tar so the tarball is not kept in a layer.
RUN curl -sSLf https://github.com/Intermesh/groupoffice/releases/download/v$VERSION/$PACKAGE.tar.gz \
        | tar zxC /tmp/ \
    && mv /tmp/$PACKAGE /usr/local/share/groupoffice

CMD ["apache2-foreground"]
ENTRYPOINT ["docker-go-entrypoint.sh"]
