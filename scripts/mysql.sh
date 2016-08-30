#!/usr/bin/env bash

echo ">>> Installing MySQL Server $2"

[[ -z "$1" ]] && { echo "!!! MySQL root password not set. Check the Vagrant file."; exit 1; }

mysql_package=mysql-server

# Install MySQL without password prompt
# Set username and password to 'root'
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password password $1"
sudo debconf-set-selections <<< "mysql-server mysql-server/root_password_again password $1"

# Install MySQL Server
# -qq implies -y --force-yes
sudo apt-get install -qq ${mysql_package}

# Make MySQL contactable from outside world without SSH tunnel
if [ $3 == "true" ]; then
    # enable remote access
    # setting the mysql bind-address to allow connections from everywhere
    sudo sed -i "s/bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf

    # adding grant privileges to mysql root user from everywhere
    # thx to http://stackoverflow.com/questions/7528967/how-to-grant-mysql-privileges-in-a-bash-script for this
    MYSQL=`which mysql`

    Q1="GRANT ALL ON *.* TO 'root'@'%' IDENTIFIED BY '$1' WITH GRANT OPTION;"
    Q2="FLUSH PRIVILEGES;"
    SQL="${Q1}${Q2}"
    ${MYSQL} -uroot -p$1 -e "$SQL"

    sudo service mysql restart
fi
