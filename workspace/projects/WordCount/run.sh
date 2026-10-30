#!/bin/bash
# ==============================================================================
# run.sh - Execution Script for WordCount MapReduce Application
# Sets up HDFS directories, uploads sample data, executes the job via YARN,
# and displays the resulting word counts from HDFS.
# ==============================================================================

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="WordCount"
MAIN_CLASS="com.bigdata.WordCount"
JAR_NAME="${APP_NAME}.jar"

# HDFS paths specific to this project
HDFS_INPUT_DIR="/wordcount/input"
HDFS_OUTPUT_DIR="/wordcount/output"

# Local input file
DEFAULT_LOCAL_INPUT="$SCRIPT_DIR/input/data.txt"
LOCAL_INPUT="${1:-$DEFAULT_LOCAL_INPUT}"

# Ensure Java & Hadoop environment variables if running in non-login shell
if [ -z "$JAVA_HOME" ] && [ -d "/usr/lib/jvm/java-8-openjdk-amd64" ]; then
    export JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64"
    export PATH="$JAVA_HOME/bin:$PATH"
fi

if [ -z "$HADOOP_HOME" ] && [ -d "/opt/hadoop" ]; then
    export HADOOP_HOME="/opt/hadoop"
    export PATH="$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$PATH"
fi

echo "=================================================================="
echo " Executing MapReduce Application: $APP_NAME"
echo "=================================================================="

# 1. Check whether Hadoop CLI is available
if ! command -v hadoop >/dev/null 2>&1; then
    echo "[ERROR] 'hadoop' command was not found in PATH." >&2
    echo "       This execution script must be run inside the hadoop-master container." >&2
    echo "       Usage: docker compose exec hadoop-master bash /workspace/projects/$APP_NAME/run.sh" >&2
    exit 1
fi

# 2. Locate the executable JAR
JAR_PATH=""
if [ -f "/workspace/jars/$JAR_NAME" ]; then
    JAR_PATH="/workspace/jars/$JAR_NAME"
elif [ -f "$SCRIPT_DIR/$JAR_NAME" ]; then
    JAR_PATH="$SCRIPT_DIR/$JAR_NAME"
elif [ -f "$SCRIPT_DIR/../../jars/$JAR_NAME" ]; then
    JAR_PATH="$SCRIPT_DIR/../../jars/$JAR_NAME"
fi

if [ -z "$JAR_PATH" ] || [ ! -f "$JAR_PATH" ]; then
    echo "[ERROR] Executable JAR '$JAR_NAME' not found!" >&2
    echo "       Please build the project first by running:" >&2
    echo "       bash $SCRIPT_DIR/build.sh" >&2
    exit 1
fi
echo "[OK] Found JAR: $JAR_PATH"

# 3. Check local input file
if [ ! -f "$LOCAL_INPUT" ]; then
    echo "[ERROR] Local input file '$LOCAL_INPUT' does not exist." >&2
    exit 1
fi
echo "[OK] Local Input File: $LOCAL_INPUT"
echo "[INFO] Input content:"
cat "$LOCAL_INPUT"
echo ""

# 4. Create the required HDFS input directory
echo "[INFO] Preparing HDFS input directory: $HDFS_INPUT_DIR"
hdfs dfs -mkdir -p "$HDFS_INPUT_DIR"

# 5. Upload sample input into HDFS
echo "[INFO] Uploading '$LOCAL_INPUT' to HDFS '$HDFS_INPUT_DIR/'..."
hdfs dfs -put -f "$LOCAL_INPUT" "$HDFS_INPUT_DIR/"

# 6. Safely handle existing HDFS output directory
# Hadoop MapReduce requires the output directory to NOT exist before execution.
# To prevent accidental data loss, ONLY remove the dedicated HDFS_OUTPUT_DIR.
if hdfs dfs -test -e "$HDFS_OUTPUT_DIR" 2>/dev/null; then
    echo "[INFO] Existing output directory found: $HDFS_OUTPUT_DIR"
    echo "[INFO] Safely removing ONLY the specific output directory for this job..."
    hdfs dfs -rm -r -f "$HDFS_OUTPUT_DIR"
fi

# 7. Execute the MapReduce job via `hadoop jar`
echo "[INFO] Submitting MapReduce job to YARN..."
echo "[CMD]  hadoop jar $JAR_PATH $MAIN_CLASS $HDFS_INPUT_DIR $HDFS_OUTPUT_DIR"
hadoop jar "$JAR_PATH" "$MAIN_CLASS" "$HDFS_INPUT_DIR" "$HDFS_OUTPUT_DIR"

if [ $? -ne 0 ]; then
    echo "[ERROR] MapReduce job execution failed." >&2
    exit 1
fi

# 8. Display generated output
echo ""
echo "=================================================================="
echo " [SUCCESS] MapReduce Job Finished Successfully!"
echo " Results from HDFS ($HDFS_OUTPUT_DIR):"
echo "=================================================================="
hdfs dfs -cat "$HDFS_OUTPUT_DIR/part-*"

# Also export copy to shared workspace output directory if available
if [ -d "/workspace/output" ]; then
    hdfs dfs -cat "$HDFS_OUTPUT_DIR/part-*" > "/workspace/output/wordcount-output.txt" 2>/dev/null || true
    echo "=================================================================="
    echo " Output also copied to host workspace: workspace/output/wordcount-output.txt"
fi
echo "=================================================================="
