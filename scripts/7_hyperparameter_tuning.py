from pyspark import SparkContext
from pyspark.mllib.classification import LogisticRegressionWithSGD
from pyspark.mllib.tree import DecisionTree
from pyspark.mllib.regression import LabeledPoint
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
from pyspark.mllib.evaluation import MulticlassMetrics
from spark_setup import create_spark_session

def tune_and_save():
    spark = create_spark_session("HEPMASS_Hyperparameter_Tuning")
    sc = spark.sparkContext
    
    # Load training data
    scaled_train = sc.pickleFile("hdfs://localhost:9000/hepmass/scaled_train")
    train_data = scaled_train.map(lambda x: LabeledPoint(x[0], x[1]))
    
    # Hyperparameter grid
    depths = [3, 5, 7, 9]
    results = []
    
    for depth in depths:
        model = DecisionTree.trainClassifier(
            train_data,
            numClasses=2,
            categoricalFeaturesInfo={},  # Add this required parameter
            impurity='gini',
            maxDepth=depth,
            maxBins=32
        )
        preds = model.predict(train_data.map(lambda x: x.features))
        metrics = MulticlassMetrics(train_data.map(lambda x: x.label).zip(preds))
        results.append((depth, metrics.fMeasure(1.0)))

    # Save tuning results
    plt.plot(*zip(*results))
    plt.xlabel('Tree Depth')
    plt.ylabel('F1 Score')
    plt.title('Decision Tree Hyperparameter Tuning')
    plt.savefig('tuning_results.png')
    
    best_depth = max(results, key=lambda x: x[1])[0]
    print(f"Best depth: {best_depth}")

if __name__ == "__main__":
    tune_and_save()
