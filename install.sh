#!/usr/bin/env bash
# ============================================================================
# Station Météo - Script d'installation interactif
# Raspberry Pi 2/3/4/5/Zero - DHT11/DHT22 + BMP280 (optionnel)
# ============================================================================
set -euo pipefail

VERSION="2.0.0"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CONF_FILE=""
SERVICE_NAME="meteo-v2"
DEFAULT_INSTALL_DIR="${HOME}/meteo-v2"
APACHE_ALIAS="/meteo-v2"

# Couleurs
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ============================================================================
# Fonctions d'affichage
# ============================================================================
info()    { echo -e "${YELLOW}INFO${NC} $*" >&2; }
success() { echo -e "${GREEN} OK ${NC} $*" >&2; }
warn()    { echo -e "${YELLOW}WARN${NC} $*" >&2; }
error()   { echo -e "${RED}ERREUR${NC} $*" >&2; }
step()    { echo -e "\n${BOLD}${CYAN}── $* ──${NC}"; }
header()  { echo -e "${BOLD}========================================${NC}"; \
            echo -e "${BOLD}  Station Météo v${VERSION} - Installation  ${NC}"; \
            echo -e "${BOLD}========================================${NC}"; }

ask() {
    local prompt="$1"
    local default="${2:-}"
    local result
    if [ -n "$default" ]; then
        read -rp "$(echo -e "${BOLD}$prompt${NC} [Défaut: $default] : ")" result
        echo "${result:-$default}"
    else
        read -rp "$(echo -e "${BOLD}$prompt${NC} : ")" result
        echo "$result"
    fi
}

ask_yn() {
    local prompt="$1"
    local default="${2:-y}"
    local hint="[Y/n]"
    [ "$default" = "n" ] && hint="[y/N]"
    while true; do
        read -rp "$(echo -e "${BOLD}$prompt${NC} $hint : ")" yn
        yn="${yn:-$default}"
        case "$yn" in
            [oOyY]*) return 0 ;;
            [nN]*)   return 1 ;;
            *)       echo "Répondre par oui (o) ou non (n)." ;;
        esac
    done
}

# ============================================================================
# Vérifications système
# ============================================================================
check_root() {
    if [ "$EUID" -eq 0 ]; then
        error "Ne pas lancer ce script en tant que root."
        error "Utilisez : bash install.sh"
        exit 1
    fi
}

check_pi() {
    if [ ! -f /proc/device-tree/model ]; then
        error "Ce script doit être exécuté sur un Raspberry Pi."
        exit 1
    fi
    PI_MODEL=$(tr -d '\0' < /proc/device-tree/model 2>/dev/null || echo "Unknown")
    echo "$PI_MODEL" | grep -qi "raspberry" || { error "Modèle non reconnu : $PI_MODEL"; exit 1; }

    # Vérifier Pi 2 ou plus récent
    if echo "$PI_MODEL" | grep -qi "Raspberry Pi 1"; then
        error "Raspberry Pi 1 non supporté (bus I2C différent)."
        exit 1
    fi
    success "Modèle détecté : $PI_MODEL"
}

check_python() {
    if ! command -v python3 &>/dev/null; then
        error "Python 3 non trouvé. Installation requise : sudo apt install python3"
        exit 1
    fi
    PY_VERSION=$(python3 --version 2>&1)
    success "Python : $PY_VERSION"
}

check_network() {
    if ! ping -c 1 -W 2 8.8.8.8 &>/dev/null; then
        warn "Pas de connexion internet. Les paquets ne seront pas installables."
    fi
}

# ============================================================================
# Détection I2C
# ============================================================================
detect_i2c_bus() {
    # Trouver le bon numéro de bus I2C
    for bus in 1 0; do
        if [ -e "/dev/i2c-$bus" ]; then
            echo "$bus"
            return 0
        fi
    done
    echo ""
    return 1
}

check_i2c_enabled() {
    local bus
    bus=$(detect_i2c_bus)
    if [ -n "$bus" ]; then
        I2C_BUS="$bus"
        success "Bus I2C détecté : /dev/i2c-$bus"
        return 0
    fi
    return 1
}

enable_i2c() {
    local config_file=""
    # Vérifier quel fichier de config existe
    if [ -f "/boot/firmware/config.txt" ]; then
        config_file="/boot/firmware/config.txt"
    elif [ -f "/boot/config.txt" ]; then
        config_file="/boot/config.txt"
    else
        error "Fichier de config RPI non trouvé."
        return 1
    fi

    if grep -q "^dtparam=i2c_arm=on" "$config_file"; then
        success "I2C déjà activé dans $config_file"
        return 0
    fi

    if ask_yn "Activer I2C dans $config_file ?" "y"; then
        echo "dtparam=i2c_arm=on" | sudo -S tee -a "$config_file" >/dev/null 2>&1 || \
        echo "dtparam=i2c_arm=on" >> "$config_file"
        success "I2C activé dans $config_file"
        warn "Un redémarrage sera nécessaire après l'installation."
        I2C_ACTIVATED=true
        return 0
    else
        info "I2C non activé. Vous pouvez l'activer manuellement :"
        info "  sudo raspi-config → Interface Options → I2C → Enable"
        info "  sudo reboot"
        return 1
    fi
}

# ============================================================================
# Détection capteurs
# ============================================================================
detect_bmp280() {
    local bus="${1:-1}"
    local addr=""

    # Installer i2c-tools si nécessaire
    if ! command -v i2cdetect &>/dev/null; then
        info "Installation de i2c-tools pour la détection..."
        sudo apt-get install -y i2c-tools >/dev/null 2>&1 || true
    fi

    if ! command -v i2cdetect &>/dev/null; then
        warn "i2cdetect non disponible, détection BMP280 impossible."
        return 1
    fi

    # Scanner les adresses 0x76 et 0x77
    for a in 0x76 0x77; do
        local chip_id
        chip_id=$(i2cdetect -y "$bus" "$a" "$a" 2>/dev/null | grep -v "^$" | tail -1 | awk '{print $2}')
        if [ -n "$chip_id" ] && [ "$chip_id" != "--" ]; then
            # Lire le Chip ID (registre 0xD0)
            local real_id
            real_id=$(i2cget -y "$bus" "$a" 0xD0 2>/dev/null | grep -oP '0x[0-9a-fA-F]+' | tail -1)
            if [ "$real_id" = "0x58" ]; then
                echo "$a"
                return 0
            elif [ "$real_id" = "0x60" ]; then
                echo "$a"
                return 0
            fi
        fi
    done
    return 1
}

probe_dht() {
    # Méthode 1 : Lire la config existante (pas d'arrêt de service)
    info "Recherche du capteur DHT..."

    # Chercher dans les scripts existants (meteo, station-meteo-github-final, etc.)
    local search_dirs="${HOME}/meteo ${HOME}/station-meteo-github-final/scripts"
    local found=""

    for dir in $search_dirs; do
        if [ -f "$dir/collect.py" ]; then
            local pin_line
            pin_line=$(grep -oP 'board\.D\K[0-9]+' "$dir/collect.py" 2>/dev/null | head -1)
            if [ -n "$pin_line" ]; then
                # Vérifier quel capteur est utilisé
                local sensor
                sensor=$(grep -oP 'adafruit_dht\.\K(DHT\w+)' "$dir/collect.py" 2>/dev/null | head -1)
                [ -z "$sensor" ] && sensor="DHT22"
                success "Config existante trouvée : $sensor sur GPIO $pin_line (source: $dir/collect.py)"
                echo "${sensor}:${pin_line}"
                return 0
            fi
        fi
        if [ -f "$dir/live_read.py" ]; then
            local pin_line
            pin_line=$(grep -oP 'board\.D\K[0-9]+' "$dir/live_read.py" 2>/dev/null | head -1)
            if [ -n "$pin_line" ]; then
                local sensor
                sensor=$(grep -oP 'adafruit_dht\.\K(DHT\w+)' "$dir/live_read.py" 2>/dev/null | head -1)
                [ -z "$sensor" ] && sensor="DHT22"
                success "Config existante trouvée : $sensor sur GPIO $pin_line (source: $dir/live_read.py)"
                echo "${sensor}:${pin_line}"
                return 0
            fi
        fi
    done

    # Méthode 2 : Vérifier si un service meteo tourne (il indique le GPIO utilisé)
    if systemctl is-active --quiet meteo 2>/dev/null; then
        warn "Le service meteo tourne mais impossible de lire sa config."
        warn "Le capteur est probablement sur GPIO 4 (DHT22 par défaut)."
    fi

    # Méthode 3 : Aucune config trouvée → pas de probe automatique
    warn "Aucune config de capteur trouvée."
    return 1
}

# ============================================================================
# Installation des paquets
# ============================================================================
install_packages() {
    local packages=()
    local descriptions=()

    # Tous les paquets de base
    packages+=("python3-pip" "python3-venv")
    descriptions+=("Gestionnaire de packages Python" "Environnements virtuels Python")

    if [ "$HAS_BAROMETER" = true ]; then
        packages+=("i2c-tools" "python3-smbus")
        descriptions+=("Outils de détection I2C" "Accès I2C depuis Python")
    fi

    packages+=("apache2" "libapache2-mod-php" "php-sqlite3")
    descriptions+=("Serveur web Apache" "Support PHP dans Apache" "Accès SQLite depuis PHP")

    echo ""
    info "Paquets à installer :"
    for i in "${!packages[@]}"; do
        printf "  ${GREEN}[OK]${NC} %-28s %s\n" "${packages[$i]}" "${descriptions[$i]}"
    done

    if ! ask_yn "Installer ces paquets ?" "y"; then
        warn "Installation des paquets annulée."
        warn "Certains paquets sont nécessaires au fonctionnement."
        if ! ask_yn "Continuer quand même ?" "n"; then
            exit 1
        fi
    fi

    sudo apt-get update -qq 2>/dev/null || true
    for pkg in "${packages[@]}"; do
        if dpkg -s "$pkg" &>/dev/null; then
            success "$pkg déjà installé"
        else
            info "Installation de $pkg..."
            if sudo apt-get install -y "$pkg" -qq 2>/dev/null; then
                success "$pkg installé"
            else
                error "Échec d'installation de $pkg"
                if [ "$pkg" = "python3-pip" ] || [ "$pkg" = "apache2" ]; then
                    error "$pkg est obligatoire. Arrêt."
                    exit 1
                fi
            fi
        fi
    done
}

# ============================================================================
# Environnement Python
# ============================================================================
setup_venv() {
    local venv_dir="$INSTALL_DIR/venv"

    step "Étape 5/7 : Environnement Python"

    if [ -d "$venv_dir" ] && [ -f "$venv_dir/bin/activate" ]; then
        success "venv existant trouvé : $venv_dir"
        if ! ask_yn "Le recréer ?" "n"; then
            return 0
        fi
        rm -rf "$venv_dir"
    fi

    info "Création du venv..."
    python3 -m venv "$venv_dir"
    success "venv créé : $venv_dir"

    info "Mise à jour de pip..."
    "$venv_dir/bin/pip" install --upgrade pip -q 2>/dev/null || true

    local pip_packages=()

    if [ "$SENSOR_TYPE" != "none" ]; then
        pip_packages+=("adafruit-circuitpython-dht==4.0.12")
    fi

    if [ "$HAS_BAROMETER" = true ]; then
        pip_packages+=("smbus2")
    fi

    if [ ${#pip_packages[@]} -eq 0 ]; then
        success "Aucun package Python nécessaire"
        return 0
    fi

    info "Packages Python à installer :"
    for pkg in "${pip_packages[@]}"; do
        echo -e "  ${GREEN}[OK]${NC} $pkg"
    done

    if ask_yn "Installer ces packages Python ?" "y"; then
        for pkg in "${pip_packages[@]}"; do
            info "Installation de $pkg..."
            if "$venv_dir/bin/pip" install "$pkg" 2>&1 | tail -1; then
                success "$pkg installé"
            else
                error "Échec d'installation de $pkg"
            fi
        done
    fi
}

# ============================================================================
# Génération des scripts Python
# ============================================================================
generate_collect() {
    local pin_name="D${GPIO_PIN}"
    local sensor_class="DHT22"

    [ "$SENSOR_TYPE" = "DHT11" ] && sensor_class="DHT11"

    cat > "$INSTALL_DIR/scripts/collect.py" << COLLECT_EOF
#!/usr/bin/env python3
"""
Station meteo - Collecte de donnees ${SENSOR_TYPE}.
Mesure toutes les 5 minutes, stocke dans SQLite.
"""

import time
import sqlite3
import os
import sys
import logging
from datetime import datetime

import board
import adafruit_dht

# Configuration
SENSOR_PIN = board.${pin_name}
DB_PATH = "${INSTALL_DIR}/data/meteo.db"
MAX_RETRIES = 10
RETRY_DELAY = 2.5
MEASURE_INTERVAL = 300  # 5 minutes

# Logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(message)s",
    handlers=[
        logging.StreamHandler(sys.stdout),
    ],
)
log = logging.getLogger("meteo")


def init_db():
    """Initialise la base SQLite."""
    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    conn.execute("""
        CREATE TABLE IF NOT EXISTS mesures (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            timestamp TEXT NOT NULL,
            temperature REAL NOT NULL,
            humidity REAL NOT NULL
        )
    """)
    conn.execute("""
        CREATE INDEX IF NOT EXISTS idx_mesures_timestamp ON mesures(timestamp)
    """)
    conn.commit()
    conn.close()
    log.info("Base SQLite initialisee: %s", DB_PATH)


def read_sensor():
    """Lit le ${SENSOR_TYPE} avec plusieurs tentatives."""
    dht = adafruit_dht.${sensor_class}(SENSOR_PIN, use_pulseio=False)

    for attempt in range(1, MAX_RETRIES + 1):
        try:
            temp = dht.temperature
            hum = dht.humidity
            if temp is not None and hum is not None:
                if -40 <= temp <= 80 and 0 <= hum <= 100:
                    return round(temp, 1), round(hum, 1)
        except RuntimeError:
            pass
        except Exception as e:
            log.warning("Erreur inattendue lecture capteur: %s", e)
        time.sleep(RETRY_DELAY)

    return None


def store_measurement(temp, hum):
    """Enregistre une mesure dans SQLite."""
    now = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
    conn = sqlite3.connect(DB_PATH)
    conn.execute(
        "INSERT INTO mesures (timestamp, temperature, humidity) VALUES (?, ?, ?)",
        (now, temp, hum),
    )
    conn.commit()
    conn.close()
    log.info("Mesure enregistree: %s T=%.1fC H=%.1f%%", now, temp, hum)


def main():
    """Boucle principale de collecte."""
    log.info("Demarrage de la collecte meteo (${SENSOR_TYPE} GPIO ${GPIO_PIN})")
    init_db()

    while True:
        result = read_sensor()
        if result:
            temp, hum = result
            store_measurement(temp, hum)
        else:
            log.error("Echec lecture capteur apres %d tentatives", MAX_RETRIES)

        time.sleep(MEASURE_INTERVAL)


if __name__ == "__main__":
    try:
        main()
    except KeyboardInterrupt:
        log.info("Arret demande par l'utilisateur")
        sys.exit(0)
    except Exception as e:
        log.error("Erreur fatale: %s", e)
        sys.exit(1)
COLLECT_EOF
    chmod +x "$INSTALL_DIR/scripts/collect.py"
    success "collect.py généré"
}

generate_live_read() {
    local pin_name="D${GPIO_PIN}"
    local sensor_class="DHT22"

    [ "$SENSOR_TYPE" = "DHT11" ] && sensor_class="DHT11"

    cat > "$INSTALL_DIR/scripts/live_read.py" << LIVE_EOF
#!/usr/bin/env python3
"""Lecture instantanee du ${SENSOR_TYPE} sans stockage en base."""
import time
import board
import adafruit_dht

dht = adafruit_dht.${sensor_class}(board.${pin_name}, use_pulseio=False)

for attempt in range(6):
    try:
        temp = dht.temperature
        hum = dht.humidity
        if temp is not None and hum is not None:
            if -40 <= temp <= 80 and 0 <= hum <= 100:
                print("OK:%.1f:%.1f" % (temp, hum))
                break
    except RuntimeError:
        pass
    except Exception:
        pass
    time.sleep(2)
else:
    print("FAIL")
LIVE_EOF
    chmod +x "$INSTALL_DIR/scripts/live_read.py"
    success "live_read.py généré"
}

# ============================================================================
# Copie des fichiers
# ============================================================================
copy_web_files() {
    info "Copie du frontend web..."
    cp -r "$SCRIPT_DIR/web/." "$INSTALL_DIR/web/" 2>/dev/null || true
    success "Fichiers web copiés"

    info "Correction des chemins dans api.php..."
    local ap="$INSTALL_DIR/web/api.php"
    sed -i "s|/home/rpi/meteo/data/|${INSTALL_DIR}/data/|g" "$ap" 2>/dev/null || true
    sed -i "s|/home/rpi/meteo/scripts/|${INSTALL_DIR}/scripts/|g" "$ap" 2>/dev/null || true
    sed -i "s|/home/rpi/meteo/live_read\.py|${INSTALL_DIR}/scripts/live_read.py|g" "$ap" 2>/dev/null || true
    sed -i "s|/home/rpi/meteo/bmp280_read\.py|${INSTALL_DIR}/scripts/bmp280_read.py|g" "$ap" 2>/dev/null || true
    sed -i "s|/home/rpi/meteo-env/bin/python3|${INSTALL_DIR}/venv/bin/python3|g" "$ap" 2>/dev/null || true
    sed -i "s|/home/rpi/meteo/|${INSTALL_DIR}/scripts/|g" "$ap" 2>/dev/null || true
    success "Chemins api.php corrigés"
}

copy_database() {
    info "Copie du schéma SQL..."
    cp "$SCRIPT_DIR/database/schema.sql" "$INSTALL_DIR/database/" 2>/dev/null || true
    success "schema.sql copié"
}

copy_barometer() {
    if [ "$HAS_BAROMETER" = true ]; then
        local src=""
        # Chercher bmp280_read.py
        if [ -f "${HOME}/meteo/bmp280_read.py" ]; then
            src="${HOME}/meteo/bmp280_read.py"
        elif [ -f "$SCRIPT_DIR/scripts/bmp280_read.py" ]; then
            src="$SCRIPT_DIR/scripts/bmp280_read.py"
        fi

        if [ -n "$src" ]; then
            cp "$src" "$INSTALL_DIR/scripts/bmp280_read.py"
            chmod +x "$INSTALL_DIR/scripts/bmp280_read.py"
            success "bmp280_read.py copié"
        else
            warn "bmp280_read.py non trouvé. Le baromètre ne fonctionnera pas."
        fi
    fi
}

# ============================================================================
# Configuration Apache
# ============================================================================
setup_apache() {
    step "Configuration Apache"

    # Vérifier qu'Apache est installé
    if ! command -v apache2 &>/dev/null; then
        error "Apache non installé"
        return 1
    fi

    # Activer le module rewrite
    sudo a2enmod rewrite >/dev/null 2>&1 || true
    success "Module rewrite activé"

    # Créer la config d'alias
    local alias_conf="/etc/apache2/conf-available/meteo-v2.conf"
    sudo tee "$alias_conf" >/dev/null << ALIAS_EOF
# Station Meteo v2 - Apache config
Alias ${APACHE_ALIAS} ${INSTALL_DIR}/web

<Directory ${INSTALL_DIR}/web>
    Options -Indexes +FollowSymLinks
    AllowOverride All
    Require all granted

    # Cache désactivé
    <IfModule mod_headers.c>
        Header set Cache-Control "no-cache, no-store, must-revalidate"
        Header set Pragma "no-cache"
        Header set Expires "0"
    </IfModule>
</Directory>
ALIAS_EOF

    # Activer la config
    sudo a2enconf meteo-v2 >/dev/null 2>&1 || true
    success "Alias ${APACHE_ALIAS} configuré"

    # Redémarrer Apache
    if sudo systemctl restart apache2 2>/dev/null; then
        success "Apache redémarré"
    else
        error "Erreur au redémarrage d'Apache"
        sudo systemctl status apache2 2>&1 | head -5
    fi
}

# ============================================================================
# Service systemd
# ============================================================================
setup_service() {
    step "Configuration du service systemd"

    local service_file="/etc/systemd/system/${SERVICE_NAME}.service"

    sudo tee "$service_file" >/dev/null << SERVICE_EOF
[Unit]
Description=Station Meteo v2 - Collecte ${SENSOR_TYPE}
After=network.target

[Service]
Type=simple
User=$USER
Group=$USER
WorkingDirectory=${INSTALL_DIR}/scripts
ExecStart=${INSTALL_DIR}/venv/bin/python3 ${INSTALL_DIR}/scripts/collect.py
Restart=on-failure
RestartSec=30
StandardOutput=journal
StandardError=journal

[Install]
WantedBy=multi-user.target
SERVICE_EOF

    sudo systemctl daemon-reload
    success "Service ${SERVICE_NAME} créé"

    if ask_yn "Démarrer le service maintenant ?" "y"; then
        sudo systemctl enable "${SERVICE_NAME}" 2>/dev/null || true
        sudo systemctl start "${SERVICE_NAME}" 2>/dev/null || true
        if sudo systemctl is-active --quiet "${SERVICE_NAME}" 2>/dev/null; then
            success "Service démarré et activé"
        else
            warn "Service créé mais non démarré. Vérifiez les logs :"
            warn "  sudo journalctl -u ${SERVICE_NAME} -f"
        fi
    fi
}

# ============================================================================
# Vérification post-installation
# ============================================================================
verify_install() {
    step "Étape 7/7 : Vérification"

    local all_ok=true

    # Test capteur DHT
    if [ "$SENSOR_TYPE" != "none" ]; then
        info "Test de lecture du ${SENSOR_TYPE}..."
        local venv_python="${INSTALL_DIR}/venv/bin/python3"
        local result
        result=$(timeout 20 "$venv_python" "${INSTALL_DIR}/scripts/live_read.py" 2>/dev/null || echo "FAIL")

        if echo "$result" | grep -q "^OK:"; then
            local temp hum
            temp=$(echo "$result" | cut -d: -f2)
            hum=$(echo "$result" | cut -d: -f3)
            success "Capteur : ${temp}°C, ${hum}%"
        else
            warn "Capteur non lisible (vérifiez le câblage)"
            all_ok=false
        fi
    fi

    # Test service
    if sudo systemctl is-active --quiet "${SERVICE_NAME}" 2>/dev/null; then
        success "Service ${SERVICE_NAME} : actif"
    else
        warn "Service ${SERVICE_NAME} : inactif"
        all_ok=false
    fi

    # Test Apache
    if curl -s -o /dev/null -w "%{http_code}" http://localhost${APACHE_ALIAS}/ | grep -q "200"; then
        success "Apache : accessible sur ${APACHE_ALIAS}"
    else
        warn "Apache : non accessible sur ${APACHE_ALIAS}"
        all_ok=false
    fi

    # Obtenir l'IP
    local ip
    ip=$(hostname -I 2>/dev/null | awk '{print $1}')
    [ -z "$ip" ] && ip="<IP_RPI>"

    echo ""
    echo -e "${BOLD}========================================${NC}"
    if [ "$all_ok" = true ]; then
        echo -e "${BOLD}  ${GREEN}Installation terminee !${NC}${BOLD}          ${NC}"
    else
        echo -e "${BOLD}  ${YELLOW}Installation terminee (avec avertissements)${NC}"
    fi
    echo -e "${BOLD}----------------------------------------${NC}"
    echo -e "  URL    : http://${ip}${APACHE_ALIAS}"
    if [ "${I2C_ACTIVATED:-false}" = true ]; then
        echo -e "  ${YELLOW}I2C active. Redemarrez : sudo reboot${NC}"
    fi
    echo -e "  Config : ${INSTALL_DIR}/config/"
    echo -e "  Logs   : sudo journalctl -u ${SERVICE_NAME}"
    echo -e "${BOLD}========================================${NC}"
    echo ""
}

# ============================================================================
# Sauvegarde de la config
# ============================================================================
save_config() {
    mkdir -p "$INSTALL_DIR/config"
    cat > "$INSTALL_DIR/config/sensor.conf" << CONF_EOF
# Station Meteo - Configuration des capteurs
# Généré par install.sh le $(date '+%Y-%m-%d %H:%M:%S')

SENSOR_TYPE=${SENSOR_TYPE}
GPIO_PIN=${GPIO_PIN}
HAS_BAROMETER=${HAS_BAROMETER}
BARO_I2C_ADDR=${BARO_I2C_ADDR:-}
BARO_I2C_BUS=${BARO_I2C_BUS:-}
INSTALL_DIR=${INSTALL_DIR}
PI_MODEL=${PI_MODEL}
CONF_EOF
    success "Configuration sauvegardée"
}



# ============================================================================
# Programme principal
# ============================================================================
main() {
    header
    check_root
    check_python
    check_network

    # ── Étape 1 : Détection ──
    step "Étape 1/7 : Détection du matériel"

    HAS_BAROMETER=false
    SENSOR_TYPE="none"
    GPIO_PIN=""
    BARO_I2C_ADDR=""
    BARO_I2C_BUS=""
    I2C_ACTIVATED=false

    # Détection I2C
    I2C_BUS=""
    if check_i2c_enabled; then
        I2C_BUS=$(detect_i2c_bus)
    fi

    # Détection BMP280
    if [ -n "$I2C_BUS" ]; then
        local bmp_addr
        if bmp_addr=$(detect_bmp280 "$I2C_BUS"); then
            HAS_BAROMETER=true
            BARO_I2C_ADDR="$bmp_addr"
            BARO_I2C_BUS="$I2C_BUS"
            success "BMP280 détecté sur I2C $bmp_addr"
        else
            info "Aucun BMP280/BME280 détecté sur I2C"
        fi
    fi

    # Détection DHT
    local dht_result=""
    if dht_result=$(probe_dht); then
        SENSOR_TYPE=$(echo "$dht_result" | cut -d: -f1)
        GPIO_PIN=$(echo "$dht_result" | cut -d: -f2)
        success "${SENSOR_TYPE} détecté sur GPIO ${GPIO_PIN}"
    else
        info "Aucun capteur DHT détecté automatiquement"
    fi

    echo ""
    echo -e "${BOLD}Résultat de la détection :${NC}"
    echo ""
    if [ "$SENSOR_TYPE" != "none" ]; then
        echo -e "  Capteur    : ${GREEN}${SENSOR_TYPE} sur GPIO ${GPIO_PIN}${NC}"
    else
        echo -e "  Capteur    : ${RED}Aucun détecté${NC}"
    fi
    if [ "$HAS_BAROMETER" = true ]; then
        echo -e "  Baromètre  : ${GREEN}BMP280 sur I2C ${BARO_I2C_ADDR}${NC}"
    else
        echo -e "  Baromètre  : ${YELLOW}Aucun${NC}"
    fi
    echo ""

    # Choix de la config
    if [ "$SENSOR_TYPE" = "none" ]; then
        warn "Aucun capteur DHT détecté. Configuration manuelle requise."
        echo ""
        echo -e "  ${BOLD}1)${NC} Configuration manuelle"
        echo -e "  ${BOLD}2)${NC} Annuler l'installation"
        echo ""
        local choice
        choice=$(ask "Votre choix" "1")
        if [ "$choice" != "1" ]; then
            info "Installation annulée."
            exit 0
        fi
    else
        echo -e "  ${BOLD}1)${NC} Utiliser cette config"
        echo -e "  ${BOLD}2)${NC} Configuration manuelle"
        echo -e "  ${BOLD}3)${NC} Re-detecter"
        echo ""
        local choice
        choice=$(ask "Votre choix" "1")

        case "$choice" in
            2)
                SENSOR_TYPE="none"
                GPIO_PIN=""
                ;;
            3)
                info "Relancement de la détection..."
                exec bash "$0"
                ;;
        esac
    fi

    # ── Configuration manuelle si nécessaire ──
    if [ "$SENSOR_TYPE" = "none" ]; then
        step "Configuration manuelle du capteur"
        echo ""
        echo -e "  ${BOLD}1)${NC} DHT22 (précision ±0.5°C)"
        echo -e "  ${BOLD}2)${NC} DHT11 (moins précis, ±2°C)"
        echo -e "  ${BOLD}3)${NC} Aucun capteur"
        echo ""
        local sensor_choice
        sensor_choice=$(ask "Quel capteur" "1")

        case "$sensor_choice" in
            1) SENSOR_TYPE="DHT22" ;;
            2) SENSOR_TYPE="DHT11" ;;
            3)
                error "Un capteur est obligatoire pour cette station."
                error "Connectez un DHT11 ou DHT22, ou vérifiez le câblage."
                exit 1
                ;;
        esac

        GPIO_PIN=$(ask "Broche GPIO (BCM)" "4")
        # Valider que c'est un nombre
        if ! [[ "$GPIO_PIN" =~ ^[0-9]+$ ]]; then
            error "Le numéro de GPIO doit être un nombre."
            exit 1
        fi
    fi

    # Configuration baromètre
    if [ "$HAS_BAROMETER" = false ]; then
        echo ""
        if [ -n "$I2C_BUS" ]; then
            if ask_yn "Avez-vous un baromètre BMP280 ?" "n"; then
                if ! I2C_BUS=$(detect_i2c_bus 2>/dev/null) || ! I2C_BUS=$(detect_i2c_bus); then
                    # Activer I2C si nécessaire
                    if check_i2c_enabled || enable_i2c; then
                        I2C_BUS=$(detect_i2c_bus)
                    fi
                fi
                if [ -n "$I2C_BUS" ]; then
                    local bmp_addr
                    if bmp_addr=$(detect_bmp280 "$I2C_BUS"); then
                        HAS_BAROMETER=true
                        BARO_I2C_ADDR="$bmp_addr"
                        BARO_I2C_BUS="$I2C_BUS"
                        success "BMP280 trouvé sur I2C $bmp_addr"
                    else
                        warn "BMP280 non trouvé. Vérifiez le câblage I2C."
                    fi
                fi
            fi
        else
            if ask_yn "Avez-vous un baromètre BMP280 ?" "n"; then
                warn "Bus I2C non disponible. Activation nécessaire."
                if enable_i2c; then
                    I2C_BUS=$(detect_i2c_bus)
                    if [ -n "$I2C_BUS" ]; then
                        local bmp_addr
                        if bmp_addr=$(detect_bmp280 "$I2C_BUS"); then
                            HAS_BAROMETER=true
                            BARO_I2C_ADDR="$bmp_addr"
                            BARO_I2C_BUS="$I2C_BUS"
                            success "BMP280 trouvé sur I2C $bmp_addr"
                        fi
                    fi
                fi
            fi
        fi
    fi

    # ── Étape 2 : Emplacement ──
    step "Étape 2/7 : Emplacement d'installation"
    INSTALL_DIR=$(ask "Dossier d'installation" "$DEFAULT_INSTALL_DIR")

    # Créer le dossier
    mkdir -p "$INSTALL_DIR"/{scripts,web,data,database,config,service,venv}
    success "Dossier $INSTALL_DIR créé"

    # ── Étape 3 : Vérifications ──
    step "Étape 3/7 : Vérifications système"
    check_pi

    # ── Étape 4 : Paquets ──
    step "Étape 4/7 : Dépendances système"
    install_packages

    # ── Étape 5 : I2C ──
    if [ "$HAS_BAROMETER" = true ] && [ -z "$I2C_BUS" ]; then
        step "Activation I2C"
        enable_i2c || true
    fi

    # ── Étape 6 : Venv ──
    setup_venv

    # ── Étape 7 : Installation ──
    step "Étape 7/7 : Installation des fichiers"

    # Générer les scripts Python
    if [ "$SENSOR_TYPE" != "none" ]; then
        generate_collect
        generate_live_read
    fi

    # Copier les fichiers
    copy_web_files
    copy_database
    copy_barometer

    # Sauvegarder la config
    save_config

    success "Fichiers installés"

    # ── Étape 8 : Configuration ──
    setup_apache
    setup_service

    # Permissions data/ APRÈS Apache (Apache crée meteo.db en www-data)
    mkdir -p "$INSTALL_DIR/data"
    sudo chown -R "$USER":"$USER" "$INSTALL_DIR/data"
    sudo chmod -R 777 "$INSTALL_DIR/data"
    # Relancer le service pour qu'il puisse écrire dans la DB
    sudo systemctl restart "${SERVICE_NAME}" 2>/dev/null || true

    # ── Vérification ──
    verify_install
}

main "$@"
