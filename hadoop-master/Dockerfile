FROM gethue/hue:4.11.0

USER root

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y \
    openjdk-8-jdk \
    wget \
    curl \
    procps \
    netcat \
    net-tools \
    rsync \
    && rm -rf /var/lib/apt/lists/*

ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
ENV HADOOP_HOME=/opt/hadoop
ENV HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop
ENV HIVE_HOME=/opt/hive

ENV PATH=$JAVA_HOME/bin:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$HIVE_HOME/bin:$PATH

# Hadoop 2.7.4
RUN wget -q https://archive.apache.org/dist/hadoop/common/hadoop-2.7.4/hadoop-2.7.4.tar.gz && \
    tar -xzf hadoop-2.7.4.tar.gz -C /opt && \
    mv /opt/hadoop-2.7.4 /opt/hadoop && \
    rm hadoop-2.7.4.tar.gz

# Hive 2.3.2
RUN wget -q https://archive.apache.org/dist/hive/hive-2.3.2/apache-hive-2.3.2-bin.tar.gz && \
    tar -xzf apache-hive-2.3.2-bin.tar.gz -C /opt && \
    mv /opt/apache-hive-2.3.2-bin /opt/hive && \
    rm apache-hive-2.3.2-bin.tar.gz

COPY core-site.xml /opt/hadoop/etc/hadoop/core-site.xml
COPY hdfs-site.xml /opt/hadoop/etc/hadoop/hdfs-site.xml
COPY yarn-site.xml /opt/hadoop/etc/hadoop/yarn-site.xml
COPY mapred-site.xml /opt/hadoop/etc/hadoop/mapred-site.xml
COPY hive-site.xml /opt/hive/conf/hive-site.xml
COPY hue.ini /usr/share/hue/desktop/conf/z-hue.ini
COPY start.sh /start.sh

RUN chmod +x /start.sh && \
    mkdir -p /hadoop/dfs/name /hadoop/dfs/data /hadoop/dfs/secondary /opt/hive-data /opt/hue-data && \
    chmod -R 777 /hadoop/dfs /opt/hive-data /opt/hue-data && \
    chown -R hue:hue /usr/share/hue

EXPOSE 50070 8030 8031 8032 8088 9000 10000 8888

CMD ["/start.sh"]