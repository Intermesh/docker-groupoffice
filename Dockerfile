# Image intermesh/groupoffice

# To build test image:

# Disable build kit to make docker compose use the local image
# DOCKER_BUILDKIT=0 && docker buildx build --load . -t intermesh/groupoffice:local
# DOCKER_BUILDKIT=0 && docker compose build serviceusingtesting

FROM php:8.4-apache-bookworm

ENV MYSQL_USER=groupoffice
ENV MYSQL_PASSWORD=groupoffice
ENV MYSQL_DATABASE=groupoffice
ENV MYSQL_HOST=db

#ENV APACHE_SERVER_NAME localhost
#ENV APACHE_SERVER_ADMIN admin@localhost

EXPOSE 80
EXPOSE 443

ARG DEBIAN_FRONTEND=noninteractive

# Install PHP build deps, Filesearch utils and mariadb-client is needed for mysqldump in multi_instance module
# dnsutils is used for nslookups by maildomains module

RUN apt-get update --allow-releaseinfo-change
RUN apt-get dist-upgrade -y 
RUN apt-get install -y libxml2-dev libpng-dev libfreetype6-dev libjpeg62-turbo-dev zip tnef ssl-cert libldap2-dev \
	catdoc unzip tar imagemagick tesseract-ocr tesseract-ocr-eng poppler-utils exiv2 libzip-dev \
	zlib1g-dev mariadb-client dnsutils

#sysvshm sysvsem sysvmsg pcntl are for z-push
RUN	docker-php-ext-configure gd --with-freetype --with-jpeg && \
	docker-php-ext-configure ldap && \
    docker-php-ext-install -j$(nproc) soap pdo pdo_mysql calendar gd sysvshm sysvsem sysvmsg ldap opcache intl pcntl zip bcmath exif

RUN curl -sSLf \
        -o /usr/local/bin/install-php-extensions \
        https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions && \
    chmod +x /usr/local/bin/install-php-extensions && \
    install-php-extensions sourceguardian

#mem cached
#RUN yes "" | pecl install memcached && \
#	echo "extension=memcached.so" > $PHP_INI_DIR/conf.d/docker-php-ext-memcached.ini

RUN pecl install apcu
RUN docker-php-ext-enable apcu

RUN apt purge -y binutils binutils-common cpp dpkg-dev g++ gcc icu-devtools \
                libatomic1 libbinutils libcc1-0 libfreetype6-dev libicu-dev \
                libitm1 libjpeg62-turbo-dev libldap2-dev liblsan0 libmpc3 libmpfr6 libpng-dev \
                libpng-tools libubsan1 libxml2-dev patch --autoremove && \
                rm -rf /var/lib/apt/lists/*

RUN a2enmod ssl

# SSL volume can be used to replace SSL config and certificates
COPY ./etc/ssl/groupoffice/apache.conf /etc/ssl/groupoffice/apache.conf
COPY ./etc/ssl/openssl.cnf /etc/ssl/openssl.cnf
VOLUME /etc/ssl/groupoffice

COPY ./etc/php.ini $PHP_INI_DIR

#configure apache
ADD ./etc/apache2/sites-available/000-default.conf $APACHE_CONFDIR/sites-available/000-default.conf

RUN mkdir -p /etc/groupoffice/multi_instance && chown -R www-data:www-data /etc/groupoffice
#default group-office config
ADD ./etc/groupoffice/docker-config.php.tpl /usr/local/share/groupoffice-docker-config.php.tpl
ADD ./etc/groupoffice/config.php /etc/groupoffice/config.php

#For persistant configuration
VOLUME /etc/groupoffice

RUN mkdir -p /var/lib/groupoffice/multi_instance && chown -R www-data:www-data /var/lib/groupoffice
#Group-Office data:
VOLUME /var/lib/groupoffice

COPY docker-go-entrypoint.sh /usr/local/bin/

ARG VERSION=25.0.44
ARG PACKAGE=groupoffice-$VERSION

#Download package from GitHub
ADD https://github.com/Intermesh/groupoffice/releases/download/v$VERSION/$PACKAGE.tar.gz /tmp/
RUN tar zxvfC /tmp/$PACKAGE.tar.gz /tmp/ \
    && rm /tmp/$PACKAGE.tar.gz \
    && mv /tmp/$PACKAGE /usr/local/share/groupoffice

#Create studio subdirectory, make writable
RUN mkdir -p /usr/local/share/groupoffice/go/modules/studio \
    && chown -R www-data:www-data /usr/local/share/groupoffice/go/modules

CMD ["apache2-foreground"]
ENTRYPOINT ["docker-go-entrypoint.sh"]
