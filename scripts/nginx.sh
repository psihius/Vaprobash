#!/usr/bin/env bash

# Test if PHP is installed
php -v > /dev/null 2>&1
PHP_IS_INSTALLED=$?

PHP_VERSION=$(ls -lah /etc/init.d/php*fpm | grep -oP 'php\K[[:digit:]]\.[[:digit:]]')

echo ">>> Installing Nginx"

[[ -z $1 ]] && { echo "!!! IP address not set. Check the Vagrant file."; exit 1; }

if [[ -z $2 ]]; then
    public_folder="/vagrant"
else
    public_folder="$2"
fi

if [[ -z $3 ]]; then
    hostname=""
else
    # There is a space, because this will be suffixed
    hostname=" $3"
fi

if [[ -z $4 ]]; then
    github_url="https://raw.githubusercontent.com/fideloper/Vaprobash/master"
else
    github_url="$4"
fi

# Install Nginx
# -qq implies -y --force-yes
sudo apt-get install -qq nginx

# Turn off sendfile to be more compatible with Windows, which can't use NFS
sed -i 's/sendfile on;/sendfile off;/' /etc/nginx/nginx.conf

# Set run-as user for PHP-FPM processes to user/group "vagrant"
# to avoid permission errors from apps writing to files
sed -i "s/user www-data;/user vagrant;/" /etc/nginx/nginx.conf
sed -i "s/# server_names_hash_bucket_size.*/server_names_hash_bucket_size 64;/" /etc/nginx/nginx.conf

# Add vagrant user to www-data group
usermod -a -G www-data vagrant

# Nginx enabling and disabling virtual hosts
curl --silent -L $github_url/helpers/ngxen.sh > ngxen
curl --silent -L $github_url/helpers/ngxdis.sh > ngxdis
curl --silent -L $github_url/helpers/ngxcb.sh > ngxcb
sudo chmod guo+x ngxen ngxdis ngxcb
sudo mv ngxen ngxdis ngxcb /usr/local/bin

# Create Nginx Server Block with same name as hostname
sudo ngxcb -n "$hostname" -d $public_folder -s "$1.xip.io$hostname $hostname" -e

# Disable "default"
sudo ngxdis default

if [[ $PHP_IS_INSTALLED -eq 0 ]]; then
    # PHP-FPM Config for Nginx
    sed -i "s/;cgi.fix_pathinfo=1/cgi.fix_pathinfo=0/" /etc/php/${PHP_VERSION}/fpm/php.ini

    sudo service php${PHP_VERSION}-fpm restart
fi

sudo systemctl enable nginx
sudo systemctl restart nginx
