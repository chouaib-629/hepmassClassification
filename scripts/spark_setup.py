from pyspark.sql import SparkSession

def create_spark_session(appName='HEPMASS_Analysis'):
    return SparkSession.builder \
        .appName(appName) \
        .master("spark://localhost:7077") \
        .config("spark.driver.memory", "4g") \
        .config("spark.executor.memory", "4g") \
        .config("spark.executor.cores", "4") \
        .config("spark.cores.max", "8") \
        .config("spark.executor.instances", "4") \
        .config("spark.hadoop.fs.defaultFS", "hdfs://localhost:9000") \
        .config("spark.serializer", "org.apache.spark.serializer.KryoSerializer") \
        .getOrCreate()
