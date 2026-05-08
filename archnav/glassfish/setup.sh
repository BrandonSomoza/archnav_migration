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

/opt/glassfish5/bin/asadmin --port 4848 create-jdbc-resource --connectionpoolid MySQLConnPool jdbc/archemyapp

# Fortress LDAP connection options
/opt/glassfish5/bin/asadmin --port 4848 create-jvm-options -- -Dfortress.host=apacheds
/opt/glassfish5/bin/asadmin --port 4848 create-jvm-options -- -Dfortress.port=10389
/opt/glassfish5/bin/asadmin --port 4848 create-jvm-options -- -Dfortress.admin.user=uid=admin,ou=system
/opt/glassfish5/bin/asadmin --port 4848 create-jvm-options -- -Dfortress.admin.pw=secret
/opt/glassfish5/bin/asadmin --port 4848 create-jvm-options -- "-Dfortress.config.root=ou=Config,dc=example,dc=com"

# Stop domain and let CMD restart it in foreground
/opt/glassfish5/bin/asadmin stop-domain domain1
