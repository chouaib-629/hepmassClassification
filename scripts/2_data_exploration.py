from pyspark import SparkContext
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import seaborn as sns
import pandas as pd
from sparkConfig import create_spark_session
import numpy as np

def explore_and_save():
    spark = create_spark_session("HEPMASS_Data_Exploration")
    sc = spark.sparkContext
    
    parsed_train = sc.pickleFile("hdfs://localhost:9000/hepmass/parsed_train")
    
    # Class distribution
    class_counts = parsed_train.map(lambda x: (x[0], 1)).reduceByKey(lambda a,b: a+b).collect()
    plt.figure(figsize=(8, 6))
    sns.barplot(x=[str(c[0]) for c in class_counts], y=[c[1] for c in class_counts])
    plt.title("Class Distribution")
    plt.savefig('plots/class_distribution.png')
    
    # Feature visualization
    sample_data = parsed_train.take(1000)
    features = np.array([x[1] for x in sample_data])
    df = pd.DataFrame(features[:, :5], columns=[f"feature_{i}" for i in range(1,6)])
    
    plt.figure(figsize=(12, 6))
    sns.boxplot(data=df)
    plt.title("Feature Distributions")
    plt.savefig('plots/feature_distributions.png')

if __name__ == "__main__":
    explore_and_save()