#!/usr/bin/env bash

apt-get install -qq cachefilesd
echo "RUN=yes" > /etc/default/cachefilesd
sudo service cachefilesd restart