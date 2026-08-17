# Station Météo - Raspberry Pi (Installation automatisée)

## Matériel nécessaire

| Composant | Description |
|-----------|-------------|
| Raspberry Pi 2/3/4/5/Zero 2 | Le serveur |
| Capteur DHT11 ou DHT22 | Température + humidité |
| BMP280 (optionnel) | Baromètre I2C |
| Carte microSD | Stockage (8 Go min) |
| Alimentation USB-C | Pour le RPi |

## Installation

```bash
git clone -b v2 https://github.com/jpparein/raspberry-pi-station-meteo.git station-meteo
cd station-meteo
bash install.sh
```

L'installateur :
1. Détecte automatiquement le capteur (DHT11, DHT22, BMP280)
2. Installe les dépendances (Apache, Python, venv)
3. Configure le service systemd
4. Démarre la station

## Désinstallation

```bash
bash uninstall.sh
```

## Dépannage

### Le capteur ne répond pas
Vérifiez le câblage, testez avec `python3 scripts/live_read.py`.

### Le service ne démarre pas
```bash
sudo journalctl -u meteo-v2 -n 50
```

### Apache ne fonctionne pas
```bash
sudo systemctl status apache2
sudo apache2ctl configtest
```

## Licence

MIT - Prévisions : [Open-Meteo.com](https://open-meteo.com/)
