#!/usr/bin/env bash

sudo apt-get install -qq cachefilesd
echo "RUN=yes" | sudo tee /etc/default/cachefilesd > /dev/null
sudo service cachefilesd restart