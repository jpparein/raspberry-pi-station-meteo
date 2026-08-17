# Station Météo - Raspberry Pi (Installation automatisée)

Version avec installateur interactif. Pour l'installation manuelle, voir la branche `main`.

## Matériel nécessaire

| Composant | Description |
|-----------|-------------|
| Raspberry Pi 2/3/4/5/Zero 2 | Le serveur |
| Capteur DHT22 | Température + humidité |
| BMP280 (optionnel) | Baromètre I2C |
| Carte microSD | Stockage (8 Go min) |
| Alimentation USB-C | Pour le RPi |

## Câblage DHT22

```
DHT22          Raspberry Pi
──────         ───────────
VCC (1)   →    Pin 1 (3.3V)
DATA (2)  →    Pin 7 (GPIO 4)
GND (3)   →    Pin 6 (GND)
```

## Installation

```bash
git clone -b v2 https://github.com/jpparein/raspberry-pi-station-meteo.git station-meteo
cd station-meteo
bash install.sh
```

L'installateur détecte automatiquement le capteur, installe les dépendances, configure Apache et le service systemd.

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
