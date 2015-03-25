#!/usr/bin/env bash

sudo mysql --version > /dev/null 2>&1
MYSQL_IS_INSTALLED=$?
if [[ $MYSQL_IS_INSTALLED -ne 0 ]]; then
    echo "!!! phpMyAdmin requires MySQL to be installed.";
    exit 1;
fi

# Test if PHP is installed
sudo php -v > /dev/null 2>&1
PHP_IS_INSTALLED=$?

if [[ $PHP_IS_INSTALLED -ne 0 ]]; then
    echo "!!! phpMyAdmin requires PHP to be installed";
    exit 1;
fi

# Check for nginx
sudo nginx -v > /dev/null 2>$1
NGING_IS_INSTALLED=$?
# Check for Apache
sudo apache2 -v > /dev/null 2>$1
APACHE_IS_INSTALLED=$?

echo "phpmyadmin	phpmyadmin/mysql/admin-pass	password	$2" | sudo debconf-set-selections
echo "phpmyadmin	phpmyadmin/app-password-confirm	password	$2" | sudo debconf-set-selections
echo "phpmyadmin	phpmyadmin/dbconfig-install	boolean	true" | sudo debconf-set-selections
echo "phpmyadmin	phpmyadmin/setup-password	password	$2" | sudo debconf-set-selections
echo "phpmyadmin	phpmyadmin/mysql/app-pass	password	$2" | sudo debconf-set-selections
echo "phpmyadmin	phpmyadmin/password-confirm	password	$2" | sudo debconf-set-selections
echo "phpmyadmin	phpmyadmin/reconfigure-webserver	multiselect	apache1" | sudo debconf-set-selections

sudo apt-get install -y -qq phpmyadmin
sudo find /usr ! -path "*/doc/*" ! -path "*/dbconfig*" -type d -name phpmyadmin > /dev/null 2>&1
public_folder=$?

# Make a vhost for nginx
if [[ $NGING_IS_INSTALLED -eq 0 ]]; then
    sudo ngxcb -d $public_folder -n $hostname -s "$1.xip.io $hostname" -e
fi

# MAke a vhost for Apache
if [[ $APACHE_IS_INSTALLED -eq 0 ]]; then
    sudo vhost -s $1.xip.io -d $public_folder -p /etc/ssl/xip.io -c xip.io -a "$1.xip.io $hostname"
else
    # phpMyAdmin cannot be installed without a web server - so we purge apache from system
    sudo apt-get purge -qq apache2*
fi