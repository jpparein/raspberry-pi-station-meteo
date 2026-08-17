# Station météo Raspberry Pi : opération vide-tiroirs !

![Raspberry Pi](https://img.shields.io/badge/Raspberry%20Pi-2/3/4/5/C51A4A?logo=raspberrypi&logoColor=white)
![Python](https://img.shields.io/badge/Python-3-3776AB?logo=python&logoColor=white)
![PHP](https://img.shields.io/badge/PHP-Apache-777BB4?logo=php&logoColor=white)
![SQLite](https://img.shields.io/badge/Base-SQLite-003B57?logo=sqlite&logoColor=white)
![Capteur](https://img.shields.io/badge/Capteur-DHT11/DHT22-43A047)
![Baromètre](https://img.shields.io/badge/Baromètre-BMP280-optional-blue)
![Statut](https://img.shields.io/badge/Statut-Fonctionnel-brightgreen)

Tout est parti d'un constat très scientifique : chez moi, j'avais un **Raspberry Pi 2B**, une vieille **clé Wi-Fi**, un **iPad Air sous iOS 12.5.7**, un ancien câble téléphonique RJ11 et quelques composants qui dormaient tranquillement dans mes tiroirs.

Plutôt que de les laisser poursuivre leur carrière de ramasse-poussière, j'ai décidé d'en faire une station météo locale avec un capteur **DHT22 / AM2302**. Elle mesure la température et l'humidité, conserve un historique, affiche les prévisions et transforme l'ancien iPad en écran permanent.

Le résultat n'a évidemment pas vocation à concurrencer Météo-France, mais il est plutôt complet pour un projet fabriqué essentiellement avec ce que j'avais déjà sous la main.

![Station météo affichée sur un ancien iPad](docs/images/12-affichage-station-meteo-ipad.png)

## Démonstration

![Démonstration animée de l'interface](docs/images/21-demonstration-interface-web.gif)

## Ce qu'elle sait faire

### Mesures et données
- mesure locale de la température et de l'humidité avec un **DHT11** ou **DHT22** ;
- **baromètre BMP280** en option (pression atmosphérique) ;
- collecte automatique environ toutes les 5 minutes ;
- stockage des mesures dans une base SQLite ;
- mesure instantanée à la demande, sans l'enregistrer dans l'historique ;
- statistiques sur 24 heures (min, moyenne, max) ;
- graphiques sur 24 heures, 7 jours et 30 jours ;
- prévisions horaires fournies par Open-Meteo ;
- choix de la commune au premier lancement.

### Interface et affichage
- animations adaptées à la météo : soleil, nuages, pluie, neige et orage ;
- catégorie d'humidité et calcul du point de rosée ;
- affichage discret de la température du processeur du Raspberry Pi ;
- interface tactile compatible avec Safari sous iOS 12.5.7.

### Modes d'économie
- **mode nuit** : se déclenche automatiquement selon le lever et le coucher du soleil de la commune configurée, avec basculement manuel possible ;
- **mode économie** : désactive les animations et les particules pour réduire la charge CPU, idéal sur les anciens Raspberry Pi.

### Installation
- installation automatisée en une seule commande ;
- détection automatique des capteurs ;
- aucun compte en ligne et aucune clé API nécessaires.

> Les mesures et l'historique restent à la maison, sur le Raspberry Pi. Seules les prévisions et les heures de lever/coucher du soleil nécessitent Internet via Open-Meteo.

## Matériel compatible

| Composant | Compatibilité |
|---|---|
| Raspberry Pi 2 Model B | Oui |
| Raspberry Pi 3 / 3B+ | Oui |
| Raspberry Pi 4 Model B | Oui |
| Raspberry Pi 5 | Oui |
| Raspberry Pi Zero / Zero 2 | Oui |
| Raspberry Pi 1 | Non supporté |

| Composant | Rôle |
|---|---|
| DHT11 ou DHT22 sur module | Température et humidité |
| BMP280 (optionnel) | Baromètre I2C |
| Carte microSD (8 Go min) | Système et base SQLite |
| Alimentation USB-C ou micro-USB | Pour le Raspberry Pi |

![Prototype Raspberry Pi et DHT22](docs/images/01-prototype-raspberry-dht22.jpg)

## Principe de fonctionnement

```mermaid
flowchart TD
    A["Capteur DHT11/DHT22"] --> B["collect.py"]
    F["Capteur BMP280 (optionnel)"] --> B
    B --> C["Base SQLite"]
    C --> D["API PHP"]
    E["Open-Meteo"] --> D
    D --> G["Interface web"]
    G --> H["PC, mobile ou ancien iPad"]
```

Le service `meteo-v2.service` garde `collect.py` éveillé. Le script lit le capteur sur le GPIO, puis ajoute une mesure à SQLite environ toutes les cinq minutes. Apache et PHP transforment ensuite ces données en JSON pour l'interface web.

Si un BMP280 est connecté, la pression atmosphérique est enregistrée en même temps que la température et l'humidité.

Le bouton **Mesurer** utilise `live_read.py`. Il permet de satisfaire immédiatement le classique « oui, mais combien fait-il maintenant ? ». Cette lecture actualise l'écran sans être enregistrée : les statistiques restent basées uniquement sur les mesures automatiques.

## Câblage

### DHT11 ou DHT22 — trois fils, pas un de plus

| Capteur | Raspberry Pi | Broche physique | Rôle |
|---|---|---|---|
| `+` / VCC | 3,3 V | 1 | Alimentation |
| `OUT` / DATA | GPIO 4 | 7 | Données |
| `−` / GND | GND | 6 | Masse |

![Brochage du capteur DHT22](docs/images/02-capteur-dht22-brochage.jpg)

> Ajouter une résistance pull-up de 4.7kΩ entre DATA et VCC si le module ne l'a pas intégrée. Vérifiez le marquage de votre module : l'ordre des broches peut varier selon le fabricant.

### BMP280 (optionnel) — quatre fils

| BMP280 | Raspberry Pi | Broche physique | Rôle |
|---|---|---|---|
| VCC | 3,3 V | 1 | Alimentation |
| GND | GND | 6 | Masse |
| SCL | GPIO 3 (SCL) | 5 | Horloge I2C |
| SDA | GPIO 2 (SDA) | 3 | Données I2C |

> Le BMP280 nécessite l'activation du bus I2C. L'installateur s'en charge automatiquement.

### Préparation du câble récupéré

J'avais chez moi un ancien câble téléphonique RJ11 d'environ cinq mètres qui ne servait plus. Pour relier le capteur, inutile d'acheter un câble neuf : celui-ci possède quatre conducteurs et le DHT22 n'en demande que trois — alimentation, données et masse. Il fait parfaitement l'affaire. Le quatrième fil reste inutilisé et profite simplement de la promenade jusqu'au capteur.

![Préparation du câble](docs/images/03-preparation-cable-capteur.jpg)

Les raccords sont soudés, puis chaque conducteur est isolé avec de la gaine thermorétractable. Les soudures ne gagneront peut-être pas le premier prix d'un concours d'électronique, mais elles tiennent, elles conduisent le courant et elles sont correctement isolées : contrat rempli.

![Soudure des fils du DHT22](docs/images/04-soudure-fils-dht22.jpg)

![Capteur et câble terminés](docs/images/05-capteur-cable-termine.jpg)

Le repérage `+`, `OUT` et `−` évite de jouer à la loterie au moment du branchement final.

![Raccordement final du DHT22](docs/images/09-raccordement-final-dht22.jpg)

### Côté Raspberry Pi

![Branchement sur le Raspberry Pi](docs/images/06-branchement-raspberry-pi.jpg)

## Installation extérieure

Le capteur doit être placé :

- à l'ombre ;
- à l'abri de la pluie directe ;
- dans un endroit ventilé ;
- loin d'un mur, d'une toiture ou d'un appareil qui accumule de la chaleur.

Ici, il est installé sous un avant-toit. La fixation fait appel à une technologie de pointe disponible dans presque tous les tiroirs : un crochet et du ruban adhésif. Ce n'est pas très académique, mais le capteur est maintenu, protégé de la pluie et du soleil direct, tout en restant ventilé.

![Installation extérieure du capteur](docs/images/11-installation-capteur-exterieur.png)

Le Raspberry Pi reste à l'intérieur, près du routeur, posé sur une brique — un support sans ventilateur, sans vis et garanti totalement compatible avec le Raspberry Pi.

![Raspberry Pi et clé Wi-Fi près du routeur](docs/images/10-installation-raspberry-et-wifi.png)

## Installation logicielle

L'installateur automatise tout. Plus besoin de taper vingt commandes à la main :

```bash
git clone -b v2 https://github.com/jpparein/raspberry-pi-station-meteo.git station-meteo
cd station-meteo
bash install.sh
```

L'installateur va :
1. Détecter automatiquement le capteur (DHT11, DHT22, BMP280) ;
2. Installer les dépendances (Apache, Python, venv) ;
3. Activer I2C si un BMP280 est détecté ;
4. Configurer le service systemd ;
5. Démarrer la station.

## Donner une seconde vie à l'ancien iPad

1. Ouvrez l'adresse de la station dans Safari sur l'iPad.
2. Utilisez le menu de partage.
3. Choisissez **Sur l'écran d'accueil**.
4. Lancez ensuite l'icône créée.

L'iPad est ancien, Safari aussi, et tous deux ont parfois des opinions très arrêtées sur le JavaScript moderne. L'interface utilise donc `XMLHttpRequest`, des préfixes `-webkit-` et une syntaxe compatible avec iOS 12.5.7.

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

# Vérifier la base de données
sqlite3 data/meteo.db "SELECT * FROM mesures ORDER BY id DESC LIMIT 5;"
```

## Désinstallation

```bash
bash uninstall.sh
```

## Dépannage

### Aucune mesure ne s'affiche

```bash
sudo systemctl status meteo-v2 --no-pager
sudo journalctl -u meteo-v2 -n 50 --no-pager
python3 scripts/live_read.py
```

Vérifiez le câblage (3.3V, GND, GPIO 4). Dans la majorité des cas, le logiciel n'est pas vexé : c'est simplement un fil qui l'est.

### Le service ne démarre pas

```bash
sudo journalctl -u meteo-v2 -n 50
```

### Apache ne fonctionne pas

```bash
sudo systemctl status apache2
sudo apache2ctl configtest
```

### Le BMP280 n'est pas détecté

```bash
# Vérifier que I2C est activé
ls /dev/i2c-*

# Scanner le bus
i2cdetect -y 1
```

Le BMP280 doit apparaître à l'adresse `0x76` ou `0x77`.

### Les prévisions sont absentes ou incorrectes

- vérifiez l'accès Internet du Raspberry Pi ;
- vérifiez la commune affichée dans l'interface ;
- utilisez le bouton de réinitialisation pour choisir une autre commune.

## Crédits

Projet réalisé par **Jean-Philippe Parein** avec beaucoup de matériel récupéré, quelques soudures et une quantité raisonnable de « tant qu'à faire… ».

- Prévisions et géocodage : [Open-Meteo](https://open-meteo.com/)
- Pilote du capteur : [Adafruit CircuitPython DHT](https://github.com/adafruit/Adafruit_CircuitPython_DHT)
- Plateforme : [Raspberry Pi](https://www.raspberrypi.com/)

## Licence

Le code source est distribué sous licence MIT. Consultez le fichier [LICENSE](LICENSE).
