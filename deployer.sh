#!/bin/sh

echo "###############################################################"
echo "# Welcome to the apiman deployer.  Use this utility to deploy #"
echo "# a single apiman component onto a target system.             #"
echo "#                                                             #"
echo "# NOTE: this script deploys apiman version 1.1.6.Final        #"
echo "###############################################################"
echo ""
echo ""


echo "Currently supported components:"
echo "    1. Elasticsearch (for metrics)"
echo "    2. Keycloak Authentication Server"
echo "    3. apiman: API Manager"
echo "    4. apiman: API Gateway"
read -p "Which component would you like to deploy? " COMPONENT


if [ "x$COMPONENT" = "x1" ]
then
  echo "###############################################################"
  echo "# Installing Elasticsearch 1.7.1 for apiman...                #"
  echo "###############################################################"
  mkdir ~/apiman-elasticsearch
  cd ~/apiman-elasticsearch
  curl https://download.elastic.co/elasticsearch/elasticsearch/elasticsearch-1.7.1.zip -o elasticsearch-1.7.1.zip
  unzip elasticsearch-1.7.1.zip
  cd elasticsearch-1.7.1
  ./bin/plugin -i elasticsearch/marvel/latest
  echo 'marvel.agent.enabled: false' >> ./config/elasticsearch.yml
  sed -i "s/#cluster.name: elasticsearch/cluster.name: apiman/g" config/elasticsearch.yml

  echo "####################################################################"
  echo "# Installation complete. You can now start up Elasticsearch        #"
  echo "# with the following command:                                      #"
  echo "#                                                                  #"
  echo "#    ~/apiman-elasticsearch/elasticsearch-1.7.1/bin/elasticsearch  #"
  echo "#                                                                  #"
  echo "# or add the -d option to start Elasticsearch in the background.   #"
  echo "#                                                                  #"
  echo "# Please note: SSL and Authentication have *not* been enabled.     #"
  echo "# We recommend you enable these feature in elasticsearch if the    #"
  echo "# network between apiman and Elasticsearch is not secure.          #"
  echo "####################################################################"
  
fi

