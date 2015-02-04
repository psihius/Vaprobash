#!/bin/bash
apt-get install cachefilesd
echo "RUN=yes" > /etc/default/cachefilesd
service cachefilesd restart