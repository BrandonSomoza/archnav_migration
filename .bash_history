sudo docker ps
sudo docker ps -a
sudo docker logs apacheds
sudo docker logs fortress
cat > ~/archnav/apacheds/Dockerfile << 'EOF'
FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y wget && rm -rf /var/lib/apt/lists/*

RUN wget -q https://archive.apache.org/dist/directory/apacheds/dist/2.0.0.AM25/apacheds-2.0.0.AM25-amd64.deb -O /tmp/apacheds.deb \
    && dpkg -i /tmp/apacheds.deb \
    && rm /tmp/apacheds.deb

EXPOSE 10389 10636

CMD ["/opt/apacheds-2.0.0.AM25/bin/apacheds", "console", "default"]
EOF

cat > ~/archnav/fortress/Dockerfile << 'EOF'
FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    wget \
    unzip \
    openjdk-8-jdk \
    maven \
    tomcat9 \
    tomcat9-admin \
    && rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
ENV PATH=$JAVA_HOME/bin:$PATH

RUN wget -q https://archive.apache.org/dist/directory/fortress/dist/2.0.3/fortress-core-2.0.3-source-release.zip -O /tmp/fortress-core.zip \
    && unzip -q /tmp/fortress-core.zip -d /opt \
    && rm /tmp/fortress-core.zip

COPY fortress.properties /opt/fortress-core-2.0.3/config/fortress.properties
RUN cd /opt/fortress-core-2.0.3 && mvn install -DskipTests

RUN wget -q https://archive.apache.org/dist/directory/fortress/dist/2.0.3/fortress-rest-2.0.3-source-release.zip -O /tmp/fortress-rest.zip \
    && unzip -q /tmp/fortress-rest.zip -d /opt \
    && rm /tmp/fortress-rest.zip

RUN cp /opt/fortress-core-2.0.3/config/fortress.properties /opt/fortress-rest-2.0.3/src/main/resources/
RUN cd /opt/fortress-rest-2.0.3 && mvn install -DskipTests

RUN wget -q https://archive.apache.org/dist/directory/fortress/dist/2.0.3/fortress-web-2.0.3-source-release.zip -O /tmp/fortress-web.zip \
    && unzip -q /tmp/fortress-web.zip -d /opt \
    && rm /tmp/fortress-web.zip

RUN cp /opt/fortress-core-2.0.3/config/fortress.properties /opt/fortress-web-2.0.3/src/main/resources/
RUN cd /opt/fortress-web-2.0.3 && mvn install -DskipTests

RUN wget -q https://repo.maven.apache.org/maven2/org/apache/directory/fortress/fortress-realm-proxy/2.0.3/fortress-realm-proxy-2.0.3.jar \
    -O /usr/share/tomcat9/lib/fortress-realm-proxy-2.0.3.jar

RUN cp /opt/fortress-rest-2.0.3/target/fortress-rest-2.0.3.war /var/lib/tomcat9/webapps/ \
    && cp /opt/fortress-web-2.0.3/target/fortress-web-2.0.3.war /var/lib/tomcat9/webapps/

RUN echo '<?xml version="1.0" encoding="UTF-8"?>\n\
<tomcat-users>\n\
  <role rolename="manager-script"/>\n\
  <role rolename="manager-gui"/>\n\
  <user username="tcmanager" password="m@nager123" roles="manager-script"/>\n\
  <user username="tcmanagergui" password="m@nager123" roles="manager-gui"/>\n\
</tomcat-users>' > /etc/tomcat9/tomcat-users.xml

ENV CATALINA_HOME=/usr/share/tomcat9
ENV CATALINA_BASE=/var/lib/tomcat9

ENV JAVA_OPTS="-Dfortress.admin.user=uid=admin,ou=system \
    -Dfortress.admin.pw=secret \
    -Dfortress.config.root=ou=Config,dc=example,dc=com \
    -Dfortress.port=10389"

EXPOSE 8080

CMD ["/usr/share/tomcat9/bin/catalina.sh", "run"]
EOF

cd ~/archnav/apacheds && sudo docker build -t archnav-apacheds . && cd ~/archnav/fortress && sudo docker build -t archnav-fortress .
clear
cd ~/archnav/apacheds && sudo docker build -t archnav-apacheds . && cd ~/archnav/fortress && sudo docker build -t archnav-fortress .
cd ~/archnav && sudo docker-compose down && sudo docker-compose up
clear
sudo docker ps
sudo docker exec -it apacheds /opt/apacheds-2.0.0.AM25/bin/apacheds status default
sudo docker exec -it fortress bash -c "cd /opt/fortress-core-2.0.3 && mvn install -Dload.file=./ldap/setup/refreshLDAPData.xml -DskipTests"
sudo docker exec -it fortress bash -c "cd /opt/fortress-core-2.0.3 && mvn install -Dload.file=./ldap/setup/refreshLDAPData.xml -DskipTests -e 2>&1 | grep -A 20 'BUILD FAILURE'"
sudo docker exec -it fortress bash -c "cat > /opt/fortress-core-2.0.3/config/bootstrap/fortress.properties << 'EOF'
ldap.server.type=apacheds
ldap.host=apacheds
ldap.port=10389
root.dn=uid=admin,ou=system
cfg.root.pw=secret
ldap.client.type=apache
suffix.name=example
suffix.dc=com
suffix=dc=example,dc=com
users.dn=ou=People,dc=example,dc=com
roles.dn=ou=Roles,ou=RBAC,dc=example,dc=com
policies.dn=ou=Policies,dc=example,dc=com
perms.dn=ou=Permissions,ou=RBAC,dc=example,dc=com
constraints.dn=ou=Constraints,ou=RBAC,dc=example,dc=com
userous.dn=ou=OS-U,ou=ARBAC,dc=example,dc=com
permous.dn=ou=OS-P,ou=ARBAC,dc=example,dc=com
adminroles.dn=ou=AdminRoles,ou=ARBAC,dc=example,dc=com
adminperms.dn=ou=AdminPerms,ou=ARBAC,dc=example,dc=com
groups.dn=ou=Groups,dc=example,dc=com
admin.min.conn=1
admin.max.conn=10
user.min.conn=1
user.max.conn=10
min.log.conn=1
max.log.conn=3
group.objectclass=configGroup
group.protocol=configProtocol
group.properties=configParameter
rfc2307=false
EOF"
sudo docker exec -it fortress bash -c "cd /opt/fortress-core-2.0.3 && mvn install -Dload.file=./ldap/setup/refreshLDAPData.xml -DskipTests"
sudo docker exec -it fortress bash -c "apt-get install -y telnet 2>/dev/null && telnet apacheds 10389"
sudo docker exec -it apacheds bash -c "apt-get install -y net-tools 2>/dev/null && netstat -tlnp"
sudo docker exec -it apacheds bash -c "cat /proc/net/tcp"
sudo docker exec -it apacheds bash -c "cat /var/log/apacheds-2.0.0.AM25/default/apacheds.log 2>/dev/null || cat /opt/apacheds-2.0.0.AM25/instances/default/log/apacheds.log 2>/dev/null"
sudo docker exec -it apacheds bash -c "find / -name '*.log' 2>/dev/null | grep -i apache"
sudo docker ps
sudo docker exec -it apacheds bash -c "cat /var/lib/apacheds-2.0.0.AM25/default/log/apacheds.log | tail -50"
sudo docker exec -it apacheds bash -c "cat /var/lib/apacheds-2.0.0.AM25/default/log/apacheds.log | grep -i 'started\|listening\|transport\|10389'"
sudo docker exec -it apacheds bash -c "tail -5 /var/lib/apacheds-2.0.0.AM25/default/log/apacheds.log"
sudo docker exec -it apacheds bash -c "tail -20 /var/lib/apacheds-2.0.0.AM25/default/log/wrapper.log"
sudo docker exec -it apacheds bash -c "cat /proc/net/tcp6 | grep 28A5"
sudo docker exec -it apacheds bash -c "cat /proc/net/tcp6"
sudo docker exec -it fortress bash -c "cd /opt/fortress-core-2.0.3 && mvn install -Dload.file=./ldap/setup/refreshLDAPData.xml -DskipTests"
sudo docker exec -it fortress bash -c "cat /etc/hosts"
sudo docker network ls && sudo docker inspect archnav_default | grep -A 20 "Containers"
sudo docker exec -it fortress bash -c "cd /opt/fortress-core-2.0.3 && sed -i 's/ldap.host=apacheds/ldap.host=172.20.0.2/' config/bootstrap/fortress.properties && cat config/bootstrap/fortress.properties | grep ldap.host"
sudo docker exec -it fortress bash -c "cd /opt/fortress-core-2.0.3 && mvn install -Dload.file=./ldap/setup/refreshLDAPData.xml -DskipTests"
sudo docker exec -it fortress bash -c "cat /opt/fortress-core-2.0.3/config/bootstrap/fortress.properties | grep ldap.host"
sudo docker exec -it fortress bash -c "apt-get install -y netcat 2>/dev/null && nc -zv 172.20.0.2 10389"
nc -zv 172.20.0.2 10389
sudo docker exec -it apacheds bash -c "cat /var/lib/apacheds-2.0.0.AM25/default/conf/config.ldif | grep -i 'address\|transport\|port'"
sudo docker exec -it apacheds bash -c "find / -name 'config.ldif' 2>/dev/null"
sudo docker exec -it apacheds bash -c "find /var/lib/apacheds-2.0.0.AM25 -type f 2>/dev/null"
sudo docker exec -it apacheds bash -c "find /var/lib/apacheds-2.0.0.AM25 -type f 2>/dev/null" | grep -i conf
sudo docker exec -it apacheds bash -c "find /var/lib/apacheds-2.0.0.AM25/default/conf -name '*.ldif' | xargs grep -l 'ldap\|transport' 2>/dev/null"
sudo docker exec -it apacheds bash -c "cat '/var/lib/apacheds-2.0.0.AM25/default/conf/ou=config/ads-directoryserviceid=default/ou=servers/ads-serverid=ldapserver/ou=transports/ads-transportid=ldap.ldif'"
sudo docker exec -it fortress bash -c "bash -c 'echo > /dev/tcp/172.20.0.2/10389' && echo 'connected' || echo 'failed'"
sudo docker exec -it fortress bash -c "find /opt/fortress-core-2.0.3 -name 'fortress.properties' 2>/dev/null"
sudo docker exec -it fortress bash -c "find /opt/fortress-core-2.0.3 -name 'fortress.properties' -exec sed -i 's/ldap.host=.*/ldap.host=172.20.0.2/' {} \;"
sudo docker exec -it fortress bash -c "find /opt/fortress-core-2.0.3 -name 'fortress.properties' | xargs grep ldap.host"
sudo docker exec -it fortress bash -c "find /opt/fortress-core-2.0.3 -name 'fortress.properties' | xargs sed -i 's/host=\${ldap.host}/host=172.20.0.2/g'"
sudo docker exec -it fortress bash -c "cd /opt/fortress-core-2.0.3 && mvn install -Dload.file=./ldap/setup/refreshLDAPData.xml -DskipTests"
sudo docker exec -it fortress bash -c "cat /opt/fortress-core-2.0.3/target/antrun/build-fortress-load.xml | grep -i 'fortress\|config\|properties'"
sudo docker exec -it fortress bash -c "cat /opt/fortress-core-2.0.3/config/bootstrap/fortress.properties | grep -E 'ldap.host|ldap.port'"
sudo iptables -L DOCKER-USER 2>/dev/null || sudo iptables -L FORWARD
docker ps
sudo docker ps
sudo docker exec -it fortress bash -c "java -cp /opt/fortress-core-2.0.3/target/fortress-core-2.0.3.jar org.apache.directory.fortress.core.util.Config 2>&1 | head -20"
sudo docker exec -it fortress bash -c "apt-get install -y ldap-utils 2>/dev/null && ldapsearch -H ldap://172.20.0.2:10389 -x -D 'uid=admin,ou=system' -w secret -b 'ou=system' 2>&1 | head -20"
sudo docker exec -it fortress bash -c "cd /opt/fortress-core-2.0.3 && java -cp 'target/fortress-core-2.0.3-tests.jar:target/fortress-core-2.0.3.jar:target/dependency/*:config/bootstrap' -Dload.file=./ldap/setup/refreshLDAPData.xml org.apache.tools.ant.launch.Launcher -f ./ldap/setup/refreshLDAPData.xml 2>&1 | head -30"
sudo apt-get install -y ldap-utils && ldapsearch -H ldap://172.20.0.2:10389 -x -D "uid=admin,ou=system" -w secret -b "ou=system" 2>&1 | head -20
sudo apt-get install -y maven openjdk-8-jdk
sudo docker exec -it fortress bash
cd /opt/fortress-core-2.0.3 && mvn install -Dload.file=./ldap/setup/refreshLDAPData.xml -DskipTests
sudo docker exec -it fortress bash
sudo docker exec -it glassfish /opt/glassfish5/bin/asadmin --port 4848 list-jdbc-connection-pools
sudo docker exec -it fortress bash
sudo docker exec -it glassfish /opt/glassfish5/bin/asadmin --port 4848 list-jdbc-connection-pools
cat > ~/archnav/glassfish/setup.sh << 'EOF'
#!/bin/bash


# Start GlassFish in background

/opt/glassfish5/bin/asadmin start-domain domain1

# Wait for it to be ready

sleep 15

# JVM options

/opt/glassfish5/bin/asadmin --port 4848 create-jvm-options -- -XX\\:MaxPermSize=512m
/opt/glassfish5/bin/asadmin --port 4848 create-jvm-options -- -Doracle.mds.cache=simple

# JDBC pool

/opt/glassfish5/bin/asadmin --port 4848 create-jdbc-connection-pool \
  --datasourceclassname com.mysql.cj.jdbc.MysqlXADataSource \
  --restype javax.sql.XADataSource \
  --property "ServerName=migration-db.mysql.database.azure.com:Port=3306:DatabaseName=archemy:User=archnav_admin:Password=Migration123\!:useSSL=false" \
  MySQLConnPool

/opt/glassfish5/bin/asadmin --port 4848 create-jdbc-resource \
  --connectionpoolid MySQLConnPool jdbc/Connection1DS

# Stop domain and let CMD restart it in foreground

/opt/glassfish5/bin/asadmin stop-domain domain1
EOF

chmod +x ~/archnav/glassfish/setup.sh
cat > ~/archnav/glassfish/Dockerfile << 'EOF'
FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    wget \
    unzip \
    openjdk-8-jdk \
    && rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
ENV PATH=$JAVA_HOME/bin:$PATH

RUN wget -q http://download.oracle.com/glassfish/5.0.1/release/glassfish-5.0.1.zip -O /tmp/glassfish.zip \
    && unzip -q /tmp/glassfish.zip -d /opt \
    && rm /tmp/glassfish.zip

ENV GLASSFISH_HOME=/opt/glassfish5

COPY adf-essentials/ $GLASSFISH_HOME/glassfish/domains/domain1/lib/
COPY mysql-connector.jar $GLASSFISH_HOME/glassfish/domains/domain1/lib/
COPY archemy.ear $GLASSFISH_HOME/glassfish/domains/domain1/autodeploy/
COPY setup.sh /setup.sh

RUN chmod +x /setup.sh && /setup.sh

EXPOSE 8080 4848 9999

CMD ["/opt/glassfish5/bin/asadmin", "start-domain", "--verbose"]
EOF

sudo docker exec -it glassfish /opt/glassfish5/bin/asadmin --port 4848 list-jdbc-connection-pools
sudo docker exec -it glassfish /opt/glassfish5/bin/asadmin --port 4848 list-jdbc-resources
cd ~/archnav/glassfish && sudo docker build -t archnav-glassfish .
cd ~/archnav && sudo docker-compose down && sudo docker-compose up
cd ~/archnav && sudo docker-compose down -v
sudo docker-compose build --no-cache
cat ~/archnav/docker-compose.yml
cat > ~/archnav/docker-compose.yml << 'EOF'
version: '3.3'

services:
  apacheds:
    build: ./apacheds
    image: archnav-apacheds
    container_name: apacheds
    ports:
      - "10389:10389"
    volumes:
      - apacheds-data:/var/lib/apacheds-2.0.0.AM25

  fortress:
    build: ./fortress
    image: archnav-fortress
    container_name: fortress
    ports:
      - "8080:8080"
    depends_on:
      - apacheds

  glassfish:
    build: ./glassfish
    image: archnav-glassfish
    container_name: glassfish
    ports:
      - "9999:8080"
      - "4848:4848"
    depends_on:
      - apacheds
      - fortress

volumes:
  apacheds-data:
EOF

cat ~/archnav/docker-compose.yml
cat ~/archnav/apacheds/Dockerfile
cat ~/archnav/fortress/Dockerfile
cat ~/archnav/glassfish/Dockerfile
sudo docker build -t archnav-apacheds ./apacheds
sudo docker build -t archnav-fortress ./fortress
sudo docker build -t archnav-glassfish ./glassfish
sudo docker-compose up
sudo docker exec apacheds bash -c "cat /dev/null > /dev/tcp/localhost/10389 && echo open || echo closed"
sudo docker logs apacheds --tail 50
cd ~/archnav && sudo docker-compose down -v
sudo docker-compose up
unzip -l ~/ADFEssentialsApp.zip | grep -i "adf-essentials\|adf_essentials\|essentials" | head -20
unzip -l ~/V996774-01.zip | grep -i mds
unzip -j ~/V996774-01.zip "modules/oracle.mds/mdsrt.jar" -d /tmp/newmds/
jar xf /tmp/newmds/mdsrt.jar META-INF/MANIFEST.MF && cat /tmp/META-INF/MANIFEST.MF
unzip -l ~/V996774-01.zip | grep "\.jar" | wc -l
unzip -l ~/V996774-01.zip | grep "\.jar" | head -30
unzip -l ~/V996774-01.zip | head -50
rm -rf ~/archnav/glassfish/adf-essentials/*
unzip -j ~/V996774-01.zip "modules/*.jar" "modules/*/*.jar" -d ~/archnav/glassfish/adf-essentials/
ls ~/archnav/glassfish/adf-essentials/ | wc -l
cat > ~/archnav/rebuild.sh << 'EOF'
#!/bin/bash

set -e

echo "Bringing down containers and volumes..."
cd ~/archnav
sudo docker-compose down -v

echo "Building apacheds..."
sudo docker build -t archnav-apacheds ./apacheds --no-cache

echo "Building fortress..."
sudo docker build -t archnav-fortress ./fortress --no-cache

echo "Building glassfish..."
sudo docker build -t archnav-glassfish ./glassfish --no-cache

echo "Starting containers..."
sudo docker-compose up
EOF

chmod +x ~/archnav/rebuild.sh
ls
mv ~/archnav/rebuild.sh ~/archnav/build.sh
~/archnav/build.sh
sudo docker exec glassfish tail -30 /opt/glassfish5/glassfish/domains/domain1/logs/server.log
jar xf /tmp/Archemy_Project1_webapp.war WEB-INF/web.xml && cat /tmp/WEB-INF/web.xml | grep -i "jndi\|resource\|jdbc\|archemy"
cat /tmp/adf/META-INF/connections.xml
cd /tmp && jar xf ~/archnav/glassfish/archemy.ear adf/META-INF/connections.xml && cat /tmp/adf/META-INF/connections.xml
jar xf ~/archnav/glassfish/archemy.ear META-INF/glassfish-application.xml && cat /tmp/META-INF/glassfish-application.xml
jar xf ~/archnav/glassfish/archemy.ear META-INF/application.xml && cat /tmp/META-INF/application.xml
mkdir -p /tmp/warcontents && cd /tmp/warcontents && jar xf /tmp/Archemy_Project1_webapp.war && grep -r "archemyapp" /tmp/warcontents/
sed -i 's|# Fortress LDAP connection options|/opt/glassfish5/bin/asadmin --port 4848 create-jdbc-resource --connectionpoolid MySQLConnPool jdbc/archemyapp\n\n# Fortress LDAP connection options|' ~/archnav/glassfish/setup.sh
cat ~/archnav/glassfish/setup.sh
grep -r "Connection1DS" /tmp/warcontents/
grep -r "Connection1DS" ~/archnav/
grep -r "Connection1DS" /tmp/
cd ~/archnav && ./build.sh
exit
ls
cd archnav
ls
cat apacheds/Dockerfile
cat fortress/Dockerfile
ls
cat glassfish/Dockerfile
ls
cat docker-compose.yml
ls
cat build.sh
df -h
cat > ~/archnav/start.sh << 'EOF'
#!/bin/bash

cd ~/archnav
sudo docker-compose up
EOF

chmod +x ~/archnav/start.sh
cat > ~/archnav/stop.sh << 'EOF'
#!/bin/bash

cd ~/archnav
sudo docker-compose down
EOF

chmod +x ~/archnav/stop.sh
df -h
./stop.sh
./start.sh
