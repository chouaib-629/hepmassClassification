from pyspark import SparkContext
import numpy as np
from spark_setup import create_spark_session

def load_and_save():
    spark = create_spark_session("HEPMASS_Data_Loading")
    sc = spark.sparkContext
    
    def parse_line(line):
        try:
            parts = list(map(float, line.strip().split(',')))
            return (float(parts[0]), np.array(parts[1:], dtype=np.float32))  # Fixed label type
        except:
            return None
            
    # Load and parse data
    train_rdd = sc.textFile("hdfs://localhost:9000/hepmass/1000_train.csv.gz")
    test_rdd = sc.textFile("hdfs://localhost:9000/hepmass/1000_test.csv.gz")
    
    parsed_train = train_rdd.map(parse_line).filter(lambda x: x is not None)
    parsed_test = test_rdd.map(parse_line).filter(lambda x: x is not None)
    
    # Save parsed data
    parsed_train.saveAsPickleFile("hdfs://localhost:9000/hepmass/parsed_train")
    parsed_test.saveAsPickleFile("hdfs://localhost:9000/hepmass/parsed_test")
    
    print(f"Train samples: {parsed_train.count()}, Test samples: {parsed_test.count()}")

if __name__ == "__main__":
    load_and_save()