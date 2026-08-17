# Station Météo - Raspberry Pi

## Description

Station météo complète pour Raspberry Pi avec capteurs DHT11/DHT22 et baromètre BMP280 (optionnel). Interface web moderne avec prévisions météo, graphiques, prévisions solaire, qualité de l'air et bien plus.

## Matériel nécessaire

| Composant | Description | Prix indicatif |
|-----------|-------------|----------------|
| Raspberry Pi 2/3/4/5/Zero | Le serveur | 35-80€ |
| Capteur DHT22 | Température + humidité | 5-10€ |
| BMP280 (optionnel) | Baromètre I2C | 5-10€ |
| Carte microSD | Stockage (8Go min) | 5-10€ |
| Alimentation USB-C | Pour le RPi | 10-15€ |

## Câblage

### DHT22

```
DHT22          Raspberry Pi
──────         ───────────
VCC (1)   →    Pin 1 (3.3V)
DATA (2)  →    Pin 7 (GPIO 4)
GND (3)   →    Pin 6 (GND)
```

> Ajouter une résistance pull-up de 4.7kΩ entre DATA et VCC si le module ne l'a pas intégrée.

### BMP280 (optionnel)

```
BMP280          Raspberry Pi
──────          ───────────
VCC       →    Pin 1 (3.3V)
GND       →    Pin 6 (GND)
SCL       →    Pin 5 (GPIO 3 / SCL)
SDA       →    Pin 3 (GPIO 2 / SDA)
```

## Installation rapide

```bash
# Cloner le dépôt
git clone https://github.com/VOTRE_USER/station-meteo-setup.git
cd station-meteo-setup

# Lancer l'installateur
bash install.sh
```

L'installateur va :
1. Détecter automatiquement les capteurs connectés
2. Installer les dépendances (Apache, Python, etc.)
3. Configurer le service systemd
4. Démarrer la station

## Configuration manuelle

Si la détection automatique ne fonctionne pas, vous pouvez configurer manuellement le fichier `config/sensor.conf` :

```bash
# Modifier la configuration
nano config/sensor.conf

# Relancer l'installation
bash install.sh
```

Contenu de `sensor.conf` :
```
SENSOR_TYPE=DHT22
GPIO_PIN=4
HAS_BAROMETER=true
BARO_I2C_ADDR=0x76
BARO_I2C_BUS=1
INSTALL_DIR=/home/rpi/meteo
```

## Activation I2C (pour BMP280)

Le bus I2C doit être activé pour le baromètre BMP280 :

```bash
# Option 1 : via raspi-config
sudo raspi-config
# Interface Options → I2C → Enable
sudo reboot

# Option 2 : manuellement
echo "dtparam=i2c_arm=on" | sudo tee -a /boot/firmware/config.txt
sudo reboot
```

Vérification :
```bash
ls /dev/i2c-*
# Doit afficher : /dev/i2c-1

i2cdetect -y 1
# Doit afficher le BMP280 à l'adresse 0x76 ou 0x77
```

## Utilisation

### Accès web

Après installation, accédez à la station via :
```
http://<IP_RPI>/meteo-v2
```

### Commandes utiles

```bash
# Statut du service
sudo systemctl status meteo

# Logs en temps réel
sudo journalctl -u meteo -f

# Redémarrer le service
sudo systemctl restart meteo

# Lecture instantanée du capteur
python3 scripts/live_read.py

# Test du baromètre
python3 scripts/bmp280_read.py
```

## Désinstallation

```bash
bash uninstall.sh
```

## Dépannage

### Le capteur ne répond pas

1. Vérifiez le câblage (VCC, GND, DATA)
2. Vérifiez la broche GPIO utilisée
3. Testez avec `python3 scripts/live_read.py`
4. Vérifiez que la résistance pull-up est présente

### Le baromètre ne répond pas

1. Vérifiez que I2C est activé : `ls /dev/i2c-*`
2. Scannez le bus : `i2cdetect -y 1`
3. Vérifiez le câblage SDA/SCL

### Le service ne démarre pas

```bash
sudo journalctl -u meteo -n 50
sudo systemctl status meteo
```

### Apache ne fonctionne pas

```bash
sudo systemctl status apache2
sudo apache2ctl configtest
```

## Licences

- Code : MIT
- Prévisions météo : [Open-Meteo.com](https://open-meteo.com/) (gratuit, sans clé API)
- Icônes météo : SVG personnalisées

## Auteurs

- Votre nom ici
