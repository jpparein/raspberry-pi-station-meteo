# Station Météo Raspberry Pi

## Ce qu'elle sait faire

- mesure locale de la température et de l'humidité (DHT11 ou DHT22) ;
- baromètre BMP280 en option ;
- collecte automatique toutes les 5 minutes ;
- stockage dans SQLite ;
- prévisions horaires via Open-Meteo ;
- interface web moderne, compatible iOS 12 ;
- mode nuit automatique selon le soleil ;
- animations météo (soleil, nuages, pluie, neige, orage) ;
- aucun compte en ligne requis.

## Matériel utilisé

| Composant | Description |
|---|---|
| Raspberry Pi 2/3/4/5/Zero 2 | Serveur |
| DHT11 ou DHT22 sur module | Température et humidité |
| BMP280 (optionnel) | Baromètre I2C |
| Carte microSD (8 Go min) | Système et base SQLite |
| Alimentation USB-C | Pour le RPi |

## Branchement du DHT22 — trois fils, pas un de plus

Le module possède trois broches : `+`, `OUT` et `−`.

| DHT22 | Raspberry Pi | Broche physique | Rôle |
|---|---|---|---|
| `+` / VCC | 3,3 V | 1 | Alimentation |
| `OUT` / DATA | GPIO 4 | 7 | Données |
| `−` / GND | GND | 6 | Masse |

> Ajouter une résistance pull-up de 4.7kΩ entre DATA et VCC si le module ne l'a pas intégrée.

Vérifiez le marquage de votre module : l'ordre des broches peut varier selon le fabricant.

### Côté Raspberry Pi

Branchez les fils sur les broches du Raspberry Pi selon le tableau ci-dessus.

## Installation extérieure du capteur

Le capteur doit être placé :

- à l'ombre ;
- à l'abri de la pluie directe ;
- dans un endroit ventilé ;
- loin d'un mur ou d'une toiture qui accumule la chaleur.

## Installation logicielle

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

## Commandes utiles

```bash
# Statut du service
sudo systemctl status meteo-v2

# Logs en temps réel
sudo journalctl -u meteo-v2 -f

# Redémarrer le service
sudo systemctl restart meteo-v2

# Lecture instantanée du capteur
python3 scripts/live_read.py
```

## Dépannage

### Aucune mesure ne s'affiche

```bash
sudo systemctl status meteo-v2 --no-pager
sudo journalctl -u meteo-v2 -n 50 --no-pager
python3 scripts/live_read.py
```

Vérifiez le câblage (3.3V, GND, GPIO 4).

### Le service ne démarre pas

```bash
sudo journalctl -u meteo-v2 -n 50
```

### Apache ne fonctionne pas

```bash
sudo systemctl status apache2
sudo apache2ctl configtest
```

### Les prévisions sont absentes

Vérifiez l'accès Internet et la commune affichée dans l'interface.

## Licence

MIT - Prévisions : [Open-Meteo.com](https://open-meteo.com/)
