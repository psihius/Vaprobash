#!/usr/bin/env bash

export LANG=C.UTF-8

PHP_TIMEZONE=$1
HHVM=$2

if [[ $HHVM == "true" ]]; then

    echo ">>> Installing HHVM"

    # Get key and add to sources
    wget --quiet -O - http://dl.hhvm.com/conf/hhvm.gpg.key | sudo apt-key add -
    echo deb http://dl.hhvm.com/ubuntu trusty main | sudo tee /etc/apt/sources.list.d/hhvm.list

    # Update
    sudo apt-get update

    # Install HHVM
    # -qq implies -y --force-yes
    sudo apt-get install -qq hhvm

    # Start on system boot
    sudo update-rc.d hhvm defaults

    # Replace PHP with HHVM via symlinking
    sudo /usr/bin/update-alternatives --install /usr/bin/php php /usr/bin/hhvm 60

    sudo service hhvm restart
else
     echo ">>> Installing PHP"

    # Install PHP
    # -qq implies -y --force-yes
    sudo apt-get install -qq php-cli php-fpm php-mysql php-pgsql php-sqlite3 php-curl php-gd php-gmp php-memcached php-imagick php-intl php-xdebug php-apcu

    # We disable the mod by default because composer performance is impacted hard. Enable it in local-provisioning.sh if needed
    sudo phpdismod xdebug

    # Logging is not added by default, so let's add it
    sudo mkdir /var/log/php
    touch /var/log/php/error_fpm.log
    touch /var/log/php/error_cli.log
    chown -R vagrant:adm /var/log/php
    sudo sed -i "s,;error_log = .*,error_log = /var/log/php/error_fpm.log," /etc/php/7.0/fpm/php.ini
    sudo sed -i "s,;error_log = .*,error_log = /var/log/php/error_cli.log," /etc/php/7.0/cli/php.ini

    # Set PHP FPM to listen on TCP instead of Socket
    sudo sed -i "s/listen =.*/listen = unix:/var/run/php/php7.0-fpm.sock/" /etc/php/7.0/fpm/pool.d/www.conf

    # Set PHP FPM allowed clients IP address
    sudo sed -i "s/;listen.allowed_clients/listen.allowed_clients/" /etc/php/7.0/fpm/pool.d/www.conf

    # Set run-as user for PHP5-FPM processes to user/group "vagrant"
    # to avoid permission errors from apps writing to files
    sudo sed -i "s/user = www-data/user = vagrant/" /etc/php/7.0/fpm/pool.d/www.conf
    sudo sed -i "s/group = www-data/group = www-data/" /etc/php/7.0/fpm/pool.d/www.conf

    sudo sed -i "s/listen\.owner.*/listen.owner = vagrant/" /etc/php/7.0/fpm/pool.d/www.conf
    sudo sed -i "s/listen\.group.*/listen.group = vagrant/" /etc/php/7.0/fpm/pool.d/www.conf
    sudo sed -i "s/listen\.mode.*/listen.mode = 0666/" /etc/php/7.0/fpm/pool.d/www.conf


    # xdebug Config
    cat > $(find /etc/php -name xdebug.ini) << EOF
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
    cat > $(find /etc/php -name apcu.ini) << EOF
extension=apcu.so
apc.enabled=1
apc.shm_size=128M
apc.ttl=7200
apc.gc_ttl=3600
apc.enable_cli=0
EOF

    # OPCache Config
    cat > $(find /etc/php -name opcache.ini) << EOF
zend_extension=opcache.so
opcache.revalidate_freq=0
;opcache.validate_timestamps=0
opcache.max_accelerated_files=30000
opcache.memory_consumption=192
opcache.interned_strings_buffer=16
opcache.fast_shutdown=1
EOF

    # PHP Error Reporting Config
    sudo sed -i "s/error_reporting = .*/error_reporting = E_ALL/" /etc/php/7.0/fpm/php.ini
    sudo sed -i "s/display_errors = .*/display_errors = On/" /etc/php/7.0/fpm/php.ini

    # PHP Date Timezone
    sudo sed -i "s/;date.timezone =.*/date.timezone = ${PHP_TIMEZONE/\//\\/}/" /etc/php/7.0/fpm/php.ini
    sudo sed -i "s/;date.timezone =.*/date.timezone = ${PHP_TIMEZONE/\//\\/}/" /etc/php/7.0/cli/php.ini

    # Increase realpath cache - Symfony based projects benefit especially
    sudo sed -i "s/;realpath_cache_size =.*/realpath_cache_size = 4096k/" /etc/php/7.0/fpm/php.ini
    sudo sed -i "s/;realpath_cache_ttl =.*/realpath_cache_ttl = 600/" /etc/php/7.0/fpm/php.ini

    sudo service php7.0-fpm restart
fi
