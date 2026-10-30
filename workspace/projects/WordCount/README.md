# WordCount MapReduce Project

A complete, production-ready Java MapReduce application running on Hadoop 2.7.4 with YARN inside Docker.

## Project Structure

```text
WordCount/
├── src/
│   └── com/
│       └── bigdata/
│           └── WordCount.java   # Mapper, Reducer, and Driver implementation
├── classes/                     # Compiled bytecode (.class files)
├── input/
│   └── data.txt                 # Sample test dataset
├── build.sh                     # Compilation & JAR packaging script
├── run.sh                       # HDFS upload & YARN execution script
└── README.md                    # Project documentation
```

## How It Works

1. **Mapper (`TokenizerMapper`)**:
   - Reads lines of text from HDFS.
   - Normalizes non-alphanumeric punctuation.
   - Emits intermediate key-value pairs: `<Text word, IntWritable 1>`.

2. **Combiner (`IntSumReducer`)**:
   - Performs map-side pre-aggregation to minimize network shuffle overhead.

3. **Reducer (`IntSumReducer`)**:
   - Groups occurrences by word key.
   - Calculates the sum of counts.
   - Emits final output: `<Text word, IntWritable count>`.

## Quick Start

### 1. Build the JAR
From your macOS terminal in the project root:
```bash
docker compose exec hadoop-master bash /workspace/projects/WordCount/build.sh
```
*What this does:*
- Locates OpenJDK 8 and Hadoop inside `hadoop-master`.
- Resolves Hadoop libraries using `hadoop classpath`.
- Compiles Java source with `-source 1.8 -target 1.8`.
- Creates `WordCount.jar` and places it in `/workspace/jars/WordCount.jar`.

### 2. Run the Job
```bash
docker compose exec hadoop-master bash /workspace/projects/WordCount/run.sh
```
*What this does:*
- Checks for `/workspace/jars/WordCount.jar`.
- Creates HDFS directory `/wordcount/input`.
- Uploads `data.txt` to HDFS.
- Cleans any existing `/wordcount/output` directory safely.
- Submits the job to YARN.
- Displays the output from `/wordcount/output/part-*`.
- Saves a copy to `workspace/output/wordcount-output.txt` on your host machine.

### 3. View Results Directly from HDFS
```bash
docker compose exec hadoop-master hdfs dfs -cat /wordcount/output/part-r-00000
```

### 4. Run with Custom Input
You can provide any local file path inside the workspace:
```bash
docker compose exec hadoop-master bash /workspace/projects/WordCount/run.sh /workspace/input/custom.txt
```

## Expected Output for Sample Data

Sample input:
```text
Hello Hadoop Hello MapReduce Big Data Hadoop
```

Expected output:
```text
Big	1
Data	1
Hadoop	2
Hello	2
MapReduce	1
```
