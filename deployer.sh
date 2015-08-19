#!/bin/sh

APIMAN_VERSION=1.1.6.Final

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
echo "    3. apiman: API Gateway"
echo "    4. apiman: API Manager"
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
  echo "    ~/apiman-elasticsearch/elasticsearch-1.7.1/bin/elasticsearch"
  echo "#                                                                  #"
  echo "# or add the -d option to start Elasticsearch in the background.   #"
  echo "#                                                                  #"
  echo "# Please note: SSL and Authentication have *not* been enabled.     #"
  echo "# We recommend you enable these feature in elasticsearch if the    #"
  echo "# network between apiman and Elasticsearch is not secure.          #"
  echo "####################################################################"
  
fi



if [ "x$COMPONENT" = "x2" ]
then
  echo "###############################################################"
  echo "# (Keycloak) NOT YET SUPPORTED :(                             #"
  echo "###############################################################"
fi



if [ "x$COMPONENT" = "x3" ]
then
  echo "###############################################################"
  echo "# Installing apiman : API Gateway...                          #"
  echo "###############################################################"
  mkdir ~/apiman-gateway-$APIMAN_VERSION
  cd ~/apiman-gateway-$APIMAN_VERSION
  curl http://downloads.jboss.org/wildfly/8.2.0.Final/wildfly-8.2.0.Final.zip -o wildfly-8.2.0.Final.zip
  curl http://downloads.jboss.org/apiman/1.1.6.Final/apiman-distro-wildfly8-1.1.6.Final-overlay.zip -o apiman-distro-wildfly8-1.1.6.Final-overlay.zip
  unzip wildfly-8.2.0.Final.zip
  unzip -o apiman-distro-wildfly8-1.1.6.Final-overlay.zip -d wildfly-8.2.0.Final
  cd wildfly-8.2.0.Final
  rm -f standalone/deployments/apiman-ds.xml
  rm -f standalone/deployments/apiman-es.war
  rm -f standalone/deployments/apiman.war
  rm -f standalone/deployments/apimanui.war
  sed -i "s/<enabled>true<\/enabled>/<enabled>false<\/enabled>/g" standalone/configuration/standalone-apiman.xml

  echo "####################################################################"
  echo "# Installation complete. You can now start up apiman : API Gateway #"
  echo "# with the following commands:                                     #"
  echo "#                                                                  #"
  echo "    cd ~/apiman-gateway-$APIMAN_VERSION/wildfly-8.2.0.Final"
  echo "    ./bin/standalone.sh -b 0.0.0.0 -c standalone-apiman.xml"
  echo "#                                                                  #"
  echo "####################################################################"

fi



if [ "x$COMPONENT" = "x4" ]
then
  echo "###############################################################"
  echo "# (apiman: API Manager) NOT YET SUPPORTED :(                  #"
  echo "###############################################################"
fi

