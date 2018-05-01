# docker-groupoffice

Running default with 6.3:

1. Create a "data" directory (eg. ~/Projects/docker-groupoffice-6.2/data)
2. Setup a database container that's on the default network
3. Run this command:

docker run --name groupoffice -d -p 6380:80 -v ~/Projects/docker-groupoffice-6.3/data:/var/lib/groupoffice --link go_db:db intermesh/groupoffice



Running a 6.2 group-office container:

1. Create a "data" directory (eg. ~/Projects/docker-groupoffice-6.2/data)
2. Setup a database container that's on the default network
3. Create a source directory (~/Projects/groupoffice-6.2/www)
4. Create a "etc/groupoffice" directory with empty config.php file in it (~/Projects/docker-groupoffice-6.2/etc/groupoffice:/etc/groupoffice)
5. Run this command to start:

docker run --name groupoffice-62 -d -p 6280:80 -v ~/Projects/docker-groupoffice-6.2/data:/var/lib/groupoffice -v ~/Projects/groupoffice-6.2/www:/usr/local/share/groupoffice -v ~/Projects/docker-groupoffice-6.2/etc/groupoffice:/etc/groupoffice --link go_db:db intermesh/groupoffice
