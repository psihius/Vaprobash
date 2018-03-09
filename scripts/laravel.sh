#!/usr/bin/env bash

echo ">>> Installing Laravel"

# Test if PHP is installed
php -v > /dev/null 2>&1
PHP_IS_INSTALLED=$?

[[ $PHP_IS_INSTALLED -ne 0 ]] && { printf "!!! PHP/HHVM is not installed.\n    Installing Laravel aborted!\n"; exit 0; }

# Test if Composer is installed
composer -v > /dev/null 2>&1 || { printf "!!! Composer is not installed.\n    Installing Laravel aborted!"; exit 0; }

# Test if Server IP is set in Vagrantfile
[[ -z "$1" ]] && { printf "!!! IP address not set. Check the Vagrantfile.\n    Installing Laravel aborted!\n"; exit 0; }

# Check if Laravel root is set. If not set use default
if [[ -z $2 ]]; then
    laravel_root_folder="/vagrant/laravel"
else
    laravel_root_folder="$2"
fi

laravel_public_folder="$laravel_root_folder/public"

# Test if Apache or Nginx is installed
nginx -v > /dev/null 2>&1
NGINX_IS_INSTALLED=$?

apache2 -v > /dev/null 2>&1
APACHE_IS_INSTALLED=$?

# Create Laravel folder if needed
if [[ ! -d $laravel_root_folder ]]; then
    mkdir -p $laravel_root_folder
fi

if [[ ! -f "$laravel_root_folder/composer.json" ]]; then
    # Create Laravel
    if [[ "$4" == 'latest-stable' ]]; then
        composer create-project --prefer-dist laravel/laravel $laravel_root_folder
    else
        composer create-project laravel/laravel:$4 $laravel_root_folder
    fi
else
    # Go to vagrant folder
    cd $laravel_root_folder

    composer install --prefer-dist

    # Go to the previous folder
    cd -
fi

if [[ $NGINX_IS_INSTALLED -eq 0 ]]; then
    # Change default vhost created
    sudo sed -i "s@root /vagrant@root $laravel_public_folder@" /etc/nginx/sites-available/vagrant
    sudo systemctl realod nginx
fi

if [[ $APACHE_IS_INSTALLED -eq 0 ]]; then
    # Find and replace to find public_folder and replace with laravel_public_folder
    # Change DocumentRoot
    # Change ProxyPassMatch fcgi path
    # Change <Directory ...> path
    sudo sed -i "s@$3@$laravel_public_folder@" /etc/apache2/sites-available/$1.xip.io.conf


    sudo systemctl reload apache2
fi
