# Image intermesh/groupoffice

# To build test image:

# Disable build kit to make docker compose use the local image
# DOCKER_BUILDKIT=0 && docker buildx build --load . -t intermesh/groupoffice:local
# DOCKER_BUILDKIT=0 && docker compose build serviceusingtesting

# Build stage: compiles the PHP extensions. Compilers, -dev packages and PHP sources stay in this stage
# and never end up in the published image, so it can use as many layers as is convenient.
FROM php:8.5-apache AS build

ARG DEBIAN_FRONTEND=noninteractive

RUN apt-get update --allow-releaseinfo-change \
    && apt-get install -y libxml2-dev libpng-dev libfreetype6-dev libjpeg62-turbo-dev libldap2-dev \
        libzip-dev zlib1g-dev libicu-dev libheif-dev libmagickwand-dev

#sysvshm sysvsem sysvmsg pcntl are for z-push
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-configure ldap \
    && docker-php-ext-install -j$(nproc) soap pdo pdo_mysql calendar gd sysvshm sysvsem sysvmsg ldap intl pcntl zip bcmath exif

# MAKEFLAGS makes pecl compile in parallel too
RUN MAKEFLAGS="-j$(nproc)" pecl install imagick apcu \
    && docker-php-ext-enable imagick apcu

RUN curl -sSLf \
        -o /usr/local/bin/install-php-extensions \
        https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions \
    && chmod +x /usr/local/bin/install-php-extensions \
    && install-php-extensions sourceguardian

#mem cached
#RUN yes "" | pecl install memcached && echo "extension=memcached.so" > $PHP_INI_DIR/conf.d/docker-php-ext-memcached.ini

# List the Debian packages that provide the libraries the compiled extensions link against
RUN find /usr/local/lib/php/extensions -name '*.so' -exec ldd {} + \
        | awk '/=>/ { so = $(NF-1); if (index(so, "/usr/local/") == 1) { next }; gsub("^/(usr/)?", "", so); print so }' \
        | sort -u \
        | xargs -r dpkg-query --search \
        # skip gdb scripts in /usr/share that -dev packages ship under the library's name
        | grep -v ': /usr/share/' \
        | cut -d: -f1 \
        | sort -u \
        > /runtime-packages.txt


FROM php:8.5-apache

ENV MYSQL_USER=groupoffice
ENV MYSQL_DATABASE=groupoffice
ENV MYSQL_HOST=db

EXPOSE 80
EXPOSE 443

ARG DEBIAN_FRONTEND=noninteractive

COPY --from=build /usr/local/lib/php/extensions/ /usr/local/lib/php/extensions/
COPY --from=build /usr/local/etc/php/conf.d/ /usr/local/etc/php/conf.d/
COPY --from=build /runtime-packages.txt /tmp/runtime-packages.txt

# Install the runtime libraries of the compiled extensions, Filesearch utils and mariadb-client is needed for mysqldump in multi_instance module
# dnsutils is used for nslookups by maildomains module
RUN apt-get update --allow-releaseinfo-change \
    && apt-get dist-upgrade -y \
    && xargs -r -a /tmp/runtime-packages.txt apt-get install -y \
    # needed for documents module
    # catdoc unzip tar imagemagick tesseract-ocr tesseract-ocr-eng poppler-utils exiv2
    # needed for runtime
    && apt-get install -y zip tnef ssl-cert mariadb-client dnsutils libldap-common libzip5 netbase \
    # heif support
    && apt-get install -y libheif1 libgomp1 imagemagick \
    # the extra coders (EXR, SVG, WMF, DjVu, dot, pango) are not used and pull in libraries with open CVE's like OpenEXR
    && apt-get purge -y libmagickcore-7.q16-10-extra --autoremove \
    # the php base image ships compilers for docker-php-ext-install, they are not needed at runtime
    && apt-get purge -y binutils binutils-common cpp dpkg-dev g++ gcc patch --autoremove \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/runtime-packages.txt

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

ARG VERSION=26.1.1
ARG PACKAGE=groupoffice-$VERSION

#Download package from GitHub. Streamed through tar so the tarball is not kept in a layer.
RUN curl -sSLf https://github.com/Intermesh/groupoffice/releases/download/v$VERSION/$PACKAGE.tar.gz \
        | tar zxC /tmp/ \
    && mv /tmp/$PACKAGE /usr/local/share/groupoffice

CMD ["apache2-foreground"]
ENTRYPOINT ["docker-go-entrypoint.sh"]
