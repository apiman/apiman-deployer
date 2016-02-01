#!/bin/sh

#
# Instructions to install locally Apiman Manager and Gateway, ElasticSearch and Keycloak Server
#

#
# Set versions of Apiman & ElasticSearch, wildfly and directory to install the components
#
read -p "Directory to install the components (default: home directory): " INSTALL_DIRECTORY
INSTALL_DIRECTORY=${INSTALL_DIRECTORY:-~}
echo "Components will be installed here : $INSTALL_DIRECTORY"


read -p "Please enter the version of Apiman to be installed (default: 1.2.1): " APIMAN_VERSION
APIMAN_VERSION=${APIMAN_VERSION:-1.2.1}
echo $APIMAN_VERSION

read -p "Please enter the version of ElasticSearch to be installed (default: 1.7.2): " ELASTIC_VERSION
ELASTIC_VERSION=${ELASTIC_VERSION:-1.7.2}
echo $ELASTIC_VERSION

read -p "Version of WildFly (default: 9.0.2.Final):" WILDFLY_VERSION
WILDFLY_VERSION=${WILDFLY_VERSION:-9.0.2.Final}
echo $WILDFLY_VERSION
echo ""
echo "Next steps ..."

COMPONENT=""

while [[ "$COMPONENT" != "5" ]]; do

echo "###############################################################"
echo "# Welcome to the apiman deployer.  Use this utility to deploy #"
echo "# a single apiman component onto a local system.              #"
echo "# The utility will loop until you select EXIT.				#"
echo "#                                                             #"
echo "# NOTE: this script deploys apiman version $APIMAN_VERSION    #"
echo "###############################################################"
echo ""
echo ""
echo "Currently supported components:"
echo "    1. Elasticsearch (for metrics)"
echo "    2. Keycloak Authentication Server"
echo "    3. apiman: API Gateway"
echo "    4. apiman: API Manager"
echo "    5. Exit"
read -p "Which component would you like to deploy? " COMPONENT


if [ "$COMPONENT" = "1" ]
then
	  echo "###############################################################"
	  echo "# Installing Elasticsearch $ELASTIC_VERSION for apiman...  top of WildFly $WILDFY_VERSION #"
	  echo "###############################################################"
	  rm -rf $INSTALL_DIRECTORY/apiman-elasticsearch 
	  mkdir $INSTALL_DIRECTORY/apiman-elasticsearch
	  cd $INSTALL_DIRECTORY/apiman-elasticsearch
	  curl https://download.elastic.co/elasticsearch/elasticsearch/elasticsearch-$ELASTIC_VERSION.zip -o elasticsearch-$ELASTIC_VERSION.zip
	  unzip elasticsearch-$ELASTIC_VERSION.zip
	  cd elasticsearch-$ELASTIC_VERSION
	  ./bin/plugin -i elasticsearch/marvel/latest
	  echo 'marvel.agent.enabled: false' >> ./config/elasticsearch.yml
	  sed -i "s/#cluster.name: elasticsearch/cluster.name: apiman/g" config/elasticsearch.yml

	  echo "####################################################################"
	  echo "# Installation complete. You can now start up Elasticsearch        #"
	  echo "# with the following command:                                      #"
	  echo "#                                                                  #"
	  echo "    $INSTALL_DIRECTORY/apiman-elasticsearch/elasticsearch-$ELASTIC_VERSION/bin/elasticsearch"
	  echo "#                                                                  #"
	  echo "# or add the -d option to start Elasticsearch in the background.   #"
	  echo "#                                                                  #"
	  echo "# Please note: SSL and Authentication have *not* been enabled.     #"
	  echo "# We recommend you enable these feature in elasticsearch if the    #"
	  echo "# network between apiman and Elasticsearch is not secure.          #"
	  echo "####################################################################"
	  echo ""
	fi


	if [ "$COMPONENT" = "4" ]
	then

		#
		# Step 1. Download and install Apiman
		#
		rm -rf $INSTALL_DIRECTORY/apiman-manager-$APIMAN_VERSION
		mkdir $INSTALL_DIRECTORY/apiman-manager-$APIMAN_VERSION
	    cd $INSTALL_DIRECTORY/apiman-manager-$APIMAN_VERSION
	    curl http://downloads.jboss.org/wildfly/${WILDFLY_VERSION}/wildfly-${WILDFLY_VERSION}.zip -o wildfly-${WILDFLY_VERSION}.zip
	    curl http://downloads.jboss.org/apiman/$APIMAN_VERSION/apiman-distro-wildfly9-$APIMAN_VERSION-overlay.zip -o apiman-distro-wildfly9-$APIMAN_VERSION-overlay.zip
	    unzip wildfly-${WILDFLY_VERSION}.zip
	    unzip -o apiman-distro-wildfly9-$APIMAN_VERSION-overlay.zip -d wildfly-${WILDFLY_VERSION}
	    cd wildfly-${WILDFLY_VERSION}


		#
		# Step 2. Remove the gateway war files
		#

		rm standalone/deployments/apiman-es.war
		rm standalone/deployments/apiman-gateway-api.war
		rm standalone/deployments/apiman-gateway.war

	    echo "####################################################################"
	    echo "# Installation complete. You can now start up apiman : API Manager #"
	    echo "# with the following commands:                                     #"
	    echo "#                                                                  #"
	    echo "    cd $INSTALL_DIRECTORY/apiman-manager-$APIMAN_VERSION/wildfly-${WILDFLY_VERSION}"
	    echo "    ./bin/standalone.sh -b 0.0.0.0 -c standalone-apiman.xml"
	    echo "#                                                                  #"
	    echo "####################################################################"

	fi

done

