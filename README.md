docker-groupoffice
==================

Group-Office is an open source groupware system.

I recommend using this with docker-compose.


Using docker-compose
--------------------

Create this docker-compose.yml file:

````````````````````
version: "3.1"
services:
  groupoffice:
    image: intermesh/groupoffice
    restart: always
    ports:
      - "8004:80"
    links:
      - db
    volumes:
      - "godata:/var/lib/groupoffice:cached"
      - "goetc:/etc/groupoffice:cached"
    env_file:
      - ./db.env     
  db:
    image: mariadb
    restart: always    
    env_file:
      - ./db.env
    environment:
      MYSQL_ROOT_PASSWORD: groupoffice
    volumes:
      - "dbdata:/var/lib/mysql:cached"
volumes:
  godata:
  goetc:
  dbdata:
````````````````````

And put "db.env" in the same folder with the passwords:

``````````````````````````
MYSQL_USER=groupoffice
MYSQL_PASSWORD=groupoffice
MYSQL_DATABASE=groupoffice
``````````````````````````

Run this command in the folder where these files are to start the containers:

````````````````````
docker-compose up -d
````````````````````

Then launch your browser to http://localhost:8004 and the Group-Office installer should appear.


Using docker cli:
------------------------

1. Create a "data" directory (eg. ~/Projects/docker-groupoffice-6.2/data)
2. Setup a database container that's on the default network
3. Run this command:

````
docker run --name groupoffice -d -p 6380:80 -v ~/Projects/docker-groupoffice-6.3/data:/var/lib/groupoffice --link go_db:db intermesh/groupoffice
````


Running a 6.2 group-office container:
-------------------------------------

1. Create a "data" directory (eg. ~/Projects/docker-groupoffice-6.2/data)
2. Setup a database container that's on the default network
3. Create a source directory (~/Projects/groupoffice-6.2/www)
4. Create a "etc/groupoffice" directory with empty config.php file in it (~/Projects/docker-groupoffice-6.2/etc/groupoffice:/etc/groupoffice)
5. Run this command to start:

````````
docker run --name groupoffice-62 -d -p 6280:80 -v ~/Projects/docker-groupoffice-6.2/data:/var/lib/groupoffice -v ~/Projects/groupoffice-6.2/www:/usr/local/share/groupoffice -v ~/Projects/docker-groupoffice-6.2/etc/groupoffice:/etc/groupoffice --link go_db:db intermesh/groupoffice
''''''''
