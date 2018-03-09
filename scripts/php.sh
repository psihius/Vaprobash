#!/usr/bin/env bash

export LANG=C.UTF-8

PHP_TIMEZONE=$1
PHP_VERSION=$2

echo ">>> Installing PHP"

echo "Adding ppa:ondrej/php"
sudo add-apt-repository -y ppa:ondrej/php
sudo apt-get update

# Install PHP
# -qq implies -y --force-yes
sudo apt-get install -qq php${PHP_VERSION} php${PHP_VERSION}-cli php${PHP_VERSION}-fpm php${PHP_VERSION}-mysql \
 php${PHP_VERSION}-pgsql php${PHP_VERSION}-sqlite3 php${PHP_VERSION}-curl php${PHP_VERSION}-gd php${PHP_VERSION}-gmp \
 php${PHP_VERSION}-memcached php${PHP_VERSION}-imagick php${PHP_VERSION}-intl php${PHP_VERSION}-xdebug \
 php${PHP_VERSION}-apcu php${PHP_VERSION}-mbstring

# We disable the mod by default because composer performance is impacted hard. Enable it in local-provisioning.sh if needed
sudo phpdismod xdebug

# Logging is not added by default, so let's add it
if [ ! -d /var/log/php ];
then
    sudo mkdir /var/log/php
fi

sudo touch /var/log/php/error_fpm.log
sudo touch /var/log/php/error_cli.log
sudo chown -R vagrant:adm /var/log/php

sudo sed -i "s,;error_log = .*,error_log = /var/log/php/error_fpm.log," /etc/php/${PHP_VERSION}/fpm/php.ini
sudo sed -i "s,;error_log = .*,error_log = /var/log/php/error_cli.log," /etc/php/${PHP_VERSION}/cli/php.ini

# Set PHP FPM to listen on TCP instead of Socket
sudo sed -i "s,listen =.*,listen = /var/run/php/php${PHP_VERSION}-fpm.sock," /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf

# Set PHP FPM allowed clients IP address
sudo sed -i "s/;listen.allowed_clients/listen.allowed_clients/" /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf

# Set run-as user for PHP-FPM processes to user/group "vagrant"
# to avoid permission errors from apps writing to files
sudo sed -i "s/user = www-data/user = vagrant/" /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf
sudo sed -i "s/group = www-data/group = www-data/" /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf

sudo sed -i "s/listen\.owner.*/listen.owner = vagrant/" /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf
sudo sed -i "s/listen\.group.*/listen.group = www-data/" /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf
sudo sed -i "s/listen\.mode.*/listen.mode = 0666/" /etc/php/${PHP_VERSION}/fpm/pool.d/www.conf


# xdebug Config
cat > sudo $(sudo find /etc/php/${PHP_VERSION}/ -name xdebug.ini) << EOF
zend_extension=$(find /usr/lib/ -name xdebug.so)
xdebug.remote_enable = 1
xdebug.remote_connect_back = 1
xdebug.remote_port = 9000
xdebug.scream=0
xdebug.cli_color=1
xdebug.show_local_vars=1

; var_dump display
xdebug.var_display_max_depth = 5
xdebug.var_display_max_children = 256
xdebug.var_display_max_data = 1024
EOF

# APCu Config
cat > sudo $(sudo find /etc/php/${PHP_VERSION}/ -name apcu.ini) << EOF
extension=apcu.so
apc.enabled=1
apc.shm_size=128M
apc.ttl=7200
apc.gc_ttl=3600
apc.enable_cli=0
EOF

# OPCache Config
cat > sudo $(sudo find /etc/php/${PHP_VERSION}/ -name opcache.ini) << EOF
zend_extension=opcache.so
opcache.revalidate_freq=0
;opcache.validate_timestamps=0
opcache.max_accelerated_files=30000
opcache.memory_consumption=192
opcache.interned_strings_buffer=16
opcache.fast_shutdown=1
EOF

# PHP Error Reporting Config
sudo sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php/${PHP_VERSION}/fpm/php.ini
sudo sed -i "s/display_errors = .*/display_errors = On/" /etc/php/${PHP_VERSION}/fpm/php.ini

# PHP Date Timezone
sudo sed -i "s/;date.timezone =.*/date.timezone = ${PHP_TIMEZONE/\//\\/}/" /etc/php/${PHP_VERSION}/fpm/php.ini
sudo sed -i "s/;date.timezone =.*/date.timezone = ${PHP_TIMEZONE/\//\\/}/" /etc/php/${PHP_VERSION}/cli/php.ini

# Increase realpath cache - Symfony based projects benefit especially
sudo sed -i "s/;realpath_cache_size =.*/realpath_cache_size = 4096k/" /etc/php/${PHP_VERSION}/fpm/php.ini
sudo sed -i "s/;realpath_cache_ttl =.*/realpath_cache_ttl = 600/" /etc/php/${PHP_VERSION}/fpm/php.ini

sudo systemctl enable php${PHP_VERSION}-fpm
sudo systemctl restart php${PHP_VERSION}-fpm
