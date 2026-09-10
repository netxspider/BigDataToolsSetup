# BigDataToolsSetup

BigDataToolsSetup is a Docker Compose environment for experimenting with a small,
single-node big-data stack. It places Hadoop HDFS, Hive, Hue, HBase, and Cassandra
on one Docker network so that the services can be started together and accessed
from the host machine.

## Architecture

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

The Compose service named `hadoop-master` is the main integration point. It runs
the Hadoop NameNode and DataNode, HiveServer2, and Hue in one container. HBase and
Cassandra run as separate containers and share the `int312` Docker network, which
lets containers resolve one another by service hostname.

### Request and storage paths

- Hadoop clients use `hdfs://hadoop-master:9000` as the default filesystem.
- The NameNode serves its web UI and WebHDFS on port `50070` inside the container.
- Hive stores managed tables under `hdfs://hadoop-master:9000/user/hive/warehouse`.
- HiveServer2 accepts Thrift connections on `hadoop-master:10000`.
- Hue connects to HDFS through WebHDFS and to Hive through HiveServer2.
- The HDFS NameNode directory is persisted in the named Docker volume `namenode`.
- The HDFS DataNode directory is persisted in the named Docker volume `datanode`.

This is a development and teaching topology, not a production cluster: HDFS
replication is set to `1`, there is one NameNode and one DataNode, and the local
Hive metastore uses embedded Derby.

## Components

### `hadoop-master`

The custom image is built from `gethue/hue:4.11.0`. The Dockerfile adds Java 8,
Hadoop `2.7.4`, Hive `2.3.2`, and the utilities needed by the startup script.
Configuration files are copied into the image during the build:

- `core-site.xml` sets the default HDFS URI and Hue proxy-user permissions.
- `hdfs-site.xml` defines the local NameNode and DataNode directories, disables
  HDFS permissions for development, enables WebHDFS, and sets replication to `1`.
- `hive-site.xml` points Hive at the HDFS warehouse and configures HiveServer2.
- `hue.ini` configures Hue on port `8888`, HDFS access, and the Hive interpreter.

### `hbase`

The service uses `harisekhon/hbase:latest`. Its HBase master and region server
ports are published for host access. No persistent volume is configured for this
service, so its data is tied to the container lifecycle.

### `cassandra`

The service uses Apache Cassandra `4.1` and publishes its native CQL port. No
persistent volume is configured for Cassandra in the current Compose file.

## Host ports

| Service | Host port | Container port | Purpose |
| --- | ---: | ---: | --- |
| Hadoop NameNode UI / WebHDFS | `9870` | `50070` | HDFS administration and WebHDFS |
| HDFS | `9000` | `9000` | Hadoop filesystem RPC |
| HiveServer2 | `10000` | `10000` | Hive Thrift endpoint |
| Hue | `8888` | `8888` | Browser-based Hadoop and Hive UI |
| HBase master UI | `16010` | `16010` | HBase administration |
| HBase master RPC | `16000` | `16000` | HBase client RPC |
| HBase region server | `16020` | `16020` | HBase region server |
| Cassandra CQL | `9042` | `9042` | Cassandra native protocol |

From the host, the main interfaces are:

- Hue: http://localhost:8888
- HDFS NameNode UI: http://localhost:9870
- HBase UI: http://localhost:16010
- HiveServer2: `localhost:10000`
- Cassandra: `localhost:9042`

From one container to another, use the Compose service names and container ports,
for example `hadoop-master:9000`, `hadoop-master:10000`, or `cassandra:9042`.

## Requirements

- Docker Desktop with Docker Compose v2
- A host that can run the `linux/amd64` images used by this project
- At least several gigabytes of free disk space for the Hadoop and Hive image layers
- Ports listed above available on the host

The Compose file explicitly requests `linux/amd64`. On Apple Silicon, Docker
Desktop may run these images through emulation, which can make the initial build
and startup slower.

## Quick start

Run these commands from the repository root:

```bash
docker compose build
docker compose up -d
docker compose ps
```

The first build downloads the Hadoop and Hive archives and may take several
minutes. The `hadoop-master` startup script then performs the following sequence:

1. Formats the NameNode only when `/hadoop/dfs/name/current` does not exist.
2. Starts the NameNode and DataNode and waits for HDFS to answer a filesystem
   listing request.
3. Creates `/tmp` and `/user/hive/warehouse` in HDFS and grants them development
   permissions.
4. Initializes the embedded Derby metastore when it has not been initialized.
5. Starts HiveServer2 and waits for port `10000` to accept connections.
6. Starts Hue and keeps the container process alive.

Check the startup logs with:

```bash
docker compose logs -f hadoop-master
```

The expected final startup message is `ALL SERVICES STARTED`. HBase and Cassandra
may still be completing their own initialization, so inspect their logs separately
when testing those services:

```bash
docker compose logs -f hbase
docker compose logs -f cassandra
```

## Using the stack

Open Hue at http://localhost:8888 after the `hadoop-master` container reports that
all services have started. Inside the Compose network, Hive clients should use:

```text
Host: hadoop-master
Port: 10000
Transport: binary Thrift
```

Basic HDFS checks can be run directly in the container:

```bash
docker compose exec hadoop-master hdfs dfs -ls /
docker compose exec hadoop-master hdfs dfs -ls /user/hive/warehouse
```

For a Hive shell, open a shell in the container and invoke Beeline against
HiveServer2:

```bash
docker compose exec hadoop-master beeline -u 'jdbc:hive2://localhost:10000/default'
```

Cassandra can be checked with:

```bash
docker compose exec cassandra cqlsh
```

HBase clients inside the network should use `hbase` as the hostname. The exact
client command depends on the HBase client being used and the image defaults.

## Lifecycle and data management

Stop the services without removing containers:

```bash
docker compose stop
```

Start them again:

```bash
docker compose start
```

Stop and remove the containers and network:

```bash
docker compose down
```

Remove the HDFS named volumes as well when a completely fresh HDFS namespace is
needed:

```bash
docker compose down -v
```

The `namenode` and `datanode` volumes are the durable part of the current setup.
The embedded Hive Derby metastore is stored under `/opt/hive-data` inside the
`hadoop-master` container and is not mounted as a named volume. Hue deletes and
recreates `/usr/share/hue/desktop.db` on every startup. As a result, Hive metadata
and Hue settings should be treated as disposable unless the image or Compose file
is extended with persistent volumes.

## Repository layout

```text
.
├── docker-compose.yml          # Service definitions, ports, network, and volumes
├── README.md                   # Architecture and operating guide
└── hadoop-master/
    ├── Dockerfile              # Builds the combined Hadoop, Hive, and Hue image
    ├── start.sh                # Initializes and starts services in dependency order
    ├── core-site.xml           # Core Hadoop and proxy-user settings
    ├── hdfs-site.xml           # NameNode, DataNode, WebHDFS, and HDFS settings
    ├── hive-site.xml           # Hive warehouse, metastore, and HiveServer2 settings
    └── hue.ini                 # Hue web, HDFS, and Hive integration settings
```

## Troubleshooting

### `hadoop-master` exits during startup

Inspect the container logs and the service-specific log files:

```bash
docker compose logs hadoop-master
docker compose exec hadoop-master sh -c 'cat /var/log/namenode.log; cat /var/log/datanode.log; cat /var/log/hiveserver2.log'
```

Common causes are insufficient Docker resources, a port already in use, or a
stale HDFS volume containing an incomplete initialization. If the HDFS volume can
be discarded, run `docker compose down -v` and start again.

### Hue opens but cannot browse HDFS

Confirm that HDFS is ready and that WebHDFS is reachable from the `hadoop-master`
container. The configured endpoint is
`http://hadoop-master:50070/webhdfs/v1`. Also verify the NameNode and DataNode
logs before restarting Hue.

### HiveServer2 is unavailable

Check `/var/log/hiveserver2.log` and confirm that port `10000` is listening inside
the container. The current setup uses an embedded Derby metastore, which is
intended for a single HiveServer2 process and local development.

## Security and production limitations

This repository is intentionally configured for local coursework and development:

- HDFS permissions are disabled and several directories are world-writable.
- Hue uses a placeholder `secret_key` in `hue.ini`; replace it before any shared
  or internet-accessible deployment.
- Services expose administrative and data ports directly on the host.
- HBase uses the `latest` image tag, so rebuilds can change its runtime version.
- HDFS has replication factor `1` and no failover.
- Hive uses embedded Derby rather than a production metastore database.
- HBase and Cassandra have no Compose-managed persistent volumes.

For production use, separate the services into appropriately scaled containers,
pin every image version, add authentication and network restrictions, use durable
storage for every data service, and configure external metadata databases and
backups.

## Cleanup

To remove all project containers, the network, and the HDFS volumes:

```bash
docker compose down -v --remove-orphans
```

This permanently deletes the data stored in the `namenode` and `datanode` named
volumes.