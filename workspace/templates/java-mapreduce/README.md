# Reusable Java MapReduce Project Template

This template provides a standardized starting point for creating new MapReduce assignments and projects without re-writing build scripts or HDFS management logic.

## Directory Structure

```text
java-mapreduce/
├── src/
│   └── com/
│       └── bigdata/
│           └── Main.java       # Boilerplate Mapper, Reducer, and Driver
├── classes/                     # Output directory for compiled .class files
├── input/                       # Local directory for test input files
├── build.sh                     # Generalized build & JAR packaging script
├── run.sh                       # Generalized HDFS upload & execution script
└── README.md                    # Template usage instructions
```

## How to Create a New Assignment

### Step 1: Copy the Template
To create a new project (for example, `MatrixMultiplication` or `Sorting`), copy the template directory into `workspace/projects/`:

```bash
# Example for MatrixMultiplication
cp -r workspace/templates/java-mapreduce workspace/projects/MatrixMultiplication

# Example for Sorting
cp -r workspace/templates/java-mapreduce workspace/projects/Sorting
```

### Step 2: Implement Your Logic
1. Open `workspace/projects/<YourProject>/src/com/bigdata/` in VS Code or IntelliJ.
2. Edit `Main.java` (or rename the class, e.g. `MatrixMultiplication.java`).
3. Implement your custom `Mapper` and `Reducer` logic.
4. Place sample test input data in `workspace/projects/<YourProject>/input/data.txt`.

### Step 3: Build the JAR
From your host terminal:
```bash
docker compose exec hadoop-master bash /workspace/projects/<YourProject>/build.sh
```

To specify a custom JAR name:
```bash
docker compose exec hadoop-master bash /workspace/projects/<YourProject>/build.sh <YourProject>
```

The resulting JAR will be created at:
- `workspace/projects/<YourProject>/<YourProject>.jar`
- `workspace/jars/<YourProject>.jar`

### Step 4: Run the MapReduce Job
```bash
docker compose exec hadoop-master bash /workspace/projects/<YourProject>/run.sh
```

To specify custom parameters explicitly:
```bash
docker compose exec hadoop-master bash /workspace/projects/<YourProject>/run.sh \
  <MainClass> \
  <AppName> \
  <HdfsInputPath> \
  <HdfsOutputPath> \
  <LocalInputPath>
```
Example:
```bash
docker compose exec hadoop-master bash /workspace/projects/MatrixMultiplication/run.sh \
  com.bigdata.MatrixMultiplication \
  MatrixMultiplication \
  /matrix/input \
  /matrix/output \
  /workspace/projects/MatrixMultiplication/input/data.txt
```

### Step 5: View Output
Results will be displayed automatically in your terminal, and can also be queried directly from HDFS:
```bash
docker compose exec hadoop-master hdfs dfs -cat /<appname>/output/part-*
```
Copies are also saved to `workspace/output/<appname>-output.txt` for easy host inspection.
