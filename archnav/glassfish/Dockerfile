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
COPY archemy-security-1.0-SNAPSHOT-jar-with-dependencies.jar $GLASSFISH_HOME/glassfish/domains/domain1/lib/
COPY archemy.ear $GLASSFISH_HOME/glassfish/domains/domain1/autodeploy/
COPY setup.sh /setup.sh

RUN chmod +x /setup.sh && /setup.sh

EXPOSE 8080 4848 9999

CMD ["/opt/glassfish5/bin/asadmin", "start-domain", "--verbose"]
