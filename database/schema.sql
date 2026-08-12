CREATE TABLE IF NOT EXISTS mesures (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    timestamp TEXT NOT NULL,
    temperature REAL NOT NULL,
    humidity REAL NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_mesures_timestamp
ON mesures(timestamp);