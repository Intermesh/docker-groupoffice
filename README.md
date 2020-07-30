docker-groupoffice
==================

Group-Office is an open source groupware system. More information can be found at https://www.group-office.com.

I recommend using this with docker-compose.


Using docker-compose
--------------------

Clone this repository and run from inside the directory:

````````````````````
docker-compose up -d
````````````````````

Then launch your browser to http://localhost:9000 and the Group-Office installer should appear.

### Upgrading

Navigate in the folder with docker-compose.yml and pull the image:
```
docker-compose pull
```

Bring the containers down:
```
docker-compose down
```

Then start them again:
```
docker-compose up -d
```
Then run http://localhost:9000/install/upgrade.php

SSL Certificates
----------------

SSL is enabled by default but it uses a self-signed certificate. You can use
a real certificate by mounting /etc/ssl/groupoffice. You can find an example in the docker-compose.yml file.

Put your certificates there and the /etc/apache2/sites-enabled/000-default.conf will
include a config file /etc/ssl/groupoffice/apache.conf. You can put the SSL directives in that file.
For example:

```
SSLCertificateKeyFile /etc/ssl/groupoffice/certificate.key
SSLCertificateFile /etc/ssl/groupoffice/certificate.crt
SSLCertificateChainFile /etc/ssl/groupoffice/cabundle.crt
```

Pro licenses
------------
In the docker-compose.yml file you find example of how you can put the pro license files in the container with bind mounts.

Enable debug mode
-----------------
You can enable debug mode with this command on the host:
```
docker-compose exec groupoffice sed -i "s/config\['debug'\] = false;/config\['debug'\] = true;/" /etc/groupoffice/config.php
```

Using docker cli
----------------

1. Create a "data" directory (eg. ~/Projects/docker-groupoffice-6.2/data)
2. Setup a database container that's on the default network
3. Run this command:

````
docker run --name groupoffice -d -p 6380:80 -v ~/Projects/docker-groupoffice-6.3/data:/var/lib/groupoffice --link go_db:db intermesh/groupoffice
````


Running a 6.2 group-office container
------------------------------------

1. Create a "data" directory (eg. ~/Projects/docker-groupoffice-6.2/data)
2. Setup a database container that's on the default network
3. Create a source directory (~/Projects/groupoffice-6.2/www)
4. Create a "etc/groupoffice" directory with empty config.php file in it (~/Projects/docker-groupoffice-6.2/etc/groupoffice:/etc/groupoffice)
5. Run this command to start:

```
docker run --name groupoffice-62 -d -p 6280:80 -v ~/Projects/docker-groupoffice-6.2/data:/var/lib/groupoffice -v ~/Projects/groupoffice-6.2/www:/usr/local/share/groupoffice -v ~/Projects/docker-groupoffice-6.2/etc/groupoffice:/etc/groupoffice --link go_db:db intermesh/groupoffice
```
