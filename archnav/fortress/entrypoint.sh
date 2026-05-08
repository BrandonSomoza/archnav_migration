#!/bin/bash

echo "Waiting for ApacheDS to be ready..."
until ldapsearch -H ldap://apacheds:10389 -x -D "uid=admin,ou=system" -w secret -b "" -s base > /dev/null 2>&1; do
    echo "ApacheDS not ready yet, retrying in 5 seconds..."
    sleep 5
done
echo "ApacheDS is ready!"

echo "Importing Fortress schema..."
ldapadd -H ldap://apacheds:10389 -x -D "uid=admin,ou=system" -w secret -f /opt/fortress-core-2.0.3/ldap/schema/apacheds-fortress.ldif
echo "Schema import done."

echo "Running refreshLDAPData..."
cd /opt/fortress-core-2.0.3 && mvn install -Dload.file=./ldap/setup/refreshLDAPData.xml -Dfortress.host=apacheds

echo "Running DelegatedAdminManagerLoad..."
cd /opt/fortress-core-2.0.3 && mvn install -Dload.file=./ldap/setup/DelegatedAdminManagerLoad.xml -Dfortress.host=apacheds

echo "Running FortressRestServerPolicy..."
cd /opt/fortress-rest-2.0.3 && mvn install -Dload.file=./src/main/resources/FortressRestServerPolicy.xml -Dfortress.host=apacheds

echo "Running FortressWebDemoUsers..."
cd /opt/fortress-web-2.0.3 && mvn install -Dload.file=./src/main/resources/FortressWebDemoUsers.xml -Dfortress.host=apacheds

echo "Running ArchNav Security Policy..."
cd /opt/fortress-core-2.0.3 && mvn install -Dload.file=./ldap/setup/ArchNavSecurityPolicy.xml -Dfortress.host=apacheds

echo "Starting Tomcat..."
exec /usr/share/tomcat9/bin/catalina.sh run
