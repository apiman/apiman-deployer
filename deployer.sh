#!/bin/sh

APIMAN_VERSION=1.2.7-SNAPSHOT
ELASTIC_VERSION=1.7.2

echo "###############################################################"
echo "# Welcome to the apiman deployer.  Use this utility to deploy #"
echo "# a single apiman component onto a target system.             #"
echo "#                                                             #"
echo "# NOTE: this script deploys apiman version $APIMAN_VERSION        #"
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
  echo "# Installing Elasticsearch $ELASTIC_VERSION for apiman...                #"
  echo "###############################################################"
  mkdir ~/apiman-elasticsearch
  cd ~/apiman-elasticsearch
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
  echo "    ~/apiman-elasticsearch/elasticsearch-$ELASTIC_VERSION/bin/elasticsearch"
  echo "#                                                                  #"
  echo "# or add the -d option to start Elasticsearch in the background.   #"
  echo "#                                                                  #"
  echo "# Please note: SSL and Authentication have *not* been enabled.     #"
  echo "# We recommend you enable these feature in elasticsearch if the    #"
  echo "# network between apiman and Elasticsearch is not secure.          #"
  echo "####################################################################"
  echo ""
  echo "Next Steps:"
  echo "  -> Log in to the Keycloak admin console"
  echo "  -> Select the *apiman* realm"
  echo "  -> Click the *clients* left-nav item"
  echo "  -> Choose the *apimanui* client"
  echo "  -> Add the public URL of your API Manager UI as a valid redirect URL"
  echo ""
  echo "Enjoy apiman!"
  
fi



if [ "x$COMPONENT" = "x2" ]
then
  echo "###############################################################"
  echo "# Installing Keycloak for apiman...                           #"
  echo "###############################################################"
  echo ""
  mkdir ~/apiman-keycloak-$APIMAN_VERSION
  cd ~/apiman-keycloak-$APIMAN_VERSION
  curl http://downloads.jboss.org/wildfly/9.0.2.Final/wildfly-9.0.2.Final.zip -o wildfly-9.0.2.Final.zip
  curl http://downloads.jboss.org/apiman/$APIMAN_VERSION/apiman-distro-wildfly9-$APIMAN_VERSION-overlay.zip -o apiman-distro-wildfly9-$APIMAN_VERSION-overlay.zip
  unzip wildfly-9.0.2.Final.zip
  unzip -o apiman-distro-wildfly9-$APIMAN_VERSION-overlay.zip -d wildfly-9.0.2.Final
  cd wildfly-9.0.2.Final
  rm -f standalone/deployments/apiman*

  echo "####################################################################"
  echo "# Installation complete. You can now start up Keycloak for apiman  #"
  echo "# with the following commands:                                     #"
  echo "#                                                                  #"
  echo "    cd ~/apiman-keycloak-$APIMAN_VERSION/wildfly-9.0.2.Final"
  echo "    ./bin/standalone.sh -b 0.0.0.0 -c standalone-apiman.xml"
  echo "#                                                                  #"
  echo "####################################################################"
fi



if [ "x$COMPONENT" = "x3" ]
then
  echo "###############################################################"
  echo "# Installing apiman : API Gateway...                          #"
  echo "###############################################################"
  echo ""
  echo ""
  echo "You need to let us know the public endpoint for the API"
  echo "Gateway.  The public endpoint is the URL that an API client"
  echo "would use to connect to the API Gateway.  An example is:"
  echo "    https://gateway.acme.org/apiman-gateway/"
  echo ""
  read -p "Public Endpoint: " GATEWAY_PUBLIC_ENDPOINT
  if [ "x$GATEWAY_PUBLIC_ENDPOINT" = "x" ]
  then
    echo "Sorry, invalid endpoint!  Exiting..."
    exit 1
  fi
  echo ""
  echo ""
  echo "Now you need to tell us where your Keycloak authentication"
  echo "server is located.  This should be in the form of a URL."
  echo "An example might be:"
  echo "    https://keycloak.acme.org/auth"
  echo ""
  read -p "Keycloak URL: " KEYCLOAK_URL
  if [ "x$KEYCLOAK_URL" = "x" ]
  then
    echo "Sorry, invalid URL!  Exiting..."
    exit 1
  fi
  KEYCLOAK_URL_ESC="$(echo $KEYCLOAK_URL | sed 's/[\/]/\\\//g')"
  echo ""
  echo ""
  echo "Finally, please clue us in on the location of your Elasticsearch"
  echo "instance.  Please include the port - Elasticsearch typically"
  echo "listens on port 9200."
  echo "An example might be:"
  echo "    http://elastic.acme.org:9200"
  echo ""
  read -p "Elastic URL: " ELASTIC_URL
  if [ "x$ELASTIC_URL" = "x" ]
  then
    echo "Sorry, invalid URL!  Exiting..."
    exit 1
  fi
  ES_PROTOCOL=`echo $ELASTIC_URL | sed -r 's/(https?).*/\1/g'`
  ES_HOST=`echo $ELASTIC_URL | sed -r 's/https?:\/\/([^\:^\/]+)\:?[0-9]*\/?.*/\1/g'`
  ES_PORT=`echo $ELASTIC_URL | sed -r 's/https?\:\/\/[^\:]+\:?([0-9]+)?.*/\1/g'`
  echo ""
  echo "Thanks!  Will use the following elasticsearch info:"
  echo "---------------------------------------------------------"
  echo "  protocol: $ES_PROTOCOL"
  echo "      host: $ES_HOST"
  echo "      port: $ES_PORT"
  echo "---------------------------------------------------------"
  echo ""
  echo ""
  mkdir ~/apiman-gateway-$APIMAN_VERSION
  cd ~/apiman-gateway-$APIMAN_VERSION
  curl http://downloads.jboss.org/wildfly/9.0.2.Final/wildfly-9.0.2.Final.zip -o wildfly-9.0.2.Final.zip
  curl http://downloads.jboss.org/apiman/$APIMAN_VERSION/apiman-distro-wildfly9-$APIMAN_VERSION-overlay.zip -o apiman-distro-wildfly9-$APIMAN_VERSION-overlay.zip
  unzip wildfly-9.0.2.Final.zip
  unzip -o apiman-distro-wildfly9-$APIMAN_VERSION-overlay.zip -d wildfly-9.0.2.Final
  cd wildfly-9.0.2.Final
  rm -f standalone/deployments/apiman-ds.xml
  rm -f standalone/deployments/apiman-es.war
  rm -f standalone/deployments/apiman.war
  rm -f standalone/deployments/apimanui.war
  sed -i "s/<enabled>true<\/enabled>/<enabled>false<\/enabled>/g" standalone/configuration/standalone-apiman.xml
  sed -i "s/<kc\:auth-server-url>\/auth<\/kc\:auth-server-url>/<kc\:auth-server-url>$KEYCLOAK_URL_ESC<\/kc\:auth-server-url>/g" standalone/configuration/standalone-apiman.xml
  sed -i "s/apiman.es.protocol=.*$/apiman.es.protocol=$ES_PROTOCOL/g" standalone/configuration/apiman.properties
  sed -i "s/apiman.es.host=.*$/apiman.es.host=$ES_HOST/g" standalone/configuration/apiman.properties
  sed -i "s/apiman.es.port=.*$/apiman.es.port=$ES_PORT/g" standalone/configuration/apiman.properties
  sed -i "s/^apiman-manager/#apiman-manager/g" standalone/configuration/apiman.properties
  echo "" >> standalone/configuration/apiman.properties
  echo "# The public endpoint for accessing the API Gateway" >> standalone/configuration/apiman.properties
  echo "apiman-gateway.public-endpoint=$GATEWAY_PUBLIC_ENDPOINT" >> standalone/configuration/apiman.properties

  echo "####################################################################"
  echo "# Installation complete. You can now start up apiman : API Gateway #"
  echo "# with the following commands:                                     #"
  echo "#                                                                  #"
  echo "    cd ~/apiman-gateway-$APIMAN_VERSION/wildfly-9.0.2.Final"
  echo "    ./bin/standalone.sh -b 0.0.0.0 -c standalone-apiman.xml"
  echo "#                                                                  #"
  echo "####################################################################"

fi



if [ "x$COMPONENT" = "x4" ]
then
  echo "###############################################################"
  echo "# Installing apiman : API Manager...                          #"
  echo "###############################################################"
  echo ""
  echo ""
  echo "Now you need to tell us where your Keycloak authentication"
  echo "server is located.  This should be in the form of a URL."
  echo "An example might be:"
  echo "    https://keycloak.acme.org/auth"
  echo ""
  read -p "Keycloak URL: " KEYCLOAK_URL
  if [ "x$KEYCLOAK_URL" = "x" ]
  then
    echo "Sorry, invalid URL!  Exiting..."
    exit 1
  fi
  KEYCLOAK_URL_ESC="$(echo $KEYCLOAK_URL | sed 's/[\/]/\\\//g')"

  echo ""
  echo ""
  echo "We'll help you connect to your database.  Please provide us"
  echo "with the database connection information we'll need:"
  echo ""
  echo "Database Type:"
  echo "  1. mysql"
  echo "  2. postresql"
  read -p "Choose: " DATABASE_TYPE
  if [ "x$DATABASE_TYPE" = "x1" ]
  then
    echo "OK, mysql it is!"
  elif [ "x$DATABASE_TYPE" = "x2" ]
  then
    echo "OK, postgresql it is!"
  else
    echo "Sorry, invalid database type!  Exiting..."
    exit 1
  fi
  read -p "DB host/ip: " DATABASE_HOST
  read -p "DB port: " DATABASE_PORT
  read -p "DB username: " DATABASE_USER
  read -p "DB password: " -s DATABASE_PASSWORD
  echo ""
  read -p "      again: " -s DATABASE_PASSWORD_REPEAT
  
  if [ "x$DATABASE_PASSWORD" = "x$DATABASE_PASSWORD_REPEAT" ]
  then
    echo "OK great, thanks."
  else
    echo "Passwords don't match!  Exiting..."
    exit 1
  fi

  echo ""
  echo ""
  echo "Finally, please clue us in on the location of your Elasticsearch"
  echo "instance.  Please include the port - Elasticsearch typically"
  echo "listens on port 9200."
  echo "An example might be:"
  echo "    http://elastic.acme.org:9200"
  echo ""
  read -p "Elastic URL: " ELASTIC_URL
  if [ "x$ELASTIC_URL" = "x" ]
  then
    echo "Sorry, invalid URL!  Exiting..."
    exit 1
  fi
  ES_PROTOCOL=`echo $ELASTIC_URL | sed -r 's/(https?).*/\1/g'`
  ES_HOST=`echo $ELASTIC_URL | sed -r 's/https?:\/\/([^\:^\/]+)\:?[0-9]*\/?.*/\1/g'`
  ES_PORT=`echo $ELASTIC_URL | sed -r 's/https?\:\/\/[^\:]+\:?([0-9]+)?.*/\1/g'`
  echo ""
  echo "Thanks!  Will use the following elasticsearch info:"
  echo "---------------------------------------------------------"
  echo "  protocol: $ES_PROTOCOL"
  echo "      host: $ES_HOST"
  echo "      port: $ES_PORT"
  echo "---------------------------------------------------------"
  echo ""
  echo ""
  mkdir ~/apiman-manager-$APIMAN_VERSION
  cd ~/apiman-manager-$APIMAN_VERSION
  curl http://downloads.jboss.org/wildfly/9.0.2.Final/wildfly-9.0.2.Final.zip -o wildfly-9.0.2.Final.zip
  curl http://downloads.jboss.org/apiman/$APIMAN_VERSION/apiman-distro-wildfly9-$APIMAN_VERSION-overlay.zip -o apiman-distro-wildfly9-$APIMAN_VERSION-overlay.zip
  unzip wildfly-9.0.2.Final.zip
  unzip -o apiman-distro-wildfly9-$APIMAN_VERSION-overlay.zip -d wildfly-9.0.2.Final
  cd wildfly-9.0.2.Final
  rm -f standalone/deployments/apiman-es.war
  rm -f standalone/deployments/apiman-gateway-api.war
  rm -f standalone/deployments/apiman-gateway.war
  sed -i "s/<enabled>true<\/enabled>/<enabled>false<\/enabled>/g" standalone/configuration/standalone-apiman.xml
  sed -i "s/<kc\:auth-server-url>\/auth<\/kc\:auth-server-url>/<kc\:auth-server-url>$KEYCLOAK_URL_ESC<\/kc\:auth-server-url>/g" standalone/configuration/standalone-apiman.xml
  sed -i "s/apiman.es.protocol=.*$/apiman.es.protocol=$ES_PROTOCOL/g" standalone/configuration/apiman.properties
  sed -i "s/apiman.es.host=.*$/apiman.es.host=$ES_HOST/g" standalone/configuration/apiman.properties
  sed -i "s/apiman.es.port=.*$/apiman.es.port=$ES_PORT/g" standalone/configuration/apiman.properties
  sed -i "s/^apiman-gateway/#apiman-gateway/g" standalone/configuration/apiman.properties

  if [ "x$DATABASE_TYPE" = "x1" ]
  then
    HIBERNATE_DIALECT=org.hibernate.dialect.MySQL5Dialect
    curl https://repo1.maven.org/maven2/mysql/mysql-connector-java/5.1.33/mysql-connector-java-5.1.33.jar -o ~/apiman-manager-$APIMAN_VERSION/wildfly-9.0.2.Final/standalone/deployments/mysql-connector-java-5.1.33-bin.jar
    cp ~/apiman-manager-$APIMAN_VERSION/wildfly-9.0.2.Final/apiman/sample-configs/apiman-ds_mysql.xml ~/apiman-manager-$APIMAN_VERSION/wildfly-9.0.2.Final/standalone/deployments/apiman-ds.xml 
    sed -i "s/MYSQLSERVER/$DATABASE_HOST/g" ~/apiman-manager-$APIMAN_VERSION/wildfly-9.0.2.Final/standalone/deployments/apiman-ds.xml 
    sed -i "s/3306/$DATABASE_PORT/g" ~/apiman-manager-$APIMAN_VERSION/wildfly-9.0.2.Final/standalone/deployments/apiman-ds.xml 
  elif [ "x$DATABASE_TYPE" = "x2" ]
  then
    HIBERNATE_DIALECT=org.hibernate.dialect.PostgreSQLDialect
    curl https://repo1.maven.org/maven2/org/postgresql/postgresql/9.3-1102-jdbc41/postgresql-9.3-1102-jdbc41.jar -o ~/apiman-manager-$APIMAN_VERSION/wildfly-9.0.2.Final/standalone/deployments/postgresql-9.3-1102.jdbc41.jar
    cp ~/apiman-manager-$APIMAN_VERSION/wildfly-9.0.2.Final/apiman/sample-configs/apiman-ds_postgresql.xml ~/apiman-manager-$APIMAN_VERSION/wildfly-9.0.2.Final/standalone/deployments/apiman-ds.xml 
    sed -i "s/POSTGRESQLSERVER/$DATABASE_HOST/g" ~/apiman-manager-$APIMAN_VERSION/wildfly-9.0.2.Final/standalone/deployments/apiman-ds.xml 
    sed -i "s/5432/$DATABASE_PORT/g" ~/apiman-manager-$APIMAN_VERSION/wildfly-9.0.2.Final/standalone/deployments/apiman-ds.xml 
  fi
  sed -i "s/^apiman.hibernate.dialect=.*$/apiman.hibernate.dialect=$HIBERNATE_DIALECT/g" ~/apiman-manager-$APIMAN_VERSION/wildfly-9.0.2.Final/standalone/configuration/apiman.properties
  sed -i "s/DBUSER/$DATABASE_USER/g" ~/apiman-manager-$APIMAN_VERSION/wildfly-9.0.2.Final/standalone/deployments/apiman-ds.xml 
  sed -i "s/DBPASS/$DATABASE_PASSWORD/g" ~/apiman-manager-$APIMAN_VERSION/wildfly-9.0.2.Final/standalone/deployments/apiman-ds.xml 


  echo "####################################################################"
  echo "# Installation complete. You can now start up apiman : API Manager #"
  echo "# with the following commands:                                     #"
  echo "#                                                                  #"
  echo "    cd ~/apiman-manager-$APIMAN_VERSION/wildfly-9.0.2.Final"
  echo "    ./bin/standalone.sh -b 0.0.0.0 -c standalone-apiman.xml"
  echo "#                                                                  #"
  echo "####################################################################"
  echo ""
  echo "Next Steps:"
  echo "  -> Log in to the API Manager"
  echo "  -> Navigate to the Gateway Config page in the API Manager admin UI"
  echo "  -> Update the entry for The Gateway to point to your production"
  echo "     API Gateway instance"
  echo ""
  echo "Enjoy apiman!"
  
fi

