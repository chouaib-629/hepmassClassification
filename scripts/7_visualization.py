from pyspark import SparkContext
import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import seaborn as sns
import pandas as pd
from pyspark.mllib.tree import DecisionTreeModel
from pyspark.mllib.regression import LabeledPoint  # Fix: Import LabeledPoint
from sparkConfig import create_spark_session

def compute_feature_importance(tree_model, num_features):
    """Calculate feature importance based on split frequency in the tree."""
    tree_str = tree_model.toDebugString()
    feature_counts = {i: 0 for i in range(num_features)}
    
    # Use regex to reliably extract feature numbers
    import re
    pattern = r"feature (\d+)"
    matches = re.findall(pattern, tree_str)
    
    for match in matches:
        feature = int(match)
        if feature < num_features:
            feature_counts[feature] += 1
    
    # Normalize counts to [0, 1]
    total_splits = sum(feature_counts.values())
    return [feature_counts[i] / total_splits if total_splits > 0 else 0 
            for i in range(num_features)]
    
def visualize_and_save():
    spark = create_spark_session("HEPMASS_Visualization")
    sc = spark.sparkContext
    
    # Load model (MLlib format)
    best_model = DecisionTreeModel.load(sc, "hdfs://localhost:9000/hepmass/models/dt_model")
    
    # Load test data (RDD)
    scaled_test = sc.pickleFile("hdfs://localhost:9000/hepmass/scaled_test")
    test_data = scaled_test.map(lambda x: LabeledPoint(x[0], x[1]))  # Now works
    
    # Generate predictions
    predictions = best_model.predict(test_data.map(lambda x: x.features)).collect()
    labels = test_data.map(lambda x: x.label).collect()
    
    # Confusion matrix
    cm = pd.crosstab(pd.Series(labels), pd.Series(predictions), 
                     rownames=['Actual'], colnames=['Predicted'])
    plt.figure(figsize=(6, 4))
    sns.heatmap(cm, annot=True, fmt='d')
    plt.title('Confusion Matrix')
    plt.savefig('plots/final_confusion_matrix.png')
    plt.close()
    
    # Compute feature importance manually
    num_features = len(test_data.first().features)  # Get feature count from data
    importance = compute_feature_importance(best_model, num_features)
    
    # Plot feature importance
    plt.figure(figsize=(10, 6))
    plt.bar(range(len(importance)), importance)
    plt.title('Feature Importance (Split Frequency)')
    plt.xlabel('Feature Index')
    plt.ylabel('Importance')
    plt.savefig('plots/feature_importance.png')
    plt.close()

if __name__ == "__main__":
    visualize_and_save()