# Image intermesh/groupoffice
# docker build --no-cache -t intermesh/groupoffice:debian .

FROM debian:bookworm-slim
#FROM ubuntu:22.10

ENV MYSQL_USER groupoffice
ENV MYSQL_PASSWORD groupoffice
ENV MYSQL_DATABASE groupoffice
ENV MYSQL_HOST db

#ENV APACHE_SERVER_NAME localhost
#ENV APACHE_SERVER_ADMIN admin@localhost

EXPOSE 80
EXPOSE 443

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update
RUN apt-get install -y catdoc unzip tar imagemagick tesseract-ocr tesseract-ocr-eng poppler-utils exiv2 \
		debconf-utils gnupg wget

# Install Group-Office repo and key
RUN echo "deb http://repo.group-office.com/ sixeight  main" > /etc/apt/sources.list.d/groupoffice.list
RUN wget -O- https://repo.group-office.com/downloads/groupoffice.gpg | gpg --dearmor --yes -o /etc/apt/trusted.gpg.d/groupoffice.gpg
RUN apt-get update

# Don't install database
# RUN echo "groupoffice	groupoffice/dbconfig-install	boolean	false" | debconf-set-selections


# Install database
RUN echo "groupoffice	groupoffice/app-password-confirm	password" | debconf-set-selections
# Database type to be used by groupoffice:
RUN echo "groupoffice	groupoffice/database-type	select	mysql" | debconf-set-selections
# MySQL username for groupoffice:
RUN echo "groupoffice	groupoffice/db/app-user	string	groupoffice@localhost" | debconf-set-selections
# MySQL database name for groupoffice:
RUN echo "groupoffice	groupoffice/db/dbname	string	groupoffice" | debconf-set-selections
# Configure database for groupoffice with dbconfig-common?
RUN echo "groupoffice	groupoffice/dbconfig-install	boolean	true" | debconf-set-selections
# Reinstall database for groupoffice?
RUN echo "groupoffice	groupoffice/dbconfig-reinstall	boolean	false" | debconf-set-selections
# Deconfigure database for groupoffice with dbconfig-common?
RUN echo "groupoffice	groupoffice/dbconfig-remove	boolean	true" | debconf-set-selections
# Perform upgrade on database for groupoffice with dbconfig-common?
RUN echo "groupoffice	groupoffice/dbconfig-upgrade	boolean	true" | debconf-set-selections
RUN echo "groupoffice	groupoffice/install-error	select	abort" | debconf-set-selections
RUN echo "groupoffice	groupoffice/internal/reconfiguring	boolean	false" | debconf-set-selections
RUN echo "groupoffice	groupoffice/internal/skip-preseed	boolean	false" | debconf-set-selections
RUN echo "groupoffice	groupoffice/missing-db-package-error	select	abort" | debconf-set-selections
RUN echo "groupoffice	groupoffice/mysql/admin-pass	password" | debconf-set-selections
RUN echo "groupoffice	groupoffice/mysql/admin-user	string	root" | debconf-set-selections
# MySQL application password for groupoffice:
RUN echo "groupoffice	groupoffice/mysql/app-pass	password" | debconf-set-selections
RUN echo "groupoffice	groupoffice/mysql/authplugin	select	default" | debconf-set-selections
# Connection method for MySQL database of groupoffice:
RUN echo "groupoffice	groupoffice/mysql/method	select	Unix socket" | debconf-set-selections
RUN echo "groupoffice	groupoffice/password-confirm	password" | debconf-set-selections
RUN echo "groupoffice	groupoffice/passwords-do-not-match	error" | debconf-set-selections
# Delete the database for groupoffice?
RUN echo "groupoffice	groupoffice/purge	boolean	false" | debconf-set-selections
# Host name of the MySQL database server for groupoffice:
RUN echo "groupoffice	groupoffice/remote/host	select	localhost" | debconf-set-selections
# Host running the MySQL server for groupoffice:
RUN echo "groupoffice	groupoffice/remote/newhost	string" | debconf-set-selections
RUN echo "groupoffice	groupoffice/remote/port	string" | debconf-set-selections
RUN echo "groupoffice	groupoffice/remove-error	select	abort" | debconf-set-selections
# Back up the database for groupoffice before upgrading?
RUN echo "groupoffice	groupoffice/upgrade-backup	boolean	true" | debconf-set-selections
RUN echo "groupoffice	groupoffice/upgrade-error	select	abort" | debconf-set-selections


# RUN cat /etc/apt/sources.list.d/groupoffice.list
# RUN cat /etc/apt/sources.list
RUN apt-get -y install groupoffice php-apcu

RUN a2enmod ssl

# SSL volume can be used to replace SSL config and certificates
COPY ./etc/ssl/groupoffice/apache.conf /etc/ssl/groupoffice/apache.conf
VOLUME /etc/ssl/groupoffice

COPY ./etc/php.ini /usr/local/etc/php/

#configure apache
ADD ./etc/apache2/sites-available/000-default.conf /etc/apache2/sites-available/000-default.conf


RUN mkdir -p /etc/groupoffice/multi_instance && chown -R www-data:www-data /etc/groupoffice
#default group-office config
run touch /etc/groupoffice/config.php
run chown www-data:www-data /etc/groupoffice/config.php
#For persistant multi instances
VOLUME /etc/groupoffice

#Install ioncube
# ADD ./ioncube_installer.sh /usr/local/bin
#RUN /usr/local/bin/ioncube_installer.sh

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
RUN apt-get purge -y --auto-remove debconf-utils dirmngr gnupg wget
