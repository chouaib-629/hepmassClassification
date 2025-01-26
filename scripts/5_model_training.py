from pyspark import SparkContext
from pyspark.mllib.classification import LogisticRegressionWithSGD
from pyspark.mllib.tree import DecisionTree
from pyspark.mllib.regression import LabeledPoint
from spark_setup import create_spark_session

def train_and_save():
    spark = create_spark_session("HEPMASS_Model_Training")
    sc = spark.sparkContext
    
    # Load scaled data
    scaled_train = sc.pickleFile("hdfs://localhost:9000/hepmass/scaled_train")
    train_data = scaled_train.map(lambda x: LabeledPoint(x[0], x[1]))
    
    # Train models
    lr_model = LogisticRegressionWithSGD.train(
        train_data, 
        iterations=100,
        regParam=0.01
    )
    
    dt_model = DecisionTree.trainClassifier(
        train_data,
        numClasses=2,
        categoricalFeaturesInfo={},  # Required parameter
        impurity='gini',
        maxDepth=5
    )
    
    # Save models
    lr_model.save(sc, "hdfs://localhost:9000/hepmass/models/lr_model")
    dt_model.save(sc, "hdfs://localhost:9000/hepmass/models/dt_model")
    
    print("Models trained and saved!")

if __name__ == "__main__":
    train_and_save()