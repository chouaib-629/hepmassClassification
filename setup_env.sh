#!/bin/bash

# Configuration
ENV_NAME="penv"
REQUIREMENTS="requirements.txt"
VERSION="1.1.0"

# Codes couleur
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Fonction d'aide
show_help() {
    echo -e "${BLUE}Usage: ${0} [OPTION]"
    echo -e "Configure l'environnement Python pour le projet HEPMASS\n"
    echo -e "Options:"
    echo -e "  --help      Affiche ce message d'aide"
    echo -e "  --version   Affiche la version du script"
    echo -e "\nFonctionnalités:"
    echo -e "  ✔ Vérifie les prérequis"
    echo -e "  ✔ Crée l'environnement virtuel (seulement si nécessaire)"
    echo -e "  ✔ Installe les dépendances${NC}"
    exit 0
}

# Fonction de vérification des erreurs
check_error() {
    if [ $? -ne 0 ]; then
        echo -e "${RED}✖ Erreur lors de l'étape: $1${NC}"
        exit 1
    fi
}

# Affichage version
show_version() {
    echo -e "${BLUE}Environment Setup v${VERSION}${NC}"
    exit 0
}

# Gestion des arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --help)
            show_help
            ;;
        --version)
            show_version
            ;;
        *)
            echo -e "${RED}Option inconnue: $1${NC}"
            show_help
            exit 1
            ;;
    esac
    shift
done

# Début du script
clear
echo -e "${BLUE}=============================================="
echo -e " Configuration de l'environnement Python"
echo -e "==============================================${NC}\n"

# Vérification des prérequis
echo -e "${YELLOW}🔍 Vérification des prérequis...${NC}"

# Vérification de Python 3
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}✖ Python 3 n'est pas installé!${NC}"
    exit 1
else
    echo -e "${GREEN}✔ Python 3 détecté ($(python3 --version | awk '{print $2}'))${NC}"
fi

# Vérification du fichier requirements.txt
if [ ! -f "$REQUIREMENTS" ]; then
    echo -e "${RED}✖ Fichier $REQUIREMENTS introuvable!${NC}"
    exit 1
else
    echo -e "${GREEN}✔ Fichier $REQUIREMENTS trouvé${NC}"
fi

# Création de l'environnement
echo -e "\n${YELLOW}🛠  Configuration de l'environnement virtuel...${NC}"

if [ ! -d "$ENV_NAME" ]; then
    echo -e "Création de ${BLUE}$ENV_NAME${NC}"
    python3 -m venv "$ENV_NAME"
    check_error "Création de l'environnement virtuel"
    echo -e "${GREEN}✔ Environnement créé avec succès${NC}"
else
    echo -e "${BLUE}$ENV_NAME${NC} existe déjà (pas de recréation nécessaire)"
fi

# Installation des dépendances
echo -e "\n${YELLOW}📦 Installation des dépendances...${NC}"
source "$ENV_NAME/bin/activate"

echo -e "Mise à jour de pip..."
pip install --upgrade pip > /dev/null
check_error "Mise à jour de pip"

echo -e "Installation depuis $REQUIREMENTS..."
pip install -r "$REQUIREMENTS" > /dev/null
check_error "Installation des dépendances"

deactivate

# Message final
echo -e "\n${GREEN}✅ Configuration terminée avec succès!${NC}\n"

echo -e "Pour activer l'environnement:"
echo -e "${BLUE}source $ENV_NAME/bin/activate${NC}\n"

echo -e "Pour désactiver:"
echo -e "${BLUE}deactivate${NC}\n"

echo -e "Bonne programmation! 🚀"
exit 0