FROM php:7.3-apache
ARG PACKAGE=groupoffice-6.4.92-php-71

ENV MYSQL_USER groupoffice
ENV MYSQL_PASSWORD groupoffice
ENV MYSQL_DATABASE groupoffice
ENV MYSQL_HOST db

#ENV APACHE_SERVER_NAME localhost
#ENV APACHE_SERVER_ADMIN admin@localhost

EXPOSE 80
EXPOSE 443

RUN apt-get update && \
    apt-get install -y libxml2-dev libpng-dev libfreetype6-dev libjpeg62-turbo-dev zip tnef ssl-cert libldap2-dev \
		catdoc unzip tar imagemagick tesseract-ocr tesseract-ocr-eng poppler-utils exiv2 libzip-dev mariadb-client && \
		docker-php-ext-configure gd --with-freetype-dir=/usr/include/ --with-jpeg-dir=/usr/include/ && \
		docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu/ && \
    docker-php-ext-install soap pdo pdo_mysql calendar gd sysvshm sysvsem sysvmsg ldap opcache intl pcntl zip

#sysvshm sysvsem sysvmsg pcntl are for z-push

RUN pecl install apcu
RUN docker-php-ext-enable apcu

RUN a2enmod ssl

# SSL volume can be used to replace SSL config and certificates
COPY ./etc/ssl/groupoffice/apache.conf /etc/ssl/groupoffice/apache.conf
VOLUME /etc/ssl/groupoffice

COPY ./etc/php.ini /usr/local/etc/php/

#configure apache
ADD ./etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/000-default.conf
#RUN sed -i 's/{serverName}/'$APACHE_SERVER_NAME'/' /etc/apache2/sites-available/000-default.conf
#RUN sed -i 's/{serverAdmin}/'$APACHE_SERVER_ADMIN'/' /etc/apache2/sites-available/000-default.conf

RUN mkdir -p /etc/groupoffice/multi_instance && chown -R www-data:www-data /etc/groupoffice
#default group-office config
ADD ./etc/groupoffice/config.php.tpl /etc/groupoffice/config.php.tpl

#For persistant multi instances
VOLUME /etc/groupoffice/multi_instance


#Download package from sourceforge
ADD https://iweb.dl.sourceforge.net/project/group-office/6.4/$PACKAGE.tar.gz /tmp/
#COPY /groupoffice-com-6.3.3-php-71.tar.gz /tmp/
RUN tar zxvfC /tmp/$PACKAGE.tar.gz /tmp/ \
    && rm /tmp/$PACKAGE.tar.gz \
    && mv /tmp/$PACKAGE /usr/local/share/groupoffice

#Install ioncube
ADD https://downloads.ioncube.com/loader_downloads/ioncube_loaders_lin_x86-64.tar.gz /tmp/

RUN tar xvzfC /tmp/ioncube_loaders_lin_x86-64.tar.gz /tmp/ \
    && rm /tmp/ioncube_loaders_lin_x86-64.tar.gz \
    && mkdir -p /usr/local/ioncube \
    && cp /tmp/ioncube/ioncube_loader_* /usr/local/ioncube \
    && rm -rf /tmp/ioncube

RUN echo "zend_extension = /usr/local/ioncube/ioncube_loader_lin_7.3.so" >> /usr/local/etc/php/conf.d/00_ioncube.ini

RUN mkdir -p /var/lib/groupoffice/multi_instance && chown -R www-data:www-data /var/lib/groupoffice
#Group-Office data:
VOLUME /var/lib/groupoffice

COPY docker-go-entrypoint.sh /usr/local/bin/

CMD ["apache2-foreground"]
ENTRYPOINT ["docker-go-entrypoint.sh"]
