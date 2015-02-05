#!/usr/bin/env bash

apt-get install -qq cachefilesd
echo "RUN=yes" > /etc/default/cachefilesd
service cachefilesd restart