#!/usr/bin/env bash
# ============================================================================
# Station Météo - Désinstallation
# ============================================================================
set -euo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

info()    { echo -e "${YELLOW}INFO${NC} $*"; }
success() { echo -e "${GREEN} OK ${NC} $*"; }
warn()    { echo -e "${YELLOW}WARN${NC} $*"; }
error()   { echo -e "${RED}ERREUR${NC} $*"; }

INSTALL_DIR="${1:-${HOME}/meteo-v2}"
SERVICE_NAME="meteo-v2"

echo -e "${BOLD}========================================${NC}"
echo -e "${BOLD}  Station Météo - Désinstallation      ${NC}"
echo -e "${BOLD}========================================${NC}"
echo ""
warn "Ce script va désinstaller Station Météo de :"
warn "  $INSTALL_DIR"
echo ""

read -rp "Confirmer la désinstallation ? (o/n) : " confirm
if [ "$confirm" != "o" ] && [ "$confirm" != "O" ]; then
    info "Désinstallation annulée."
    exit 0
fi

# Arrêter le service
if systemctl is-active --quiet "$SERVICE_NAME" 2>/dev/null; then
    info "Arrêt du service $SERVICE_NAME..."
    sudo systemctl stop "$SERVICE_NAME" 2>/dev/null || true
    success "Service arrêté"
fi

# Désactiver le service
if systemctl is-enabled --quiet "$SERVICE_NAME" 2>/dev/null; then
    info "Désactivation du service $SERVICE_NAME..."
    sudo systemctl disable "$SERVICE_NAME" 2>/dev/null || true
    success "Service désactivé"
fi

# Supprimer le fichier de service
if [ -f "/etc/systemd/system/${SERVICE_NAME}.service" ]; then
    info "Suppression du service systemd..."
    sudo rm -f "/etc/systemd/system/${SERVICE_NAME}.service"
    sudo systemctl daemon-reload
    success "Service supprimé"
fi

# Supprimer la config Apache
if [ -f "/etc/apache2/conf-available/meteo-v2.conf" ]; then
    info "Suppression de la config Apache..."
    sudo a2disconf meteo-v2 >/dev/null 2>&1 || true
    sudo rm -f "/etc/apache2/conf-available/meteo-v2.conf"
    sudo systemctl restart apache2 2>/dev/null || true
    success "Config Apache supprimée"
fi

# Supprimer les fichiers
if [ -d "$INSTALL_DIR" ]; then
    info "Suppression des fichiers..."
    rm -rf "$INSTALL_DIR"
    success "Fichiers supprimés : $INSTALL_DIR"
fi

echo ""
success "Désinstallation terminée."
echo ""
info "Les paquets système (apache2, python3, etc.) n'ont pas été supprimés."
info "Pour les supprimer : sudo apt remove apache2 libapache2-mod-php php-sqlite3"
echo ""
