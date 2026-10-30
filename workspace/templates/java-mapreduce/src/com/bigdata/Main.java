package com.bigdata;

import java.io.IOException;

import org.apache.hadoop.conf.Configuration;
import org.apache.hadoop.fs.Path;
import org.apache.hadoop.io.IntWritable;
import org.apache.hadoop.io.Text;
import org.apache.hadoop.mapreduce.Job;
import org.apache.hadoop.mapreduce.Mapper;
import org.apache.hadoop.mapreduce.Reducer;
import org.apache.hadoop.mapreduce.lib.input.FileInputFormat;
import org.apache.hadoop.mapreduce.lib.output.FileOutputFormat;
import org.apache.hadoop.util.GenericOptionsParser;

/**
 * Reusable MapReduce Template Driver
 * 
 * Instructions:
 * 1. Modify the Mapper and Reducer logic below for your assignment
 *    (e.g., WordCount, MatrixMultiplication, Sorting, etc.).
 * 2. Update the output Key/Value classes in job configuration if needed.
 * 3. Update APP_NAME and MAIN_CLASS in build.sh and run.sh accordingly.
 */
public class Main {

    /**
     * Map Task
     * Input:  <Object key, Text value> (Line offset, Line text)
     * Output: <Text outKey, IntWritable outValue>
     */
    public static class TemplateMapper
            extends Mapper<Object, Text, Text, IntWritable> {

        private final static IntWritable one = new IntWritable(1);
        private Text outKey = new Text();

        @Override
        public void map(Object key, Text value, Context context)
                throws IOException, InterruptedException {
            // TODO: Implement your custom mapping logic here
            String line = value.toString().trim();
            if (!line.isEmpty()) {
                outKey.set(line);
                context.write(outKey, one);
            }
        }
    }

    /**
     * Reduce Task
     * Input:  <Text inKey, Iterable<IntWritable> inValues>
     * Output: <Text outKey, IntWritable outValue>
     */
    public static class TemplateReducer
            extends Reducer<Text, IntWritable, Text, IntWritable> {

        private IntWritable result = new IntWritable();

        @Override
        public void reduce(Text key, Iterable<IntWritable> values, Context context)
                throws IOException, InterruptedException {
            // TODO: Implement your custom reduction / aggregation logic here
            int sum = 0;
            for (IntWritable val : values) {
                sum += val.get();
            }
            result.set(sum);
            context.write(key, result);
        }
    }

    /**
     * Job Configuration and Execution
     */
    public static void main(String[] args) throws Exception {
        Configuration conf = new Configuration();
        GenericOptionsParser optionParser = new GenericOptionsParser(conf, args);
        String[] remainingArgs = optionParser.getRemainingArgs();

        if (remainingArgs.length < 2) {
            System.err.println("Usage: <JobClass> <hdfs_input_path> <hdfs_output_path>");
            System.exit(2);
        }

        Job job = Job.getInstance(conf, "MapReduceTemplate");
        job.setJarByClass(Main.class);

        // Set Mapper and Reducer classes
        job.setMapperClass(TemplateMapper.class);
        job.setCombinerClass(TemplateReducer.class); // Optional combiner
        job.setReducerClass(TemplateReducer.class);

        // Set Job Output Key/Value types (must match Reducer output)
        job.setOutputKeyClass(Text.class);
        job.setOutputValueClass(IntWritable.class);

        // Set Input and Output HDFS paths
        FileInputFormat.addInputPath(job, new Path(remainingArgs[0]));
        FileOutputFormat.setOutputPath(job, new Path(remainingArgs[1]));

        boolean success = job.waitForCompletion(true);
        System.exit(success ? 0 : 1);
    }
}
