# BigDataToolsSetup

BigDataToolsSetup is a Docker Compose environment for experimenting with a unified, single-node big data stack. It runs **Hadoop (HDFS & YARN)**, **Hive**, **Hue**, **HBase**, and **Cassandra** on a shared Docker network (`int312`) so all services can be started together and accessed easily from your host machine.

---

> [!WARNING]
> ### ⚠️ Critical Network Notice: Use Personal Internet / Mobile Hotspot
> **Do NOT use college or campus Wi-Fi when building or pulling images.**
> College and institutional networks frequently block or heavily throttle Docker Hub image pulls, Debian package repositories (`apt-get update`), and Apache software distribution archives (`archive.apache.org/dist/...`).
> 
> * **Symptom:** `docker compose build` hangs indefinitely on `apt-get` or downloading Hadoop/Hive tarballs, or connection timeout errors occur.
> * **Fix:** Disconnect from campus Wi-Fi and connect via a **personal mobile hotspot** or unrestricted home network before running `docker compose build` or `docker compose up`.

---

## ⚡ Quick Start

### 1. Prerequisites
- [Docker Desktop](https://www.docker.com/products/docker-desktop/) with Docker Compose v2 installed and running.
- At least **8 GB RAM** allocated to Docker Desktop (recommended for running Hadoop, HBase, and Cassandra concurrently).
- ~10 GB free disk space for image layers and volumes.
- *Note for Apple Silicon (M1/M2/M3/M4 Macs):* The project uses `platform: linux/amd64`. Docker Desktop handles emulation automatically; the initial build and startup may take a few extra minutes.

### 2. Start the Stack

Run the following commands from the project root directory:

```bash
# 1. Build the hadoop-master image (downloads Hadoop 2.7.4 & Hive 2.3.2)
docker compose build

# 2. Start all services in the background
docker compose up -d

# 3. Check container running status
docker compose ps
```

### 3. Service Web UIs & Host Ports

Once containers are running and initialized, access the services via your browser:

| Service | Web UI / Endpoint | Host Port | Purpose |
| :--- | :--- | :---: | :--- |
| **Hue Dashboard** | [http://localhost:8888](http://localhost:8888) | `8888` | Web interface for querying Hive & browsing HDFS |
| **Hadoop NameNode UI** | [http://localhost:9870](http://localhost:9870) | `9870` | HDFS cluster health, file browser, & WebHDFS |
| **YARN ResourceManager** | [http://localhost:8088](http://localhost:8088) | `8088` | YARN applications, scheduler, & cluster metrics |
| **HBase Master UI** | [http://localhost:16010](http://localhost:16010) | `16010` | HBase tables, region servers, & system status |
| **HiveServer2** | `localhost:10000` | `10000` | JDBC/ODBC Thrift endpoint for Hive clients |
| **Cassandra CQL** | `localhost:9042` | `9042` | Native binary protocol port for Cassandra/CQL |

> [!NOTE]
> On first login to **Hue** ([http://localhost:8888](http://localhost:8888)), create any username and password (e.g., `admin` / `admin`). The first account created automatically becomes the administrator account.

---

## 🐚 Shell Access Guide

This guide details how to enter the interactive command-line environments for Hadoop/HDFS, Hive, HBase, and Cassandra.

### 1. Hadoop & HDFS Shell

You can interact with Hadoop either by executing commands directly from the host or by dropping into an interactive bash shell inside the `hadoop-master` container.

#### Option A: Enter Container Bash Shell
To enter the container with all environment variables (`JAVA_HOME`, `HADOOP_HOME`, `HIVE_HOME`) pre-configured:
```bash
docker compose exec -it hadoop-master bash
```

#### Option B: HDFS CLI Commands
Run commands directly from your host terminal:
```bash
# List root directory of HDFS
docker compose exec hadoop-master hdfs dfs -ls /

# List Hive warehouse directory
docker compose exec hadoop-master hdfs dfs -ls /user/hive/warehouse

# Create a new directory in HDFS
docker compose exec hadoop-master hdfs dfs -mkdir -p /user/test

# Upload a local file into HDFS
docker compose exec hadoop-master hdfs dfs -put /path/to/local/file /user/test/

# View file content in HDFS
docker compose exec hadoop-master hdfs dfs -cat /user/test/file

# Check HDFS disk and block health
docker compose exec hadoop-master hdfs dfsadmin -report
```

#### Option C: Hive Shell (Beeline / Hive CLI)
Connect to HiveServer2 using the standard **Beeline** client:
```bash
docker compose exec -it hadoop-master beeline -u 'jdbc:hive2://localhost:10000/default'
```
*Or use the classic Hive CLI:*
```bash
docker compose exec -it hadoop-master hive
```
*Sample Hive queries to test:*
```sql
SHOW DATABASES;
CREATE TABLE sample_data (id INT, name STRING);
INSERT INTO sample_data VALUES (1, 'BigData');
SELECT * FROM sample_data;
```

---

### 2. HBase Shell

The HBase container runs standalone HBase with built-in ZooKeeper.

#### Waiting for HBase Readiness
Before entering the shell, confirm that HBase has completed initialization:
```bash
docker compose logs -f hbase
```
Wait until you see that the Master and RegionServer have bound their ports.

#### Enter HBase Shell Directly
```bash
docker compose exec -it hbase hbase shell
```

*Or enter container bash first, then start the shell:*
```bash
docker compose exec -it hbase bash
# Inside container:
hbase shell
```

#### Common HBase Commands to Test:
```ruby
# Check cluster status and version
status
version

# List existing tables
list

# Create a table with column family 'cf'
create 'students', 'cf'

# Insert records (put 'table', 'rowid', 'family:column', 'value')
put 'students', 'row1', 'cf:name', 'Alice'
put 'students', 'row1', 'cf:grade', 'A'
put 'students', 'row2', 'cf:name', 'Bob'
put 'students', 'row2', 'cf:grade', 'B'

# Retrieve a single row
get 'students', 'row1'

# Scan entire table
scan 'students'

# Exit the HBase shell
exit
```

---

### 3. Cassandra Shell (`cqlsh`)

The Cassandra service runs Apache Cassandra 4.1.

#### Waiting for Cassandra Readiness
Cassandra typically takes 30–60 seconds to start the gossip protocol and bind native transports. Verify its state:
```bash
docker compose logs -f cassandra
```
Look for the log message: `Startup complete` or `Created default superuser role 'cassandra'`.

#### Enter Cassandra CQL Shell Directly
```bash
docker compose exec -it cassandra cqlsh
```

*Or enter container bash first:*
```bash
docker compose exec -it cassandra bash
# Inside container:
cqlsh
```

#### Common CQL Commands to Test:
```sql
-- Check cluster info and available keyspaces
DESCRIBE CLUSTER;
DESCRIBE KEYSPACES;

-- Create a test keyspace
CREATE KEYSPACE my_keyspace WITH replication = {
  'class': 'SimpleStrategy',
  'replication_factor': 1
};

-- Use keyspace and create a table
USE my_keyspace;

CREATE TABLE users (
  user_id UUID PRIMARY KEY,
  username text,
  email text
);

-- Insert data
INSERT INTO users (user_id, username, email) 
VALUES (uuid(), 'john_doe', 'john@example.com');

-- Query data
SELECT * FROM users;

-- Exit cqlsh
exit;
```

---

## 📜 Startup Logs & Service Verification

Each service initializes in a specific order. Monitoring the logs allows you to verify healthy operation.

### 1. Following Startup Logs

```bash
# View hadoop-master startup logs (HDFS, YARN, Hive, Hue)
docker compose logs -f hadoop-master

# View HBase logs
docker compose logs -f hbase

# View Cassandra logs
docker compose logs -f cassandra
```

### 2. Expected `hadoop-master` Startup Flow

The `hadoop-master` container executes `start.sh`, performing sequential health checks before proceeding:

1. **NameNode Formatting:** Checks `/hadoop/dfs/name/current`. If not found, formats HDFS with `hdfs namenode -format -force`.
2. **HDFS Daemons:** Starts NameNode, DataNode, and SecondaryNameNode in the background, polling `hdfs dfs -ls /` until ready.
3. **YARN Daemons:** Starts ResourceManager and NodeManager, polling port `8088` with netcat (`nc -z`) until ready.
4. **HDFS Directories:** Creates and sets `777` permissions on `/tmp` and `/user/hive/warehouse`.
5. **Hive Derby Metastore:** Initializes the Derby schema using `schematool -dbType derby -initSchema` if not already present.
6. **HiveServer2:** Starts HiveServer2 and polls Thrift port `10000` until listening.
7. **Hue:** Prepares `/opt/hue-data` and starts the Hue server under the `hue` user.
8. **Final Message:**
   ```text
   ======================================
   ALL SERVICES STARTED
   ======================================
   ```

### 3. Detailed Component Log Files

If any daemon inside `hadoop-master` fails to start, inspect its specific log file:

```bash
docker compose exec hadoop-master cat /var/log/namenode.log
docker compose exec hadoop-master cat /var/log/datanode.log
docker compose exec hadoop-master cat /var/log/secondarynamenode.log
docker compose exec hadoop-master cat /var/log/resourcemanager.log
docker compose exec hadoop-master cat /var/log/nodemanager.log
docker compose exec hadoop-master cat /var/log/hiveserver2.log
```

---

## 🏗️ Architecture & Stack Details

```text
                         INT312 network
                               |
           +-------------------+-------------------+
           |                   |                   |
           v                   v                   v
     hadoop-master           hbase              cassandra
           |
       +---+---------+
       |             |
       v             v
      HDFS          HiveServer2
       |             |
       |             v
       |           Hue
       |
       +-- /data
           /user/hive/warehouse
```

### Request & Storage Paths

- **Network:** All containers reside on the custom Docker bridge network `int312`, allowing hostname resolution (e.g. `hadoop-master`, `hbase`, `cassandra`).
- **HDFS Default Filesystem:** Clients use `hdfs://hadoop-master:9000`.
- **NameNode Web UI & WebHDFS:** Port `50070` mapped to host port `9870`.
- **YARN ResourceManager:** Web UI on port `8088`, scheduler on port `8032`.
- **Hive Metastore & Warehouse:** Stored at `hdfs://hadoop-master:9000/user/hive/warehouse` with metadata in embedded Apache Derby at `/opt/hive-data/metastore_db`.
- **HiveServer2:** Accepts Thrift connections on port `10000`.
- **Hue:** Web console running on port `8888`, connecting to HDFS via WebHDFS and Hive via HiveServer2.
- **Persistent Docker Volumes:**
  - `namenode` -> `/hadoop/dfs/name`
  - `datanode` -> `/hadoop/dfs/data`
  - `secondarynamenode` -> `/hadoop/dfs/secondary`
  - `huedata` -> `/opt/hue-data` (persists Hue sqlite database across restarts)

---

## 📦 Components Breakdown

### 1. `hadoop-master`
- Built from base image `gethue/hue:4.11.0`.
- Installs OpenJDK 8, Hadoop 2.7.4, and Apache Hive 2.3.2.
- Preconfigures XML configuration files:
  - `core-site.xml`: HDFS URI and Hue proxyuser authorization.
  - `hdfs-site.xml`: Replication set to 1, WebHDFS enabled, permissions disabled for development.
  - `yarn-site.xml`: ResourceManager & NodeManager configuration, memory limit set to 4096 MB.
  - `mapred-site.xml`: Configures MapReduce on YARN.
  - `hive-site.xml`: HDFS warehouse directory and Thrift bind configuration.
  - `hue.ini`: Web UI settings and connectors for HDFS and Hive.

### 2. `hbase`
- Runs `harisekhon/hbase:latest`.
- Self-contained HBase Master, RegionServer, and ZooKeeper.
- Exposes port `16010` (Web UI), `16000` (Master RPC), and `16020` (RegionServer).

### 3. `cassandra`
- Runs official `cassandra:4.1`.
- Exposes native CQL binary protocol port `9042`.

---

## 🔄 Lifecycle & Data Management

### Pause / Stop Services
Stop containers without deleting state:
```bash
docker compose stop
```

Resume containers:
```bash
docker compose start
```

### Stop & Remove Containers
Stop and remove containers and the virtual network (volumes are preserved):
```bash
docker compose down
```

### Reset All Data (Clean Slate)
To wipe all stored data (HDFS filesystem, Hue users/queries, database volumes) and start completely fresh:
```bash
docker compose down -v
```

> [!CAUTION]
> Running `docker compose down -v` permanently removes the `namenode`, `datanode`, `secondarynamenode`, and `huedata` volumes.

---

## 📁 Repository Layout

```text
.
├── docker-compose.yml          # Service definitions, ports, network, and volumes
├── README.md                   # Architecture, quick start, and operation guide
└── hadoop-master/
    ├── Dockerfile              # Builds the combined Hadoop, Hive, and Hue image
    ├── start.sh                # Initializes and starts services in dependency order
    ├── core-site.xml           # Core Hadoop and proxy-user settings
    ├── hdfs-site.xml           # HDFS and SecondaryNameNode settings
    ├── yarn-site.xml           # ResourceManager and NodeManager settings
    ├── mapred-site.xml         # MapReduce-on-YARN settings
    ├── hive-site.xml           # Hive warehouse, metastore, and HiveServer2 settings
    └── hue.ini                 # Hue web, HDFS, and Hive integration settings
```

---

## 🔧 Troubleshooting

### 1. Build Fails or Hangs on `apt-get` or Apache Download
- **Cause:** Restricted institutional / college Wi-Fi blocking outbound ports or rate-limiting archive downloads.
- **Solution:** Switch to your **mobile hotspot** or personal home Wi-Fi and rerun `docker compose build --no-cache`.

### 2. `hadoop-master` Exits Prematurely
- Check the log output:
  ```bash
  docker compose logs hadoop-master
  ```
- Check internal daemon logs:
  ```bash
  docker compose exec hadoop-master cat /var/log/namenode.log
  ```
- If NameNode reports an inconsistent cluster ID or corrupt image due to interrupted initialization, clean up volumes:
  ```bash
  docker compose down -v
  docker compose up -d
  ```

### 3. Cassandra Connection Refused with `cqlsh`
- **Cause:** Cassandra is still in its startup phase and has not started listening on port 9042 yet.
- **Solution:** Run `docker compose logs -f cassandra` and wait until `Startup complete` is displayed before running `docker compose exec -it cassandra cqlsh`.

### 4. HiveServer2 Fails to Start
- Inspect `/var/log/hiveserver2.log`.
- Because Hive uses an embedded Apache Derby metastore, only one process can access `/opt/hive-data/metastore_db` at any given time. Ensure no other metastore process or lock file is active.

---

## ⚠️ Academic & Development Limitations

This stack is tailored for academic coursework and local lab assignments:
- **HDFS Replication Factor = 1:** Suitable for a single node; no high availability.
- **Embedded Derby Metastore:** Suitable for single-user development; concurrent HiveServer2 instances are not supported.
- **Security & Auth:** HDFS permissions are disabled, Hue uses a development secret key, and administrative ports are exposed directly to `localhost`.
- **Container Lifecycles:** HBase and Cassandra data are stored inside the container layers in the default Compose setup; use named volumes if long-term persistence is needed.

---

## 🧹 Complete Cleanup

To remove all project containers, dangling images, network interfaces, and volumes:

```bash
docker compose down -v --remove-orphans
```