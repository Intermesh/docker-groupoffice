Group-Office Docker image
=========================

Group-Office is an open source groupware system. More information can be found at https://www.group-office.com.

I recommend using this with docker compose.


Using docker compose
--------------------

Clone this repository and run from inside the directory:

````````````````````
docker compose up -d
````````````````````

Then launch your browser to http://localhost:9090 and the Group-Office installer should appear.

### Cron job

You should also configure a cron job on the host machine so that Group Office can run scheduled tasks. 
   
On Linux create a file /etc/cron.d/groupoffice and add (replace /path/to/docker-groupoffice):

```cron
* * * * * root cd /path/to/docker-groupoffice && docker compose exec -u www-data -T groupoffice php /usr/local/share/groupoffice/cron.php
```

> On MacOS I ran on the terminal:
>
> ```bash
> crontab -e
> ```
>
> And added:
>
> ```bash
> * * * * * cd /path/to/docker-groupoffice && docker compose exec -u www-data -T groupoffice php /usr/local/share/groupoffice/cron.php
> ```

### Upgrading

Check the image tag in your compose.yml for the current version. For example "intermesh/groupoffice:25.0".
Make sure it's not on "latest". The reason is that you need to upgrade major releases step by step. A major release is when
the first or second digit of the version increases. For example you can upgrade 25.0 to 25.1 but not 25.0 to 25.2.

If you're doing a major release upgrade and you run the professional license then make sure to install the latest license key from your group-office.com account in the
contracts section (https://www.group-office.com/account#account/contracts) if you run
the professional version. This can be done via the browser GUI in the main menu -> register or via CLI:

```
docker compose exec -u www-data groupoffice php /usr/local/share/groupoffice/cli.php core/System/setLicense --key=<YOURKEY>
```

Navigate in the folder of this repo and checkout another branch:
Check branches:

```
git branch -a
```

Select a version and checkout this branch:

```
git checkout VERSION
```

Pull the image:
```
docker compose pull
```

Run the containers with the new image:
```
docker compose up -d
```
Then run http://localhost:9090/install/upgrade.php

### Collabora Online integration

To enable Collabora Online integration you need to start the collabora container too with:

```
docker compose -f compose.yml -f collabora.yml up -d
```

See https://www.group-office.com/blog/2026/01/collabora-online-integration for a complete guide.


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

HTTP Proxy
----------
When using a HTTP proxy to forward requests to the Docker container you need to set some headers to tell Group-Office about the real hostname. Read more about this here: https://groupoffice.readthedocs.io/en/latest/install/extras/httpproxy.html

Enable debug mode
-----------------
You can enable debug mode with this command on the host:
```
docker compose exec groupoffice sed -i "s/config\['debug'\] = false;/config\['debug'\] = true;/" /etc/groupoffice/config.php
```

Then you can read the debug log with this command on the host:

```
docker compose exec groupoffice tail -f /var/lib/groupoffice/log/debug.log
```



Using docker cli
----------------

1. Create a "data" directory (eg. ~/Projects/docker-groupoffice-6.2/data)
2. Setup a database container that's on the default network
3. Run this command:

````
docker run --name groupoffice -d -p 6380:80 -v ~/Projects/docker-groupoffice/data:/var/lib/groupoffice --link go_db:db intermesh/groupoffice:26.0
````
