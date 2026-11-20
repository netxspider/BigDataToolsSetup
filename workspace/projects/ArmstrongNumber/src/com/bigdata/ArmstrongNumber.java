package com.bigdata;

import java.io.IOException;
import java.util.StringTokenizer;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.LongWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.Reducer;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;
import org.apache.hadoop.util.GenericOptionsParser;

public class ArmstrongNumber {

    public static long power(long base, int exp) {
        long result = 1;
        for (int i = 0; i < exp; i++) {
            result *= base;
        }
        return result;
    }

    public static boolean isArmstrong(long num) {
        if (num < 0) {
            return false;
        }
        String numStr = String.valueOf(num);
        int numDigits = numStr.length();
        long temp = num;
        long sum = 0;

        while (temp > 0) {
            long digit = temp % 10;
            sum += power(digit, numDigits);
            temp /= 10;
        }

        return sum == num;
    }

    public static class ArmstrongMapper
            extends Mapper<Object, Text, LongWritable, Text> {

        private LongWritable numberKey = new LongWritable();
        private Text statusValue = new Text();

        @Override
        public void map(Object key, Text value, Context context)
                throws IOException, InterruptedException {
            String line = value.toString().trim();
            if (line.isEmpty()) {
                return;
            }

            // Support numbers separated by whitespace or commas
            String cleanLine = line.replaceAll("[,;]", " ");
            StringTokenizer tokenizer = new StringTokenizer(cleanLine);

            while (tokenizer.hasMoreTokens()) {
                String token = tokenizer.nextToken().trim();
                if (token.isEmpty()) {
                    continue;
                }

                try {
                    long num = Long.parseLong(token);
                    numberKey.set(num);
                    if (isArmstrong(num)) {
                        statusValue.set("Armstrong Number");
                    } else {
                        statusValue.set("Not Armstrong Number");
                    }
                    context.write(numberKey, statusValue);
                } catch (NumberFormatException e) {
                    // Skip or ignore non-numeric tokens
                }
            }
        }
    }

    public static class ArmstrongReducer
            extends Reducer<LongWritable, Text, LongWritable, Text> {

        @Override
        public void reduce(LongWritable key, Iterable<Text> values, Context context)
                throws IOException, InterruptedException {
            for (Text val : values) {
                context.write(key, val);
            }
        }
    }

    public static void main(String[] args) throws Exception {
        Configuration conf = new Configuration();
        GenericOptionsParser optionParser = new GenericOptionsParser(conf, args);
        String[] remainingArgs = optionParser.getRemainingArgs();

        if (remainingArgs.length < 2) {
            System.err.println("Usage: ArmstrongNumber <in> <out>");
            System.err.println("  <in>  : HDFS input path (file or directory)");
            System.err.println("  <out> : HDFS output directory path");
            System.exit(2);
        }

        Job job = Job.getInstance(conf, "Armstrong Number Identifier");
        job.setJarByClass(ArmstrongNumber.class);

        job.setMapperClass(ArmstrongMapper.class);
        job.setCombinerClass(ArmstrongReducer.class);
        job.setReducerClass(ArmstrongReducer.class);

        job.setOutputKeyClass(LongWritable.class);
        job.setOutputValueClass(Text.class);

        FileInputFormat.addInputPath(job, new Path(remainingArgs[0]));
        FileOutputFormat.setOutputPath(job, new Path(remainingArgs[1]));

        boolean success = job.waitForCompletion(true);
        System.exit(success ? 0 : 1);
    }
}

