#!/bin/bash
echo ">>> Installing XHProf with xhprof.io GUI"
sudo apt-get install graphviz php5-xhprof
sudo git clone https://github.com/gajus/xhprof.io.git /usr/local/share/xhprof.io-gui
cat > $(find /etc/php5 -name xhprof.ini) << EOF
extension=$(find /usr/lib/php5 -name xhprof.so)
xhprof.output_dir = "/var/tmp/xhprof"

auto_prepend_file = /usr/local/share/xhprof.io-gui/inc/prepend.php
auto_append_file = /usr/local/share/xhprof.io-gui/inc/append.php
EOF
sudo mysql -u root -p$1 << EOF
CREATE DATABASE xhprof;
EOF
cat /usr/local/share/xhprof.io-gui/setup/database.sql | mysql -u root -p$1