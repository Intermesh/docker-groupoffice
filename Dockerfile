# Image intermesh/groupoffice
# docker build -t intermesh/groupoffice .

FROM php:7.4-apache
#FROM php:8.0.0RC5-apache-buster

ENV MYSQL_USER groupoffice
ENV MYSQL_PASSWORD groupoffice
ENV MYSQL_DATABASE groupoffice
ENV MYSQL_HOST db

#ENV APACHE_SERVER_NAME localhost
#ENV APACHE_SERVER_ADMIN admin@localhost

EXPOSE 80
EXPOSE 443

# Install PHP build deps, Filesearch utils and mariadb-client is needed for mysqldump in multi_instance module
RUN apt-get update --allow-releaseinfo-change && apt-get dist-upgrade -y && \
    apt-get install -y libxml2-dev libpng-dev libfreetype6-dev libjpeg62-turbo-dev zip tnef ssl-cert libldap2-dev \
	catdoc unzip tar imagemagick tesseract-ocr tesseract-ocr-eng poppler-utils exiv2 libzip-dev \
	libmemcached-dev zlib1g-dev mariadb-client

#sysvshm sysvsem sysvmsg pcntl are for z-push
RUN	docker-php-ext-configure gd --with-freetype --with-jpeg && \
	docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ && \
    docker-php-ext-install soap pdo pdo_mysql calendar gd sysvshm sysvsem sysvmsg ldap opcache intl pcntl zip bcmath && \

#mem cached
RUN yes "" | pecl install memcached && \
	echo "extension=memcached.so" > $PHP_INI_DIR/conf.d/docker-php-ext-memcached.ini

RUN pecl install apcu
RUN docker-php-ext-enable apcu

RUN apt purge -y binutils binutils-common binutils-x86-64-linux-gnu cpp dpkg-dev g++ gcc icu-devtools \
                libasan5 libatomic1 libbinutils libcc1-0 libfreetype6-dev libicu-dev \
                libitm1 libjpeg62-turbo-dev libldap2-dev liblsan0 libmpc3 libmpfr6 libpng-dev \
                libpng-tools libquadmath0  libtsan0 libubsan1 libxml2-dev patch --autoremove && \
                rm -rf /var/lib/apt/lists/*

RUN a2enmod ssl

# SSL volume can be used to replace SSL config and certificates
COPY ./etc/ssl/groupoffice/apache.conf /etc/ssl/groupoffice/apache.conf
VOLUME /etc/ssl/groupoffice

COPY ./etc/php.ini $PHP_INI_DIR

#configure apache
ADD ./etc/apache2/sites-available/000-default.conf $APACHE_CONFDIR/sites-available/000-default.conf
#RUN sed -i 's/{serverName}/'$APACHE_SERVER_NAME'/' /etc/apache2/sites-available/000-default.conf
#RUN sed -i 's/{serverAdmin}/'$APACHE_SERVER_ADMIN'/' /etc/apache2/sites-available/000-default.conf

RUN mkdir -p /etc/groupoffice/multi_instance && chown -R www-data:www-data /etc/groupoffice
#default group-office config
ADD ./etc/groupoffice/config.php.tpl /usr/local/share/groupoffice-config.php.tpl

#For persistant configuration
VOLUME /etc/groupoffice

#Install ioncube
ADD https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz /tmp/

RUN tar xvzfC /tmp/ioncube_loaders_lin_x86-64.tar.gz /tmp/ \
    && rm /tmp/ioncube_loaders_lin_x86-64.tar.gz \
    && mkdir -p /usr/local/ioncube \
    && cp /tmp/ioncube/ioncube_loader_lin_${PHP_VERSION%.*}.so /usr/local/ioncube \
    && rm -rf /tmp/ioncube

RUN echo "zend_extension = /usr/local/ioncube/ioncube_loader_lin_${PHP_VERSION%.*}.so" >> $PHP_INI_DIR/conf.d/00_ioncube.ini

RUN mkdir -p /var/lib/groupoffice/multi_instance && chown -R www-data:www-data /var/lib/groupoffice
#Group-Office data:
VOLUME /var/lib/groupoffice

COPY docker-go-entrypoint.sh /usr/local/bin/

ARG VERSION=6.6.135
ARG PACKAGE=groupoffice-$VERSION

#https://github.com/Intermesh/groupoffice/releases/download/v6.5.35/groupoffice-6.5.35.tar.gz

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
