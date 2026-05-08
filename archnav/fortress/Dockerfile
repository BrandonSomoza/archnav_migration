FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    wget \
    unzip \
    openjdk-8-jdk \
    maven \
    tomcat9 \
    tomcat9-admin \
    ldap-utils \
    && rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
ENV PATH=$JAVA_HOME/bin:$PATH

RUN wget -q https://archive.apache.org/dist/directory/fortress/dist/2.0.3/fortress-core-2.0.3-source-release.zip -O /tmp/fortress-core.zip \
    && unzip -q /tmp/fortress-core.zip -d /opt \
    && rm /tmp/fortress-core.zip

COPY fortress.properties /opt/fortress-core-2.0.3/config/fortress.properties
RUN cp /opt/fortress-core-2.0.3/build.properties.example /opt/fortress-core-2.0.3/build.properties && sed -i 's/ldap.host=localhost/ldap.host=apacheds/' /opt/fortress-core-2.0.3/build.properties && cd /opt/fortress-core-2.0.3 && mvn install -DskipTests

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

COPY entrypoint.sh /entrypoint.sh
COPY ArchNavSecurityPolicy.xml /opt/fortress-core-2.0.3/ldap/setup/ArchNavSecurityPolicy.xml
RUN chmod +x /entrypoint.sh

CMD ["/entrypoint.sh"]
