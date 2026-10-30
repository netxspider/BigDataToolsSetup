#!/bin/bash
# ==============================================================================
# run.sh - Generalized MapReduce Execution Script
#
# Usage:
#   bash run.sh [MAIN_CLASS] [APP_NAME] [HDFS_INPUT] [HDFS_OUTPUT] [LOCAL_INPUT]
#
# Examples:
#   # Run with defaults:
#   bash run.sh
#
#   # Run with explicit parameters:
#   bash run.sh com.bigdata.MatrixMultiplication MatrixMultiplication /matrix/input /matrix/output
# ==============================================================================

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Configurable defaults
DEFAULT_APP_NAME="$(basename "$SCRIPT_DIR")"
if [ "$DEFAULT_APP_NAME" = "java-mapreduce" ]; then
    DEFAULT_APP_NAME="MyMapReduceApp"
fi

MAIN_CLASS="${1:-${MAIN_CLASS:-com.bigdata.Main}}"
APP_NAME="${2:-${APP_NAME:-$DEFAULT_APP_NAME}}"
APP_NAME_LOWER="$(echo "$APP_NAME" | tr '[:upper:]' '[:lower:]')"

HDFS_INPUT_DIR="${3:-${HDFS_INPUT_PATH:-/$APP_NAME_LOWER/input}}"
HDFS_OUTPUT_DIR="${4:-${HDFS_OUTPUT_PATH:-/$APP_NAME_LOWER/output}}"

JAR_NAME="${APP_NAME}.jar"

# Local input file
DEFAULT_LOCAL_INPUT="$SCRIPT_DIR/input/data.txt"
if [ ! -f "$DEFAULT_LOCAL_INPUT" ] && [ -f "$SCRIPT_DIR/input/input.txt" ]; then
    DEFAULT_LOCAL_INPUT="$SCRIPT_DIR/input/input.txt"
fi
LOCAL_INPUT="${5:-${LOCAL_INPUT_FILE:-$DEFAULT_LOCAL_INPUT}}"

# Ensure Java & Hadoop in PATH
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
echo " Main Class:  $MAIN_CLASS"
echo " JAR:         $JAR_NAME"
echo " HDFS Input:  $HDFS_INPUT_DIR"
echo " HDFS Output: $HDFS_OUTPUT_DIR"
echo "=================================================================="

# 1. Check Hadoop CLI
if ! command -v hadoop >/dev/null 2>&1; then
    echo "[ERROR] 'hadoop' command was not found in PATH." >&2
    echo "       Please run this script inside the hadoop-master container:" >&2
    echo "       docker compose exec hadoop-master bash /workspace/.../run.sh" >&2
    exit 1
fi

# 2. Find JAR
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
    echo "       Please build the project first:" >&2
    echo "       bash $SCRIPT_DIR/build.sh $APP_NAME" >&2
    exit 1
fi
echo "[OK] Found JAR: $JAR_PATH"

# 3. Handle local input file if provided
if [ -f "$LOCAL_INPUT" ]; then
    echo "[INFO] Uploading local input '$LOCAL_INPUT' to HDFS '$HDFS_INPUT_DIR/'..."
    hdfs dfs -mkdir -p "$HDFS_INPUT_DIR"
    hdfs dfs -put -f "$LOCAL_INPUT" "$HDFS_INPUT_DIR/"
else
    # Check if HDFS input already has data
    if ! hdfs dfs -test -e "$HDFS_INPUT_DIR" 2>/dev/null; then
        echo "[ERROR] HDFS input path '$HDFS_INPUT_DIR' does not exist and no local input file was found." >&2
        exit 1
    fi
    echo "[INFO] Using existing HDFS input directory: $HDFS_INPUT_DIR"
fi

# 4. Safely remove ONLY the specific job output directory if it exists
if hdfs dfs -test -e "$HDFS_OUTPUT_DIR" 2>/dev/null; then
    echo "[INFO] Removing existing specific job output directory: $HDFS_OUTPUT_DIR"
    hdfs dfs -rm -r -f "$HDFS_OUTPUT_DIR"
fi

# 5. Execute job
echo "[INFO] Submitting MapReduce job to YARN..."
echo "[CMD]  hadoop jar $JAR_PATH $MAIN_CLASS $HDFS_INPUT_DIR $HDFS_OUTPUT_DIR"
hadoop jar "$JAR_PATH" "$MAIN_CLASS" "$HDFS_INPUT_DIR" "$HDFS_OUTPUT_DIR"

if [ $? -ne 0 ]; then
    echo "[ERROR] Job execution failed." >&2
    exit 1
fi

# 6. Display results
echo ""
echo "=================================================================="
echo " [SUCCESS] Job finished successfully!"
echo " Results from $HDFS_OUTPUT_DIR:"
echo "=================================================================="
hdfs dfs -cat "$HDFS_OUTPUT_DIR/part-*"

if [ -d "/workspace/output" ]; then
    hdfs dfs -cat "$HDFS_OUTPUT_DIR/part-*" > "/workspace/output/${APP_NAME_LOWER}-output.txt" 2>/dev/null || true
    echo "=================================================================="
    echo " Output copied to workspace/output/${APP_NAME_LOWER}-output.txt"
fi
echo "=================================================================="
