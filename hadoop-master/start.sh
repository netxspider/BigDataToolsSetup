#!/bin/bash

set -e

export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64
export HADOOP_HOME=/opt/hadoop
export HADOOP_CONF_DIR=/opt/hadoop/etc/hadoop
export HIVE_HOME=/opt/hive

export PATH=$JAVA_HOME/bin:$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$HIVE_HOME/bin:$PATH

echo "======================================"
echo "Starting Hadoop + Hive + Hue"
echo "======================================"

# First-time NameNode initialization
if [ ! -d /hadoop/dfs/name/current ]; then
    echo "Formatting NameNode..."
    hdfs namenode -format -force
fi

echo "Starting NameNode..."
hdfs namenode > /var/log/namenode.log 2>&1 &

echo "Starting DataNode..."
hdfs datanode > /var/log/datanode.log 2>&1 &

echo "Waiting for HDFS..."

for i in {1..60}; do
    if hdfs dfs -ls / >/dev/null 2>&1; then
        echo "HDFS is ready."
        break
    fi
    sleep 2
done

if ! hdfs dfs -ls / >/dev/null 2>&1; then
    echo "ERROR: HDFS failed to start."
    cat /var/log/namenode.log
    cat /var/log/datanode.log
    exit 1
fi

echo "Creating Hive directories..."

hdfs dfs -mkdir -p /tmp
hdfs dfs -mkdir -p /user/hive/warehouse
hdfs dfs -chmod 777 /tmp
hdfs dfs -chmod 777 /user/hive/warehouse

# Initialize Hive Derby database only once
if [ ! -f /opt/hive-data/metastore_db/service.properties ]; then
    echo "Initializing Hive Derby metastore..."
    rm -rf /opt/hive-data/metastore_db
    schematool -dbType derby -initSchema
fi

echo "Starting HiveServer2..."

hiveserver2 > /var/log/hiveserver2.log 2>&1 &

echo "Waiting for HiveServer2..."

for i in {1..60}; do
    if nc -z 127.0.0.1 10000 >/dev/null 2>&1; then
        echo "HiveServer2 is ready."
        break
    fi
    sleep 2
done

if ! nc -z 127.0.0.1 10000 >/dev/null 2>&1; then
    echo "ERROR: HiveServer2 failed."
    cat /var/log/hiveserver2.log
    exit 1
fi

echo "Starting Hue..."

echo "Preparing Hue database..."
rm -f /usr/share/hue/desktop.db
chown hue:hue /usr/share/hue/desktop.db 2>/dev/null || true

echo "Starting Hue..."
su -s /bin/bash hue -c "cd /usr/share/hue && ./startup.sh" &

echo "======================================"
echo "ALL SERVICES STARTED"
echo "======================================"

tail -f /dev/null