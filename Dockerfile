# Image intermesh/groupoffice
# docker build -t intermesh/groupoffice:debian .

FROM debian:bookworm-slim
#FROM php:8.0.0RC5-apache-buster

ENV MYSQL_USER groupoffice
ENV MYSQL_PASSWORD groupoffice
ENV MYSQL_DATABASE groupoffice
ENV MYSQL_HOST db

#ENV APACHE_SERVER_NAME localhost
#ENV APACHE_SERVER_ADMIN admin@localhost

EXPOSE 80
EXPOSE 443

RUN apt update
RUN apt install -y catdoc unzip tar imagemagick tesseract-ocr tesseract-ocr-eng poppler-utils exiv2 \
		debconf-utils dirmngr gnupg wget

# Install Group-Office repo and key
RUN echo "deb http://repo.group-office.com/ unstable  main" > /etc/apt/sources.list.d/groupoffice.list
RUN apt-key adv --recv-keys --keyserver pool.sks-keyservers.net 0758838B
RUN apt update

# Don't install database
RUN echo "groupoffice	groupoffice/dbconfig-install	boolean	false" | debconf-set-selections

RUN apt -y install groupoffice php-apcu

RUN a2enmod ssl

# SSL volume can be used to replace SSL config and certificates
COPY ./etc/ssl/groupoffice/apache.conf /etc/ssl/groupoffice/apache.conf
VOLUME /etc/ssl/groupoffice

COPY ./etc/php.ini /usr/local/etc/php/

#configure apache
ADD ./etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/000-default.conf


RUN mkdir -p /etc/groupoffice/multi_instance && chown -R www-data:www-data /etc/groupoffice
#default group-office config
ADD ./etc/groupoffice/config.php.tpl /etc/groupoffice/config.php.tpl

#For persistant multi instances
VOLUME /etc/groupoffice/multi_instance

#Install ioncube
ADD ./ioncube_installer.sh /usr/local/bin
RUN /usr/local/bin/ioncube_installer.sh

RUN mkdir -p /var/lib/groupoffice/multi_instance && chown -R www-data:www-data /var/lib/groupoffice
#Group-Office data:
VOLUME /var/lib/groupoffice


# output apache log to stderr and stdout
RUN ln -sfT /dev/stderr /var/log/apache2/error.log; \
	ln -sfT /dev/stdout /var/log/apache2/access.log; \
	ln -sfT /dev/stdout /var/log/apache2/other_vhosts_access.log; \
	chown -R --no-dereference www-data:www-data /var/log/apache2

COPY docker-go-entrypoint.sh /usr/local/bin/

ENTRYPOINT ["docker-go-entrypoint.sh"]

# clean up
RUN apt purge -y --auto-remove debconf-utils dirmngr gnupg wget
