#!/usr/bin/env bash

sudo mysql --version > /dev/null 2>&1
MYSQL_IS_INSTALLED=$?
if [[ $MYSQL_IS_INSTALLED -ne 0 ]]; then
    echo "!!! XHProf requires MySQL to be installed.";
    exit 1;
fi

# Check for nginx
sudo nginx -v > /dev/null 2>$1
NGING_IS_INSTALLED=$?
# Check for Apache
sudo apache2 -v > /dev/null 2>$1
APACHE_IS_INSTALLED=$?

# Test if PHP is installed
sudo php -v > /dev/null 2>&1
PHP_IS_INSTALLED=$?

if [[ $PHP_IS_INSTALLED -ne 0 ]]; then
    echo "!!! XHProf requires PHP to be installed";
    exit 1;
fi

public_folder="/usr/share/xhprof.io-gui"

echo ">>> Installing XHProf with xhprof.io GUI"
sudo apt-get install -qq graphviz php5-xhprof
if [ ! -d "$public_folder" ]; then
    sudo git clone https://github.com/gajus/xhprof.io.git $public_folder
fi

if [[ -z $3 ]]; then
    hostname=""
else
    hostname="$3"

    # Make a vhost for nginx
    if [[ $NGING_IS_INSTALLED -eq 0 ]]; then
        sudo ngxcb -d $public_folder -n $3 -s "$3.$1.xip.io $hostname" -e
    fi

    # MAke a vhost for Apache
    if [[ $APACHE_IS_INSTALLED -eq 0 ]]; then
        sudo vhost -s $3.$1.xip.io -d $public_folder -p /etc/ssl/xip.io -c xip.io -a $3
    fi

    cat > "$public_folder/xhprof/includes/config.inc.php" << EOF
<?php
return array(
        'url_base' => 'http://$hostname/',
        'url_static' => null, // When undefined, it defaults to $config['url_base'] . 'public/'. This should be absolute URL.
        'pdo' => new PDO('mysql:dbname=xhprof;host=localhost;charset=utf8', 'root', '$2'),
);
EOF
fi

cat > $(find /etc/php5 -name xhprof.ini) << EOF
extension=$(find /usr/lib/php5 -name xhprof.so)
xhprof.output_dir = "/var/tmp/xhprof"

auto_prepend_file = $public_folder/inc/prepend.php
auto_append_file = $public_folder/inc/append.php
EOF

sudo mysql -u root -p$2 << EOF
CREATE DATABASE IF NOT EXISTS xhprof;
EOF

sudo php5enmod xhprof
cat "$public_folder/setup/database.sql" | mysql -u root -p$2 xhprof

if [[ $NGING_IS_INSTALLED -eq 0 ]]; then
    sudo service nginx restart
fi

if [[ $APACHE_IS_INSTALLED -eq 0 ]]; then
    sudo service apache2 restart
fi

if [[ $PHP_IS_INSTALLED -eq 0 ]]; then
    sudo service php7.0-fpm restart
fi