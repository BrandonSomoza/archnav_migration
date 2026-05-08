FROM ubuntu:20.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y wget openjdk-8-jdk ldap-utils && rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
ENV PATH=$JAVA_HOME/bin:$PATH

RUN wget -q https://archive.apache.org/dist/directory/apacheds/dist/2.0.0.AM25/apacheds-2.0.0.AM25-amd64.deb -O /tmp/apacheds.deb \
    && dpkg -i /tmp/apacheds.deb \
    && rm /tmp/apacheds.deb

# Point ApacheDS wrapper to Java
RUN echo "wrapper.java.command=/usr/lib/jvm/java-8-openjdk-amd64/bin/java" >> /opt/apacheds-2.0.0.AM25/conf/wrapper.conf

EXPOSE 10389 10636

CMD ["/opt/apacheds-2.0.0.AM25/bin/apacheds", "console", "default"]
