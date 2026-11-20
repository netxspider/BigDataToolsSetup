# Armstrong Number Identifier (Hadoop MapReduce)

A production-ready Apache Hadoop MapReduce application in Java that identifies and classifies numbers as **Armstrong Numbers** or **Not Armstrong Numbers**.

---

## 📌 What is an Armstrong Number?

An **Armstrong number** (also called a **narcissistic number**) of $n$ digits is an integer equal to the sum of its digits each raised to the power of $n$:

$$\text{Armstrong Number: } N = \sum_{i=1}^n d_i^n$$

### Examples:
- **$153$** ($3$ digits): $1^3 + 5^3 + 3^3 = 1 + 125 + 27 = 153$ ✅
- **$370$** ($3$ digits): $3^3 + 7^3 + 0^3 = 27 + 343 + 0 = 370$ ✅
- **$371$** ($3$ digits): $3^3 + 7^3 + 1^3 = 27 + 343 + 1 = 371$ ✅
- **$407$** ($3$ digits): $4^3 + 0^3 + 7^3 = 64 + 0 + 343 = 407$ ✅
- **$1634$** ($4$ digits): $1^4 + 6^4 + 3^4 + 4^4 = 1 + 1296 + 81 + 256 = 1634$ ✅
- **$8208$** ($4$ digits): $8^4 + 2^4 + 0^4 + 8^4 = 4096 + 16 + 0 + 4096 = 8208$ ✅
- **$123$** ($3$ digits): $1^3 + 2^3 + 3^3 = 1 + 8 + 27 = 36 \neq 123$ ❌

---

## 📁 Project Structure

```
ArmstrongNumber/
├── build.sh                                    # Compiles Java code & packages ArmstrongNumber.jar
├── run.sh                                      # Uploads input to HDFS, submits job, and displays output
├── README.md                                   # Documentation & instructions
├── input/
│   └── data.txt                                # 10 sample input numbers
└── src/
    └── com/
        └── bigdata/
            └── ArmstrongNumber.java            # MapReduce Driver, Mapper, & Reducer
```

---

## ⚙️ How It Works (MapReduce Architecture)

1. **Input Phase**:
   - `TextInputFormat` reads the input file `data.txt` line by line from HDFS.
2. **Map Phase (`ArmstrongMapper`)**:
   - Parses each number from the input lines using `StringTokenizer`.
   - Computes the number of digits $n$ and calculates $\sum d^n$.
   - If sum equals the original number, emits `(num, "Armstrong Number")`.
   - Otherwise, emits `(num, "Not Armstrong Number")`.
3. **Shuffle & Sort Phase**:
   - Hadoop partitions and sorts keys numerically in ascending order using `LongWritable`.
4. **Reduce Phase (`ArmstrongReducer`)**:
   - Writes the sorted key-value pairs directly to HDFS output directory.

---

## 🚀 How to Build and Run

### 1. Build the JAR
From your host terminal:
```bash
docker exec hadoop-master bash /workspace/projects/ArmstrongNumber/build.sh
```

### 2. Run the MapReduce Job
```bash
docker exec hadoop-master bash /workspace/projects/ArmstrongNumber/run.sh
```

### 3. View Results from HDFS
```bash
docker exec hadoop-master hdfs dfs -cat /armstrong/output/part-*
```

