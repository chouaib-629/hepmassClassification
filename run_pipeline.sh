#!/bin/bash

# Configuration
HDFS_BASE_PATH="hdfs://127.0.0.1:9000/hepmass"
SCRIPT_DIR="scripts"
LOG_CONFIG="log4j.properties"
VERSION="1.2.0"
HADOOP_SBIN="${HADOOP_HOME}/sbin"
SPARK_SBIN="${SPARK_HOME}/sbin"

# Codes couleur
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Variables d'état
ENABLE_LOGS=false
MANAGE_SERVICES=true
DISABLE_SAFEMODE=false
SPARK_LOG_OPTIONS=""

# Fonction d'aide
show_help() {
    echo -e "${BLUE}Usage: ${0} [OPTIONS]"
    echo -e "Exécute le pipeline d'analyse HEPMASS\n"
    echo -e "Options:"
    echo -e "  --enable-logs       Active les logs Spark détaillés"
    echo -e "  --no-services       Ne pas gérer les services HDFS/Spark"
    echo -e "  --disable-safe-mode Désactive le safe mode HDFS"
    echo -e "  --help              Affiche ce message d'aide"
    echo -e "  --version           Affiche la version du script${NC}"
    exit 0
}

# Gestion des erreurs
handle_error() {
    echo -e "${RED}✖ Erreur critique à l'étape $1${NC}"
    exit 1
}

# Configuration des logs
configure_logging() {
    if [ "${ENABLE_LOGS}" = false ]; then
        cat > "${LOG_CONFIG}" << EOF
log4j.rootCategory=ERROR, console
log4j.appender.console=org.apache.log4j.ConsoleAppender
log4j.appender.console.target=System.err
log4j.appender.console.layout=org.apache.log4j.PatternLayout
log4j.appender.console.layout.ConversionPattern=%d{yy/MM/dd HH:mm:ss} %p %c{1}: %m%n

log4j.logger.org.apache.spark=ERROR
log4j.logger.org.apache.hadoop=ERROR
log4j.logger.io.netty=ERROR
EOF
        SPARK_LOG_OPTIONS="--conf spark.driver.extraJavaOptions=-Dlog4j.configuration=file:${LOG_CONFIG} \
                          --conf spark.executor.extraJavaOptions=-Dlog4j.configuration=file:${LOG_CONFIG}"
    fi
}

# Nettoyage
cleanup() {
    [ -f "${LOG_CONFIG}" ] && rm -f "${LOG_CONFIG}"
    if [ "${MANAGE_SERVICES}" = true ]; then
        confirm_shutdown
    fi
}

# Fonction de confirmation manuelle
confirm_shutdown() {
    echo -e "\n${YELLOW}⚠ Les services HDFS/Spark sont toujours en cours d'exécution${NC}"
    while true; do
        read -p "Voulez-vous arrêter les services maintenant ? [y/N] " response
        case "$response" in
            [yY][eE][sS]|[yY])
                stop_services
                break
                ;;
            [nN][oO]|[nN]|"")
                echo -e "${YELLOW}⚠ Les services seront laissés en cours d'exécution${NC}"
                break
                ;;
            *)
                echo -e "${RED}❌ Réponse invalide. Veuillez répondre par 'y' (oui) ou 'n' (non).${NC}"
                ;;
        esac
    done
}

# Fonctions HDFS
start_hdfs() {
    echo -e "${BLUE}→ Démarrage HDFS...${NC}"
    "${HADOOP_SBIN}/start-dfs.sh" || handle_error "Démarrage HDFS"
    echo -e "${GREEN}✔ HDFS démarré${NC}"
}

stop_hdfs() {
    echo -e "${BLUE}→ Arrêt HDFS...${NC}"
    "${HADOOP_SBIN}/stop-dfs.sh" || echo -e "${RED}⚠ Échec de l'arrêt HDFS${NC}"
    echo -e "${GREEN}✔ HDFS arrêté${NC}"
}

disable_hdfs_safemode() {
    echo -e "\n${YELLOW}🛡  Désactivation du safe mode HDFS...${NC}"
    hdfs dfsadmin -safemode leave || handle_error "Désactivation safe mode"
    echo -e "${GREEN}✔ Safe mode désactivé${NC}"
}

# Fonctions Spark
start_spark() {
    echo -e "${BLUE}→ Démarrage Spark Master...${NC}"
    "${SPARK_SBIN}/start-master.sh" || handle_error "Démarrage Spark Master"
    echo -e "${GREEN}✔ Spark Master démarré${NC}"

    echo -e "${BLUE}→ Démarrage Spark Workers...${NC}"
    "${SPARK_SBIN}/start-workers.sh" || handle_error "Démarrage Spark Workers"
    echo -e "${GREEN}✔ Spark Workers démarrés${NC}"
}

stop_spark() {
    echo -e "${BLUE}→ Arrêt Spark Workers...${NC}"
    "${SPARK_SBIN}/stop-workers.sh" || echo -e "${RED}⚠ Échec de l'arrêt Workers Spark${NC}"
    echo -e "${GREEN}✔ Spark Workers arrêtés${NC}"

    echo -e "${BLUE}→ Arrêt Spark Master...${NC}"
    "${SPARK_SBIN}/stop-master.sh" || echo -e "${RED}⚠ Échec de l'arrêt Master Spark${NC}"
    echo -e "${GREEN}✔ Spark Master arrêté${NC}"
}

# Gestion des services
start_services() {
    echo -e "${YELLOW}⚙ Démarrage des services...${NC}"
    start_hdfs
    start_spark
    
    if [ "${DISABLE_SAFEMODE}" = true ]; then
        disable_hdfs_safemode
    fi
}

stop_services() {
    echo -e "\n${YELLOW}🛑 Arrêt des services...${NC}"
    stop_spark
    stop_hdfs
}

# Vérification HDFS
verify_hdfs() {
    echo -e "\n${YELLOW}🔍 Vérification des fichiers HDFS...${NC}"
    
    local files=("all_train.csv.gz" "all_test.csv.gz")
    for file in "${files[@]}"; do
        hdfs dfs -test -e "${HDFS_BASE_PATH}/${file}" || {
            echo -e "${RED}✖ Fichier manquant: ${file}${NC}"
            exit 1
        }
    done
    
    echo -e "${GREEN}✔ Tous les fichiers requis sont présents${NC}"
}

# Nettoyage HDFS
clean_hdfs() {
    echo -e "\n${YELLOW}🧹 Nettoyage des précédents résultats...${NC}"
    
    local dirs=("parsed_train" "parsed_test" "scaled_train" "scaled_test" "models")
    for dir in "${dirs[@]}"; do
        if hdfs dfs -test -e "${HDFS_BASE_PATH}/${dir}"; then
            echo -e "Suppression de ${BLUE}${dir}${NC}"
            hdfs dfs -rm -r "${HDFS_BASE_PATH}/${dir}" || handle_error "Nettoyage HDFS"
        fi
    done
}

# Exécution d'une étape
run_step() {
    local step_num=$1
    local step_name=$2
    local script=$3
    
    echo -e "\n${GREEN}=== Étape ${step_num}/7: ${step_name} ===${NC}"
    echo -e "${YELLOW}Exécution de ${BLUE}${script}${YELLOW}...${NC}"
    
    spark-submit ${SPARK_LOG_OPTIONS} "${SCRIPT_DIR}/${script}" || handle_error "Étape ${step_num}"
}

# Traitement des arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --enable-logs)
            ENABLE_LOGS=true
            shift
            ;;
        --no-services)
            MANAGE_SERVICES=false
            shift
            ;;
        --disable-safe-mode)
            DISABLE_SAFEMODE=true
            shift
            ;;
        --help)
            show_help
            ;;
        --version)
            echo -e "${BLUE}HEPMASS Pipeline v${VERSION}${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}Option inconnue: $1${NC}"
            show_help
            exit 1
            ;;
    esac
done

# Initialisation
trap cleanup EXIT SIGINT SIGTERM
clear
echo -e "${BLUE}=============================================="
echo -e " Pipeline d'analyse HEPMASS - v${VERSION}"
echo -e "==============================================${NC}"

# Configuration initiale
configure_logging

# Gestion des services
if [ "${MANAGE_SERVICES}" = true ]; then
    start_services
else
    echo -e "${YELLOW}⚠ Gestion des services désactivée${NC}"
fi

# Vérifications HDFS
verify_hdfs
clean_hdfs

# Exécution du pipeline
echo -e "\n${YELLOW}🚀 Démarrage du pipeline...${NC}"

run_step 1 "Chargement des données" "1_data_loading.py"
run_step 2 "Exploration des données" "2_data_exploration.py"
run_step 3 "Prétraitement" "3_preprocessing.py"
run_step 4 "Entraînement des modèles" "4_model_training.py"
run_step 5 "Évaluation des modèles" "5_evaluation.py"
run_step 6 "Optimisation hyperparamètres" "6_hyperparameter_tuning.py"
run_step 7 "Visualisation finale" "7_visualization.py"

# Finalisation
echo -e "\n${BLUE}=============================================="
echo -e "✅ Pipeline exécuté avec succès!"
if [ "${MANAGE_SERVICES}" = true ]; then
    echo -e "⚠ Les services HDFS/Spark sont toujours en cours d'exécution${NC}"
    confirm_shutdown
else
    echo -e "==============================================${NC}"
fi