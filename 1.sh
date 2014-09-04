
#!/bin/sh
# Script for me to automatically install Server requirements.
#
# BEFORE RUNNING THIS SCRIPT MAKE SURE YOU INSTALL CentOS 7
########## Prepare server ##########
rm -f /var/cache/yum/timedhosts.txt;
yum clean all;
useradd tr --home-dir=/var/www;
yum -y install yum-fastestmirror;

sudo rpm -Uvh http://nginx.org/packages/centos/7/noarch/RPMS/nginx-release-centos-7-0.el7.ngx.noarch.rpm
sudo yum -y install nginx vim wget git rysnc
sudo systemctl start nginx.service
sudo systemctl enable nginx.service
ip addr show eth0 | grep inet | awk '{ print $2; }' | sed 's/\/.*$//'
#your files are here /usr/share/nginx/html

sudo yum -y install pcre pcre-devel openssl openssl-devel


yum install http://www.percona.com/downloads/percona-release/percona-release-0.0-1.x86_64.rpm
yum list | grep percona


sudo yum install Percona-Server-server-56 Percona-Server-client-56
sudo /etc/init.d/mysql start
sudo /usr/bin/mysql_secure_installation
mysql -u root -p
sudo service mysql stop
sudo rm /var/lib/mysql/ib_logfile
vim /etc/my.cnf
sudo service mysql start

rpm -Uvh http://download.fedoraproject.org/pub/epel/7/x86_64/epel-release-7-0.noarch.rpm
rpm -Uvh http://rpms.famillecollet.com/enterprise/remi-release-7.rpm
sudo yum --enablerepo=remi install php 
sudo yum --enablerepo=remi install php-mcrypt
sudo yum install unzip


curl  -k -sS https://getcomposer.org/installer | php
echo $PATH
sudo mv composer.phar /usr/local/bin/composer
wget https://github.com/laravel/laravel/archive/develop.zip
unzip develop
mv laravel-develop /var/www/yoursite
d /var/www/yoursite
composer install
chmod –R  775 /var/www/yoursite/app/storage
