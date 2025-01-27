from pyspark import SparkContext
from pyspark.mllib.feature import StandardScaler
from sparkConfig import create_spark_session

def preprocess_and_save():
    spark = create_spark_session("HEPMASS_Preprocessing")
    sc = spark.sparkContext
    
    # Load data
    parsed_train = sc.pickleFile("hdfs://0.0.0.0:9000/hepmass/parsed_train")
    parsed_test = sc.pickleFile("hdfs://0.0.0.0:9000/hepmass/parsed_test")
    
    # Feature scaling
    feature_vectors = parsed_train.map(lambda x: x[1])
    scaler = StandardScaler(withMean=True, withStd=True).fit(feature_vectors)
    
    # Broadcast parameters
    means = sc.broadcast(scaler.mean)
    stds = sc.broadcast(scaler.std)
    
    # Scale data
    scaled_train = parsed_train.map(lambda x: (x[0], (x[1] - means.value) / (stds.value + 1e-8)))
    scaled_test = parsed_test.map(lambda x: (x[0], (x[1] - means.value) / (stds.value + 1e-8)))
    
    # Save scaled data
    scaled_train.saveAsPickleFile("hdfs://0.0.0.0:9000/hepmass/scaled_train")
    scaled_test.saveAsPickleFile("hdfs://0.0.0.0:9000/hepmass/scaled_test")
    
    print("Preprocessing completed!")

if __name__ == "__main__":
    preprocess_and_save()