#!/bin/bash

echo "upgrading apt-get"
sudo apt-get update
sudo apt-get upgrade

echo "installing all the prerequisites"
sudo apt-get install --assume-yes apache2 apache2-mpm-worker apache2-utils apache2.2-bin apache2.2-common libapr1 libaprutil1 libaprutil1-dbd-sqlite3 build-essential python3.2 python-dev libpython3.2 python3-minimal libapache2-mod-wsgi libaprutil1-ldap memcached python-cairo-dev python-django python-ldap python-memcache python-pysqlite2 sqlite3 erlang-os-mon erlang-snmp rabbitmq-server bzr expect libapache2-mod-python python-setuptools

echo "installing python installer stuff"
sudo easy_install django-tagging zope.interface twisted txamqp

echo "getting graphite, carbon and whisper"
cd ~
wget https://launchpad.net/graphite/0.9/0.9.10/+download/graphite-web-0.9.10.tar.gz --no-check-certificate
wget https://launchpad.net/graphite/0.9/0.9.10/+download/carbon-0.9.10.tar.gz --no-check-certificate
wget https://launchpad.net/graphite/0.9/0.9.10/+download/whisper-0.9.10.tar.gz --no-check-certificate

echo "extracting the zips"
find *.tar.gz -exec tar -zxvf '{}' \;

echo "installing whisper"
cd whisper*
sudo python setup.py install

echo "installing carbon"
cd ../carbon*
sudo python setup.py install

echo "installing grahpite"
cd ../graphite*
sudo python check-dependencies.py
sudo python setup.py install

echo "configuring graphite"
cd /opt/graphite/conf
sudo "echo '[stats]
priority = 110
pattern = .*
retentions = 10:2160,60:10080,600:262974' > storage-schemas.conf"

echo "configuring the graphite db"
cd /opt/graphite/webapp/graphite/
sudo python manage.py syncdb
sudo cp local_settings.py.example local_settings.py

echo "configuring apache"
sudo cp ~/graphite*/examples/example-graphite-vhost.conf /etc/apache2/sites-available/default
sudo cp /opt/graphite/conf/graphite.wsgi.example /opt/graphite/conf/graphite.wsgi
sudo chown -R www-data:www-data /opt/graphite/storage
sudo mkdir -p /etc/httpd/wsgi

# do the file here - sites default...

sudo service apache2 restart

echo "installing statsd"
sudo apt-get install python-software-properties
sudo apt-add-repository ppa:chris-lea/node.js
sudo apt-get update
sudo apt-get install nodejs
sudo apt-get install git
cd /opt
sudo git clone git://github.com/etsy/statsd.git
cd /opt/statsd
sudo echo "{ graphitePort: 2003, graphiteHost: '127.0.0.1', port: 8125}" | sudo tee localConfig.js

echo "starting carbon"
sudo /opt/graphite/bin/carbon-cache.py start

echo "starting statsd"
cd /opt/statsd
node ./stats.js ./localConfig.js


