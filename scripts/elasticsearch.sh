#!/usr/bin/env bash

echo ">>> Installing Elasticsearch"

# Install prerequisite: Java and add Elastic repository
# -qq implies -y --force-yes
wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch | sudo apt-key add -
echo "deb https://artifacts.elastic.co/packages/6.x/apt stable main" | sudo tee -a /etc/apt/sources.list.d/elasticsearch.list
sudo apt-get update
sudo apt-get install -qq openjdk-8-jre-headless elasticsearch

# Configure Elasticsearch for development purposes (1 shard/no replicas, don't allow it to swap at all if it can run without swapping)
sudo sed -i "s/# index.number_of_shards: 1/index.number_of_shards: 1/" /etc/elasticsearch/elasticsearch.yml
sudo sed -i "s/# index.number_of_replicas: 0/index.number_of_replicas: 0/" /etc/elasticsearch/elasticsearch.yml
sudo sed -i "s/# bootstrap.mlockall: true/bootstrap.mlockall: true/" /etc/elasticsearch/elasticsearch.yml

# Configure to start up Elasticsearch automatically
sudo systemctl enable elasticsearch
sudo systemctl daemon-reload

# Start elastic
sudo systemctl start elasticsearch


