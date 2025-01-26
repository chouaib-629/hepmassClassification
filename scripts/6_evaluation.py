from pyspark import SparkContext
from pyspark.mllib.evaluation import MulticlassMetrics
from pyspark.mllib.classification import LogisticRegressionModel
from pyspark.mllib.tree import DecisionTreeModel
from pyspark.mllib.regression import LabeledPoint
from spark_setup import create_spark_session

def evaluate_models():
    spark = create_spark_session("HEPMASS_Evaluation")
    sc = spark.sparkContext
    
    # Load data
    scaled_test = sc.pickleFile("hdfs://localhost:9000/hepmass/scaled_test")
    test_data = scaled_test.map(lambda x: LabeledPoint(x[0], x[1]))
    
    # Load models
    lr_model = LogisticRegressionModel.load(sc, "hdfs://localhost:9000/hepmass/models/lr_model")
    dt_model = DecisionTreeModel.load(sc, "hdfs://localhost:9000/hepmass/models/dt_model")
    
    def evaluate(model, data):
        # Cast to float explicitly
        preds = model.predict(data.map(lambda x: x.features)).map(float)
        labels = data.map(lambda x: float(x.label))
        return MulticlassMetrics(labels.zip(preds))
    
    # Evaluate
    lr_metrics = evaluate(lr_model, test_data)
    dt_metrics = evaluate(dt_model, test_data)
    
    print("Logistic Regression:")
    print(f"Accuracy: {lr_metrics.accuracy:.4f}")
    print(f"F1-Score: {lr_metrics.fMeasure(1.0):.4f}")
    
    print("\nDecision Tree:")
    print(f"Accuracy: {dt_metrics.accuracy:.4f}")
    print(f"F1-Score: {dt_metrics.fMeasure(1.0):.4f}")

if __name__ == "__main__":
    evaluate_models()