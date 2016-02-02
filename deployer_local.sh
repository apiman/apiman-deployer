#!/bin/sh

#
# Instructions to install locally Apiman Manager, Apiman Gateway, ElasticSearch and Keycloak Server
#

#
# Set versions of Apiman & ElasticSearch, wildfly and directory to install the components
#
read -p "Directory to install the components (default: home directory): " INSTALL_DIRECTORY
INSTALL_DIRECTORY=${INSTALL_DIRECTORY:-~}
echo "Components will be installed here : $INSTALL_DIRECTORY"

read -p "Please enter the version of Apiman to be installed (default: 1.2.1): " APIMAN_VERSION
APIMAN_VERSION=${APIMAN_VERSION:-1.2.1.Final}
echo $APIMAN_VERSION

read -p "Please enter the version of ElasticSearch to be installed (default: 1.7.2): " ELASTIC_VERSION
ELASTIC_VERSION=${ELASTIC_VERSION:-1.7.2}
echo $ELASTIC_VERSION

read -p "Version of WildFly (default: 9.0.2.Final):" WILDFLY_VERSION
WILDFLY_VERSION=${WILDFLY_VERSION:-9.0.2.Final}
echo $WILDFLY_VERSION
echo ""
echo "Next steps ..."

unamestr=`uname`

COMPONENT=""

while [[ "$COMPONENT" != "5" ]]; do

	echo "###############################################################"
	echo "# Welcome to the apiman deployer.  Use this utility to deploy #"
	echo "# a single apiman component onto a local system.              #"
	echo "# The utility will loop until you select EXIT.                #"
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
		echo "# Installing Elasticsearch $ELASTIC_VERSION for apiman...     #"
		echo "###############################################################"
		if [ -d "$INSTALL_DIRECTORY/apiman-elasticsearch-$ELASTIC_VERSION" ]; then
		  rm -rf $INSTALL_DIRECTORY/apiman-elasticsearch-$ELASTIC_VERSION
		fi
		mkdir -p $INSTALL_DIRECTORY/apiman-elasticsearch-$ELASTIC_VERSION
		cd $INSTALL_DIRECTORY/apiman-elasticsearch-$ELASTIC_VERSION
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
		echo "    $INSTALL_DIRECTORY/apiman-elasticsearch-$ELASTIC_VERSION/elasticsearch-$ELASTIC_VERSION/bin/elasticsearch"
		echo "#                                                                  #"
		echo "# or add the -d option to start Elasticsearch in the background.   #"
		echo "#                                                                  #"
		echo "# Please note: SSL and Authentication have *not* been enabled.     #"
		echo "# We recommend you enable these feature in elasticsearch if the    #"
		echo "# network between apiman and Elasticsearch is not secure.          #"
		echo "####################################################################"
		echo ""
	fi

	if [ "x$COMPONENT" = "x2" ]
    then
      echo "###############################################################"
      echo "# Installing Keycloak for apiman...                           #"
      echo "###############################################################"
      echo ""
      if [ -d "$INSTALL_DIRECTORY/apiman-keycloak-$APIMAN_VERSION" ]; then
		  rm -rf rm -rf $INSTALL_DIRECTORY/apiman-keycloak-$APIMAN_VERSION
	  fi
      mkdir -p $INSTALL_DIRECTORY/apiman-keycloak-$APIMAN_VERSION
      cd $INSTALL_DIRECTORY/apiman-keycloak-$APIMAN_VERSION
      curl http://downloads.jboss.org/wildfly/${WILDFLY_VERSION}/wildfly-${WILDFLY_VERSION}.zip -o wildfly-${WILDFLY_VERSION}.zip
      curl http://downloads.jboss.org/apiman/$APIMAN_VERSION/apiman-distro-wildfly9-$APIMAN_VERSION-overlay.zip -o apiman-distro-wildfly9-$APIMAN_VERSION-overlay.zip
      unzip wildfly-${WILDFLY_VERSION}.zip
      unzip -o apiman-distro-wildfly9-$APIMAN_VERSION-overlay.zip -d wildfly-${WILDFLY_VERSION}
      cd wildfly-${WILDFLY_VERSION}
      rm -f standalone/deployments/apiman*

      #
      # Change the binding port offset to avoid conflicts
	  #
	  # Apiman Manager offset: 0 (-> 8080, 8443)
	  # Apiman Gateway offset: 100 (-> 8180, 8543)
	  # Apiman Keycloak Server offset: 200 (-> 8280, 8643)
	  #
      if [[ "$unamestr" == 'Linux' ]]; then
        sed -i "s/jboss.socket.binding.port-offset:0/jboss.socket.binding.port-offset:200/g" standalone/configuration/standalone-apiman.xml
      elif [[ "$unamestr" == 'Darwin' ]]; then
        sed -i '' "s/jboss.socket.binding.port-offset:0/jboss.socket.binding.port-offset:200/g" standalone/configuration/standalone-apiman.xml
      fi

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

	  #
      # Step 0: Configure Gateway Public Endpoint
	  #
      echo "You need to let us know the public endpoint for the API"
      echo "Gateway.  The public endpoint is the URL that an API client"
      echo "would use to connect to the API Gateway.  An example is:"
      echo "    https://localhost:8543/apiman-gateway/"
      echo ""
      read -p "Public Endpoint (default: https://localhost:8543/apiman-gateway/) : " GATEWAY_PUBLIC_ENDPOINT
      GATEWAY_PUBLIC_ENDPOINT=${GATEWAY_PUBLIC_ENDPOINT:-https://localhost:8543/apiman-gateway}

      #
      # Step 1: Setup URL to access Keycloak Security Server (by default it runs inside the Apiman Manager - https://localhostg:8443/auth)
	  #
      echo ""
      echo ""
      echo "Now you need to tell us where your Keycloak authentication"
      echo "server is located.  This should be in the form of a URL."
      echo "An example might be:"
      echo "    https://localhost:8443/auth"
      echo ""
	  read -p "Keycloak URL (default https://localhost:8443/auth for local usage): " KEYCLOAK_URL
	  KEYCLOAK_URL=${KEYCLOAK_URL:-https://localhost:8443/auth}
	  KEYCLOAK_URL_ESC="$(echo $KEYCLOAK_URL | sed 's/[\/]/\\\//g')"

	  echo "Keycloak URL : $KEYCLOAK_URL; escaped : $KEYCLOAK_URL_ESC"

      #
      # Step 2: Setup URL to access ElasticSearch Server - https://localhost:9200/
	  #
	  echo ""
	  echo ""
	  echo "Finally, please clue us in on the location of your Elasticsearch"
	  echo "instance.  Please include the port - Elasticsearch typically"
	  echo "listens on port 9200."
	  echo "An example might be:"
	  echo "    http://localhost:9200"
	  echo ""
	  read -p "Elastic URL (default: http://localhost:9200): " ELASTIC_URL
	  ELASTIC_URL=${ELASTIC_URL:-http://localhost:9200}

      if [[ "$unamestr" == 'Linux' ]]; then
        ES_PROTOCOL=`echo $ELASTIC_URL | sed -r 's/(https?).*/\1/g'`
        ES_HOST=`echo $ELASTIC_URL | sed -r 's/https?:\/\/([^\:^\/]+)\:?[0-9]*\/?.*/\1/g'`
        ES_PORT=`echo $ELASTIC_URL | sed -r 's/https?\:\/\/[^\:]+\:?([0-9]+)?.*/\1/g'`
      elif [[ "$unamestr" == 'Darwin' ]]; then
        ES_PROTOCOL=`echo $ELASTIC_URL | sed -E 's/(https?).*/\1/g'`
        ES_HOST=`echo $ELASTIC_URL | sed -E 's/https?:\/\/([^\:^\/]+)\:?[0-9]*\/?.*/\1/g'`
        ES_PORT=`echo $ELASTIC_URL | sed -E 's/https?\:\/\/[^\:]+\:?([0-9]+)?.*/\1/g'`
      fi

      echo ""
      echo "Thanks!  Will use the following elasticsearch info:"
      echo "---------------------------------------------------------"
      echo "  protocol: $ES_PROTOCOL"
      echo "      host: $ES_HOST"
      echo "      port: $ES_PORT"
      echo "---------------------------------------------------------"
      echo ""
      echo ""

      #
      # Step 3: Download and unzip Wildfly, Apiman
	  #
      if [ -d "$INSTALL_DIRECTORY/apiman-gateway-$APIMAN_VERSION" ]; then
		  rm -rf $INSTALL_DIRECTORY/apiman-gateway-$APIMAN_VERSION
	  fi
      mkdir $INSTALL_DIRECTORY/apiman-gateway-$APIMAN_VERSION
      cd $INSTALL_DIRECTORY/apiman-gateway-$APIMAN_VERSION
      curl http://downloads.jboss.org/wildfly/${WILDFLY_VERSION}/wildfly-${WILDFLY_VERSION}.zip -o wildfly-${WILDFLY_VERSION}.zip
      curl http://downloads.jboss.org/apiman/$APIMAN_VERSION/apiman-distro-wildfly9-$APIMAN_VERSION-overlay.zip -o apiman-distro-wildfly9-$APIMAN_VERSION-overlay.zip
      unzip wildfly-${WILDFLY_VERSION}.zip
      unzip -o apiman-distro-wildfly9-$APIMAN_VERSION-overlay.zip -d wildfly-${WILDFLY_VERSION}
      cd wildfly-${WILDFLY_VERSION}

      #
      # Step 4: Remove WAR files not required
	  #
      rm -f standalone/deployments/apiman-ds.xml
      rm -f standalone/deployments/apiman-es.war
      rm -f standalone/deployments/apiman.war
      rm -f standalone/deployments/apimanui.war

      #
      # Step 5. Disabling the keycloak Server as we will use an external
      #
      # <subsystem xmlns="urn:jboss:domain:keycloak-server:1.1">
      #     <web-context>auth</web-context>
      # </subsystem>
      if [[ "$unamestr" == 'Linux' ]]; then
        sed -i "s/<kc\:auth-server-url>\/auth<\/kc\:auth-server-url>/<kc\:auth-server-url>$KEYCLOAK_URL_ESC<\/kc\:auth-server-url>/g" standalone/configuration/standalone-apiman.xml
      elif [[ "$unamestr" == 'Darwin' ]]; then
        sed -i '' "s/\(<auth-server-url>\).*\(<\/auth-server-url\)/\1$KEYCLOAK_URL_ESC\2/" standalone/configuration/standalone-apiman.xml
      fi

      #
      # Step 6. Configure External ElasticSearch Server
      #
      sed -i '' "s/apiman.es.protocol=.*$/apiman.es.protocol=$ES_PROTOCOL/g" standalone/configuration/apiman.properties
      sed -i '' "s/apiman.es.host=.*$/apiman.es.host=$ES_HOST/g" standalone/configuration/apiman.properties
      sed -i '' "s/apiman.es.port=.*$/apiman.es.port=$ES_PORT/g" standalone/configuration/apiman.properties

      #
      # Step 7. Comment the apiman-manager parameters
      #
	  if [[ "$unamestr" == 'Linux' ]]; then
 	    sed -i "s/^apiman-manager/#apiman-manager/g" standalone/configuration/apiman.properties
      elif [[ "$unamestr" == 'Darwin' ]]; then
        sed -i '' "s/^apiman-manager/#apiman-manager/g" standalone/configuration/apiman.properties
      fi

      #
      # Step 8. Add the public endpoint of the gateway
      #
      echo "" >> standalone/configuration/apiman.properties
      echo "# The public endpoint for accessing the API Gateway" >> standalone/configuration/apiman.properties
      echo "apiman-gateway.public-endpoint=$GATEWAY_PUBLIC_ENDPOINT" >> standalone/configuration/apiman.properties

      #
      # Step 9: Change the binding port offset to avoid conflicts
	  #
	  # Apiman Manager offset: 0 (-> 8080, 8443)
	  # Apiman Gateway offset: 100 (-> 8180, 8543)
   	  # Apiman Keycloak Server offset: 200 (-> 8280, 8643)
	  #
      if [[ "$unamestr" == 'Linux' ]]; then
        sed -i "s/jboss.socket.binding.port-offset:0/jboss.socket.binding.port-offset:100/g" standalone/configuration/standalone-apiman.xml
      elif [[ "$unamestr" == 'Darwin' ]]; then
        sed -i '' "s/jboss.socket.binding.port-offset:0/jboss.socket.binding.port-offset:100/g" standalone/configuration/standalone-apiman.xml
      fi

      echo "####################################################################"
      echo "# Installation complete. You can now start up apiman : API Gateway #"
      echo "# with the following commands:                                     #"
      echo "#                                                                  #"
      echo "    cd ~/apiman-gateway-$APIMAN_VERSION/wildfly-9.0.2.Final"
      echo "    ./bin/standalone.sh -b 0.0.0.0 -c standalone-apiman.xml"
      echo "#                                                                  #"
      echo "####################################################################"

    fi


	if [ "$COMPONENT" = "4" ]
	then

		# 
		# Step 0: Configure URL of Keycloak
		#
		echo "###############################################################"
		echo "# Installing apiman : API Manager...                          #"
		echo "###############################################################"
		echo ""
		echo ""
		echo "Now you need to tell us where your Keycloak authentication"
		echo "server is located.  This should be in the form of a URL."
		echo "An example might be:"
		echo "    https://localhost:8443/auth"
		echo ""
		read -p "Keycloak URL (default https://localhost:8443/auth for local usage): " KEYCLOAK_URL
		KEYCLOAK_URL=${KEYCLOAK_URL:-https://localhost:8443/auth}
		KEYCLOAK_URL_ESC="$(echo $KEYCLOAK_URL | sed 's/[\/]/\\\//g')"
		echo "Keycloak URL : $KEYCLOAK_URL; escaped : $KEYCLOAK_URL_ESC"

		# 
		# Step 1 : Configure Database (h2, MySQL, PostGresQL)
		#
		echo ""
		echo ""
		echo "We'll help you connect to your database.  Please provide us"
		echo "with the database connection information we'll need:"
		echo ""
		echo "Database Type:"
		echo "  1. mysql"
		echo "  2. postresql"
		echo "  3. h2 (default)"
		read -p "Choose: " DATABASE_TYPE
	    DATABASE_TYPE=${DATABASE_TYPE:-3}

        echo "Database selected : $DATABASE_TYPE !!"

		if [ "$DATABASE_TYPE" = "1" ] || [ "$DATABASE_TYPE" = "2" ]
		then
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
		fi 

		#
		# Step 2 : Configure ElasticSearch connection
		#
		echo ""
		echo ""
		echo "Finally, please clue us in on the location of your Elasticsearch"
		echo "instance.  Please include the port - Elasticsearch typically"
		echo "listens on port 9200."
		echo "An example might be:"
		echo "    http://localhost:9200"
		echo ""
		read -p "Elastic URL (default: http://localhost:9200): " ELASTIC_URL
		ELASTIC_URL=${ELASTIC_URL:-http://localhost:9200}
        if [[ "$unamestr" == 'Linux' ]]; then
          ES_PROTOCOL=`echo $ELASTIC_URL | sed -r 's/(https?).*/\1/g'`
          ES_HOST=`echo $ELASTIC_URL | sed -r 's/https?:\/\/([^\:^\/]+)\:?[0-9]*\/?.*/\1/g'`
          ES_PORT=`echo $ELASTIC_URL | sed -r 's/https?\:\/\/[^\:]+\:?([0-9]+)?.*/\1/g'`
        elif [[ "$unamestr" == 'Darwin' ]]; then
          ES_PROTOCOL=`echo $ELASTIC_URL | sed -E 's/(https?).*/\1/g'`
          ES_HOST=`echo $ELASTIC_URL | sed -E 's/https?:\/\/([^\:^\/]+)\:?[0-9]*\/?.*/\1/g'`
          ES_PORT=`echo $ELASTIC_URL | sed -E 's/https?\:\/\/[^\:]+\:?([0-9]+)?.*/\1/g'`
        fi

		echo ""
		echo "Thanks!  Will use the following elasticsearch info:"
		echo "---------------------------------------------------------"
		echo "  protocol: $ES_PROTOCOL"
		echo "      host: $ES_HOST"
		echo "      port: $ES_PORT"
		echo "---------------------------------------------------------"
		echo ""
		echo ""

		#
		# Step 3. Download and unzip Wildfly, Apiman
		#
		if [ -d "$INSTALL_DIRECTORY/apiman-manager-$APIMAN_VERSION" ]; then
		  rm -rf $INSTALL_DIRECTORY/apiman-manager-$APIMAN_VERSION
	    fi
		mkdir $INSTALL_DIRECTORY/apiman-manager-$APIMAN_VERSION
	    cd $INSTALL_DIRECTORY/apiman-manager-$APIMAN_VERSION
	    curl http://downloads.jboss.org/wildfly/${WILDFLY_VERSION}/wildfly-${WILDFLY_VERSION}.zip -o wildfly-${WILDFLY_VERSION}.zip
	    curl http://downloads.jboss.org/apiman/$APIMAN_VERSION/apiman-distro-wildfly9-$APIMAN_VERSION-overlay.zip -o apiman-distro-wildfly9-$APIMAN_VERSION-overlay.zip
	    unzip wildfly-${WILDFLY_VERSION}.zip
	    unzip -o apiman-distro-wildfly9-$APIMAN_VERSION-overlay.zip -d wildfly-${WILDFLY_VERSION}
	    cd wildfly-${WILDFLY_VERSION}

		#
		# Step 4. Remove the gateway war files
		#
		rm standalone/deployments/apiman-es.war
		rm standalone/deployments/apiman-gateway-api.war
		rm standalone/deployments/apiman-gateway.war

		#
		# Step 5. Comment the apiman-gateway parameters
		#
		if [[ "$unamestr" == 'Linux' ]]; then
 		  sed -i "s/^apiman-gateway/#apiman-gateway/g" standalone/configuration/apiman.properties
        elif [[ "$unamestr" == 'Darwin' ]]; then
          sed -i '' "s/^apiman-gateway/#apiman-gateway/g" standalone/configuration/apiman.properties
        fi

        #
        # Step 6. Configure External ElasticSearch Server
        #
        sed -i '' "s/apiman.es.protocol=.*$/apiman.es.protocol=$ES_PROTOCOL/g" standalone/configuration/apiman.properties
        sed -i '' "s/apiman.es.host=.*$/apiman.es.host=$ES_HOST/g" standalone/configuration/apiman.properties
        sed -i '' "s/apiman.es.port=.*$/apiman.es.port=$ES_PORT/g" standalone/configuration/apiman.properties

        #
        # Step 7. Setup the Database parameters (MySQL, PostgreSQL)
        #
        if [ "x$DATABASE_TYPE" = "x1" ]
        then
          HIBERNATE_DIALECT=org.hibernate.dialect.MySQL5Dialect
          curl https://repo1.maven.org/maven2/mysql/mysql-connector-java/5.1.33/mysql-connector-java-5.1.33.jar -o ~/apiman-manager-$APIMAN_VERSION/wildfly-9.0.2.Final/standalone/deployments/mysql-connector-java-5.1.33-bin.jar
          cp ~/apiman-manager-$APIMAN_VERSION/wildfly-9.0.2.Final/apiman/sample-configs/apiman-ds_mysql.xml ~/apiman-manager-$APIMAN_VERSION/wildfly-9.0.2.Final/standalone/deployments/apiman-ds.xml
          sed -i "s/MYSQLSERVER/$DATABASE_HOST/g" ~/apiman-manager-$APIMAN_VERSION/wildfly-9.0.2.Final/standalone/deployments/apiman-ds.xml
          sed -i "s/3306/$DATABASE_PORT/g" ~/apiman-manager-$APIMAN_VERSION/wildfly-9.0.2.Final/standalone/deployments/apiman-ds.xml
          sed -i "s/^apiman.hibernate.dialect=.*$/apiman.hibernate.dialect=$HIBERNATE_DIALECT/g" ~/apiman-manager-$APIMAN_VERSION/wildfly-9.0.2.Final/standalone/configuration/apiman.properties
          sed -i "s/DBUSER/$DATABASE_USER/g" ~/apiman-manager-$APIMAN_VERSION/wildfly-9.0.2.Final/standalone/deployments/apiman-ds.xml
          sed -i "s/DBPASS/$DATABASE_PASSWORD/g" ~/apiman-manager-$APIMAN_VERSION/wildfly-9.0.2.Final/standalone/deployments/apiman-ds.xml
        elif [ "x$DATABASE_TYPE" = "x2" ]
        then
          HIBERNATE_DIALECT=org.hibernate.dialect.PostgreSQLDialect
          curl https://repo1.maven.org/maven2/org/postgresql/postgresql/9.3-1102-jdbc41/postgresql-9.3-1102-jdbc41.jar -o ~/apiman-manager-$APIMAN_VERSION/wildfly-9.0.2.Final/standalone/deployments/postgresql-9.3-1102.jdbc41.jar
          cp ~/apiman-manager-$APIMAN_VERSION/wildfly-9.0.2.Final/apiman/sample-configs/apiman-ds_postgresql.xml ~/apiman-manager-$APIMAN_VERSION/wildfly-9.0.2.Final/standalone/deployments/apiman-ds.xml
          sed -i "s/POSTGRESQLSERVER/$DATABASE_HOST/g" ~/apiman-manager-$APIMAN_VERSION/wildfly-9.0.2.Final/standalone/deployments/apiman-ds.xml
          sed -i "s/5432/$DATABASE_PORT/g" ~/apiman-manager-$APIMAN_VERSION/wildfly-9.0.2.Final/standalone/deployments/apiman-ds.xml
          sed -i "s/^apiman.hibernate.dialect=.*$/apiman.hibernate.dialect=$HIBERNATE_DIALECT/g" ~/apiman-manager-$APIMAN_VERSION/wildfly-9.0.2.Final/standalone/configuration/apiman.properties
          sed -i "s/DBUSER/$DATABASE_USER/g" ~/apiman-manager-$APIMAN_VERSION/wildfly-9.0.2.Final/standalone/deployments/apiman-ds.xml
          sed -i "s/DBPASS/$DATABASE_PASSWORD/g" ~/apiman-manager-$APIMAN_VERSION/wildfly-9.0.2.Final/standalone/deployments/apiman-ds.xml
        fi

		#
		# Step 8. Change the binding port offset to avoid conflicts
		#
		# Apiman Manager offset: 0 (-> 8080, 8443)
		# Apiman Gateway offset: 100 (-> 8180, 8543)
		# Apiman Keycloak Server offset: 200 (-> 8280, 8643)
		#
        if [[ "$unamestr" == 'Linux' ]]; then
          sed -i "s/jboss.socket.binding.port-offset:0/jboss.socket.binding.port-offset:0/g" standalone/configuration/standalone-apiman.xml
        elif [[ "$unamestr" == 'Darwin' ]]; then
          sed -i '' "s/jboss.socket.binding.port-offset:0/jboss.socket.binding.port-offset:0/g" standalone/configuration/standalone-apiman.xml
        fi

        #
        # Step 9. Use External Keycloak Server. Can also be used for local access with this address https://localhost:8443/auth
        #
        if [[ "$unamestr" == 'Linux' ]]; then
          sed -i "s/<kc\:auth-server-url>\/auth<\/kc\:auth-server-url>/<kc\:auth-server-url>$KEYCLOAK_URL_ESC<\/kc\:auth-server-url>/g" standalone/configuration/standalone-apiman.xml
        elif [[ "$unamestr" == 'Darwin' ]]; then
          sed -i '' "s/\(<auth-server-url>\).*\(<\/auth-server-url\)/\1$KEYCLOAK_URL_ESC\2/" standalone/configuration/standalone-apiman.xml
        fi

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




