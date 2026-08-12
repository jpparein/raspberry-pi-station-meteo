#!/usr/bin/env python3
"""Lecture instantanee du DHT22 sans stockage en base."""
import time
import board
import adafruit_dht

dht = adafruit_dht.DHT22(board.D4, use_pulseio=False)

for attempt in range(6):
    try:
        temp = dht.temperature
        hum = dht.humidity
        if temp is not None and hum is not None:
            print("OK:%.1f:%.1f" % (temp, hum))
            break
    except RuntimeError:
        pass
    except Exception:
        pass
    time.sleep(2)
else:
    print("FAIL")
