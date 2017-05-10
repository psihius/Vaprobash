#!/usr/bin/env bash

# Test if PHP is installed
php -v > /dev/null 2>&1
PHP_IS_INSTALLED=$?

# Test if HHVM is installed
hhvm --version > /dev/null 2>&1
HHVM_IS_INSTALLED=$?

# If HHVM is installed, assume PHP is *not*
[[ $HHVM_IS_INSTALLED -eq 0 ]] && { PHP_IS_INSTALLED=-1; }

echo ">>> Installing Apache Server"

[[ -z $1 ]] && { echo "!!! IP address not set. Check the Vagrant file."; exit 1; }

server_ip="$1"

if [[ -z $2 ]]; then
    public_folder="/vagrant"
else
    public_folder="$2"
fi

if [[ -z $3 ]]; then
    alias="$1"
else
    alias="$3"
fi

if [[ -z $4 ]]; then
    github_url="https://raw.githubusercontent.com/psihius/Vaprobash/master"
else
    github_url="$4"
fi

PHP_VERSION=$(ls -lah /etc/init.d/php*fpm | grep -oP 'php\K[[:digit:]]\.[[:digit:]]')

# Install Apache
# -qq implies -y --force-yes
sudo apt-get install -qq apache2

echo ">>> Configuring Apache"

# Add vagrant user to www-data group
sudo usermod -a -G www-data vagrant

# Apache Config
# On separate lines since some may cause an error
# if not installed
sudo a2dismod mpm_prefork php{$PHP_VERSION} mpm_prefork
sudo a2enmod mpm_worker rewrite actions ssl
curl --silent -L $github_url/helpers/vhost.sh > vhost
sudo chmod guo+x vhost
sudo mv vhost /usr/local/bin

# Create a virtualhost to start, with SSL certificate
sudo vhost -s $server_ip.xip.io -d $public_folder -p /etc/ssl/xip.io -c xip.io -a $alias
sudo a2dissite 000-default

# If PHP is installed or HHVM is installed, proxy PHP requests to it
if [[ $PHP_IS_INSTALLED -eq 0 || $HHVM_IS_INSTALLED -eq 0 ]]; then

    # PHP Config for Apache
    sudo a2enmod proxy_fcgi
else
    # vHost script assumes ProxyPassMatch to PHP
    # If PHP is not installed, we'll comment it out
    sudo sed -i "s@ProxyPassMatch@#ProxyPassMatch@" /etc/apache2/sites-available/$1.xip.io.conf
fi

sudo service apache2 restart
