#!/bin/bash
# ==============================================================================
# build.sh - Build Script for WordCount MapReduce Application
# Compiles Java MapReduce source and packages into an executable JAR.
# Can be run inside the hadoop-master container or via docker compose exec.
# ==============================================================================

set -eo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="WordCount"
SRC_DIR="$SCRIPT_DIR/src"
CLASSES_DIR="$SCRIPT_DIR/classes"
JAR_NAME="${APP_NAME}.jar"
PROJECT_JAR="$SCRIPT_DIR/$JAR_NAME"

# Locate shared workspace jars folder
if [ -d "/workspace/jars" ]; then
    SHARED_JARS_DIR="/workspace/jars"
else
    SHARED_JARS_DIR="$(cd "$SCRIPT_DIR/../../jars" 2>/dev/null && pwd || echo "$SCRIPT_DIR/jars")"
fi

echo "=================================================================="
echo " Building MapReduce Application: $APP_NAME"
echo "=================================================================="

# Ensure Java environment variables if running in non-login shell
if [ -z "$JAVA_HOME" ] && [ -d "/usr/lib/jvm/java-8-openjdk-amd64" ]; then
    export JAVA_HOME="/usr/lib/jvm/java-8-openjdk-amd64"
    export PATH="$JAVA_HOME/bin:$PATH"
fi

if [ -z "$HADOOP_HOME" ] && [ -d "/opt/hadoop" ]; then
    export HADOOP_HOME="/opt/hadoop"
    export PATH="$HADOOP_HOME/bin:$HADOOP_HOME/sbin:$PATH"
fi

# 1. Check whether Java compiler (javac) is available
if ! command -v javac >/dev/null 2>&1; then
    echo "[ERROR] 'javac' (Java compiler) was not found in PATH." >&2
    echo "       Please ensure Java JDK 8 is installed and JAVA_HOME is configured." >&2
    exit 1
fi
echo "[OK] Java Compiler: $(javac -version 2>&1)"

# 2. Check whether Hadoop CLI is available
if ! command -v hadoop >/dev/null 2>&1; then
    echo "[ERROR] 'hadoop' command was not found in PATH." >&2
    echo "       This build script should be executed inside the hadoop-master container." >&2
    echo "       Usage: docker compose exec hadoop-master bash /workspace/projects/$APP_NAME/build.sh" >&2
    exit 1
fi
echo "[OK] Hadoop Version: $(hadoop version | head -n 1)"

# 3. Retrieve Hadoop dependencies using `hadoop classpath`
echo "[INFO] Resolving Hadoop classpath..."
HADOOP_CLASSPATH="$(hadoop classpath)"
if [ -z "$HADOOP_CLASSPATH" ]; then
    echo "[ERROR] Failed to retrieve Hadoop classpath via 'hadoop classpath'." >&2
    exit 1
fi

# 4. Clean previous classes and prepare classes directory
echo "[INFO] Cleaning previous compilation outputs..."
rm -rf "$CLASSES_DIR"/*
mkdir -p "$CLASSES_DIR"

# 5. Compile the Java source files
echo "[INFO] Compiling Java source files (Java 8 target)..."
JAVA_FILES=$(find "$SRC_DIR" -name "*.java")
if [ -z "$JAVA_FILES" ]; then
    echo "[ERROR] No Java source files found in $SRC_DIR" >&2
    exit 1
fi

javac -source 1.8 -target 1.8 -classpath "$HADOOP_CLASSPATH" -d "$CLASSES_DIR" $JAVA_FILES
if [ $? -ne 0 ]; then
    echo "[ERROR] Java compilation failed." >&2
    exit 1
fi
echo "[OK] Compilation succeeded."

# 6. Package compiled classes into a JAR
echo "[INFO] Packaging compiled classes into $JAR_NAME..."
mkdir -p "$SHARED_JARS_DIR"
jar -cvf "$PROJECT_JAR" -C "$CLASSES_DIR" .
if [ $? -ne 0 ]; then
    echo "[ERROR] Failed to create JAR file." >&2
    exit 1
fi

# 7. Place copy in shared workspace jars/ directory
cp -f "$PROJECT_JAR" "$SHARED_JARS_DIR/$JAR_NAME"

echo "=================================================================="
echo " [SUCCESS] Build completed successfully!"
echo "  - Project JAR: $PROJECT_JAR"
echo "  - Shared JAR:  $SHARED_JARS_DIR/$JAR_NAME"
echo "=================================================================="
