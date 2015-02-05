#!/usr/bin/env bash

sudo mysql --version > /dev/null 2>&1
MYSQL_IS_INSTALLED=$?
if [[ $MYSQL_IS_INSTALLED -ne 0 ]]; then
    echo "!!! XHProf requires MySQL to be installed.";
    exit 1;
fi

public_folder="/usr/local/share/xhprof.io-gui"
if [[ -z $3 ]]; then
    hostname=""
else
    hostname=" $3"
    # Check for nginx
    sudo nginx -v > /dev/null 2>$1
    NGING_IS_INSTALLED=$?
    # Check for Apache
    sudo apache2 -v > /dev/null 2>$1
    APACHE_IS_INSTALLED=$?

    # Make a vhost for nginx
    if [[ $NGING_IS_INSTALLED -eq 0 ]]; then
        sudo ngxcb -d $public_folder -s "$1.xip.io$hostname" -e
    fi

    # MAke a vhost for Apache
    if [[ $APACHE_IS_INSTALLED -eq 0 ]]; then
        sudo vhost -s $1.xip.io -d $public_folder -p /etc/ssl/xip.io -c xip.io -a $hostname
    fi
fi
echo ">>> Installing XHProf with xhprof.io GUI"
sudo apt-get install -qq graphviz php5-xhprof
sudo git clone --quite https://github.com/gajus/xhprof.io.git $public_folder

cat > $(find /etc/php5 -name xhprof.ini) << EOF
extension=$(find /usr/lib/php5 -name xhprof.so)
xhprof.output_dir = "/var/tmp/xhprof"

auto_prepend_file = /usr/local/share/xhprof.io-gui/inc/prepend.php
auto_append_file = /usr/local/share/xhprof.io-gui/inc/append.php
EOF
sudo mysql -u root -p$1 << EOF
CREATE DATABASE IF NOT EXISTS xhprof;
EOF
sudo php5enmod xhprof
cat /usr/local/share/xhprof.io-gui/setup/database.sql | mysql -u root -p$1 xhprof
