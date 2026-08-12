#!/usr/bin/env python3
"""
Station meteo - Collecte de donnees DHT22.
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
SENSOR_PIN = board.D4
DB_PATH = "/home/rpi/meteo/data/meteo.db"
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
    """Lit le DHT22 avec plusieurs tentatives. Retourne (temperature, humidity) ou None."""
    dht = adafruit_dht.DHT22(SENSOR_PIN, use_pulseio=False)

    for attempt in range(1, MAX_RETRIES + 1):
        try:
            temp = dht.temperature
            hum = dht.humidity
            if temp is not None and hum is not None:
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
    log.info("Demarrage de la collecte meteo")
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
