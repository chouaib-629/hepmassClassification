from pyspark.sql import SparkSession

def create_spark_session(appName='HEPMASS_Analysis'):
    return SparkSession.builder \
        .appName(appName) \
        .master("spark://0.0.0.0:7077") \
        .config("spark.driver.memory", "4g") \
        .config("spark.executor.memory", "4g") \
        .config("spark.executor.cores", "4") \
        .config("spark.cores.max", "6") \
        .config("spark.executor.instances", "4") \
        .config("spark.hadoop.fs.defaultFS", "hdfs://0.0.0.0:9000") \
        .config("spark.serializer", "org.apache.spark.serializer.KryoSerializer") \
        .getOrCreate()
