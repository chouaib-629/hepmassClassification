# HEPMass Classification with PySpark

This project classifies high-energy physics particles using the [HEPMASS dataset](https://archive.ics.uci.edu/dataset/347/hepmass). Leveraging PySpark and MLlib, it delivers a scalable pipeline for:

- **Distributed Processing**: Efficient handling of large datasets via HDFS/Spark RDDs  
- **ML Pipeline**: Feature scaling, model training (Logistic Regression, Decision Trees), and hyperparameter tuning  
- **Actionable Outputs**: Performance metrics (F1-score, accuracy), confusion matrices, and feature importance visualizations  

Optimized for reproducibility, the system automates Hadoop/Spark cluster management and minimizes computational overhead.  

## Table of Contents

- [Features](#features)
- [Technologies Used](#technologies-used)
- [Dataset Structure](#dataset-structure)
- [Getting Started](#getting-started)
- [Usage](#usage)
- [Contributing](#contributing)
- [Contact Information](#contact-information)

## Features

- **Distributed Data Processing**: Uses PySpark for scalable handling of large datasets.
- **End-to-End Pipeline**:
  - Data loading and parsing
  - Exploratory analysis with visualizations
  - Feature scaling and preprocessing
  - Model training (Logistic Regression, Decision Tree)
  - Hyperparameter tuning
  - Model evaluation and visualization (confusion matrix, feature importance)
- **Automated Service Management**: Scripts to start/stop HDFS and Spark services.

## Technologies Used

- **PySpark**: Distributed data processing and ML.
- **Hadoop HDFS**: Storage for datasets and processed files.
- **Python Libraries**: NumPy, Pandas, Matplotlib, Seaborn.
- **Spark MLlib**: For model training and evaluation.
- **Linux/Unix**: Recommended OS for deployment.

## Dataset Structure

The [HEPMASS dataset](https://archive.ics.uci.edu/dataset/347/hepmass) contains simulated particle collision data. Each entry has 27 features (`f0` to `f26`) representing kinematic properties, a `mass` value, and a binary `label` (0 or 1) indicating the particle type.

**Sample Data:**

| label | f0       | f1       | f2      | ... | f26      | mass          |
|-------|----------|----------|---------|-----|----------|---------------|
| 0     | 0.09439  | 0.01276  | 0.91193 | ... | -1.29023 | 499.999969    |
| 1     | 0.32720  | -0.23955 | -1.5920 | ... | -0.45855 | 750           |

## Getting Started

### Prerequisites

1. **Java 8+**: Required for Spark.
2. **Hadoop & Spark**: Install and configure in standalone/cluster mode.
3. **Python 3.8+**: With `pip` for dependency management.

### Setup Instructions

1. **Clone the Repository**:

   ```bash
   git clone https://github.com/chouaib-629/hepmassClassification.git
   ```

2. Navigate to the project directory:

   ```bash
   cd hepmassClassification
   ```

3. **Set Up Python Environment:**

    ```bash
    ./setup_env.sh
    ```

4. **Download and Prepare the Dataset:**

    - **Download the dataset:**

        ```bash
        wget https://archive.ics.uci.edu/static/public/347/hepmass.zip 
        ```

    - **Extract files:**

        ```bash
        mkdir data
        unzip data/hepmass.zip -d data/
        ```

    - **Organize the data folder:**

        ```bash
        mv data/hepmass/* data/
        rmdir data/hepmass
        ```

    - **Upload to HDFS:**

        ```bash
        hdfs dfs -mkdir /hepmass
        hdfs dfs -put data/all_train.csv.gz /hepmass/
        hdfs dfs -put data/all_test.csv.gz /hepmass/
        ```

## Usage

### Run the Pipeline

1. **Activate the Virtual Environment:**

    ```bash
    source penv/bin/activate
    ```

2. **Execute the End-to-End Workflow:**

    ```bash
    ./run_pipeline.sh
    ```

    **Optional Flags:**

    - `--enable-logs`: Enable detailled Spark logs.
    - `--no-services`: Skip starting/stopping HDFS/Spark (manual management).
    - `--disable-safe-mode`: Force-disable HDFS safemode.

3. **Deactivate Environment** (when finished):

    ```bash
    deactivate
    ```

**Example with Flags:**

```bash
./run_pipeline.sh --enable-logs --disable-safe-mode
```

### Expected Output

1. **Preprocessed Data:** Stored in HDFS (`/hepmass/scaled_train`, `/hepmass/scaled_test`).
2. **Models:** Saved to HDFS (`/hepmass/models/`).
3. **Visualisation:** Generated in the `plots/` directory:
    - Class distribution
    - Feature importance
    - Confusion matrix

## Contributing

Contributions are welcome! To contribute:

1. Fork the repository.
2. Create a new branch:

   ```bash
   git checkout -b feature/feature-name
   ```

3. Commit your changes:

   ```bash
   git commit -m "Add feature description"
   ```

4. Push to the branch:

   ```bash
   git push origin feature/feature-name
   ```

5. Open a pull request.

## Contact Information

For questions or support, please contact [Me](mailto:chouaiba629@gmail.com).
