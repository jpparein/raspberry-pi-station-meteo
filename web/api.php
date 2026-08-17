<?php
date_default_timezone_set('Europe/Paris');
header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-cache, must-revalidate');

$db_path = '/home/rpi/meteo/data/meteo.db';
$cache_file = '/home/rpi/meteo/data/forecast_cache.json';
$loc_file = '/home/rpi/meteo/data/location.json';

function getLocation(){
    global $loc_file;
    if(!file_exists($loc_file)) return null;
    $d = json_decode(file_get_contents($loc_file), true);
    if(!$d || !isset($d['name'], $d['latitude'], $d['longitude'])) return null;
    return $d;
}

$loc0 = getLocation();
if($loc0 && !empty($loc0['timezone'])){
    date_default_timezone_set($loc0['timezone']);
}

function staleCache() {
    global $cache_file;
    if (file_exists($cache_file)) {
        return json_decode(file_get_contents($cache_file), true);
    }
    return null;
}

function getForecast() {
    global $cache_file, $loc_file;
    $loc = getLocation();
    if(!$loc){
        return ['error' => 'Localisation non configuree'];
    }
    $lat = $loc['latitude'];
    $lon = $loc['longitude'];
    $tz = !empty($loc['timezone']) ? $loc['timezone'] : 'Europe/Paris';
    if (file_exists($cache_file)) {
        $age = time() - filemtime($cache_file);
        if ($age < 1800) {
            $cached = json_decode(file_get_contents($cache_file), true);
            if ($cached && isset($cached['loc']) && $cached['loc']['lat'] == $lat && $cached['loc']['lon'] == $lon) {
                return $cached;
            }
        }
    }
    $url = "https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&hourly=temperature_2m,weathercode,uv_index,precipitation_probability,precipitation&daily=sunrise,sunset,weathercode,temperature_2m_max,temperature_2m_min&timezone=".urlencode($tz)."&forecast_days=2";
    $ctx = stream_context_create(['http' => ['timeout' => 10]]);
    $resp = @file_get_contents($url, false, $ctx);
    if ($resp === false) return staleCache();
    $data = json_decode($resp, true);
    if (!$data || !isset($data['hourly'])) return staleCache();
    $result = [];
    $now = new DateTime('now', new DateTimeZone($tz));
    $today = $now->format('Y-m-d');
    $hour = (int)$now->format('H');
    foreach ($data['hourly']['time'] as $i => $t) {
        $dt = new DateTime($t, new DateTimeZone($tz));
        if ($dt->format('Y-m-d') < $today) continue;
        if ($dt->format('Y-m-d') == $today && (int)$dt->format('H') < $hour) continue;
        $result[] = [
            'time' => $dt->format('H:00'),
            'temp' => round($data['hourly']['temperature_2m'][$i], 1),
            'uv' => isset($data['hourly']['uv_index'][$i]) ? round($data['hourly']['uv_index'][$i]) : null,
            'pprob' => isset($data['hourly']['precipitation_probability'][$i]) ? round($data['hourly']['precipitation_probability'][$i]) : null,
            'pmm' => isset($data['hourly']['precipitation'][$i]) ? round($data['hourly']['precipitation'][$i], 1) : null,
            'code' => $data['hourly']['weathercode'][$i]
        ];
    }
    $daily = [];
    if (isset($data['daily'])) {
        for ($i = 0; $i < count($data['daily']['time']); $i++) {
            $daily[] = [
                'date' => $data['daily']['time'][$i],
                'max' => round($data['daily']['temperature_2m_max'][$i], 1),
                'min' => round($data['daily']['temperature_2m_min'][$i], 1),
                'code' => $data['daily']['weathercode'][$i],
                'sunrise' => isset($data['daily']['sunrise'][$i]) ? $data['daily']['sunrise'][$i] : null,
                'sunset' => isset($data['daily']['sunset'][$i]) ? $data['daily']['sunset'][$i] : null
            ];
        }
    }
    $out = ['hourly' => $result, 'daily' => $daily, 'fetched' => date('Y-m-d H:i:s'), 'loc' => ['lat' => $lat, 'lon' => $lon]];
    if (file_put_contents($cache_file, json_encode($out)) === false) {
        error_log('meteo: echec ecriture cache previsions ' . $cache_file);
    }
    return $out;
}

function saveLocation($d){
    global $loc_file, $cache_file;
    $name = isset($d['name']) ? trim($d['name']) : '';
    $lat = isset($d['latitude']) ? $d['latitude'] : null;
    $lon = isset($d['longitude']) ? $d['longitude'] : null;
    $tz = isset($d['timezone']) ? trim($d['timezone']) : '';
    if($name === '') return 'nom manquant';
    if(!is_numeric($lat) || $lat < -90 || $lat > 90) return 'latitude invalide';
    if(!is_numeric($lon) || $lon < -180 || $lon > 180) return 'longitude invalide';
    if($tz === '') return 'fuseau horaire manquant';
    $save = [
        'name' => $name,
        'admin1' => isset($d['admin1']) ? trim($d['admin1']) : '',
        'admin2' => isset($d['admin2']) ? trim($d['admin2']) : '',
        'country' => isset($d['country']) ? trim($d['country']) : '',
        'latitude' => (float)$lat,
        'longitude' => (float)$lon,
        'timezone' => $tz
    ];
    $tmp = $loc_file . '.tmp';
    file_put_contents($tmp, json_encode($save, JSON_PRETTY_PRINT | JSON_UNESCAPED_UNICODE));
    if(!rename($tmp, $loc_file)){
        @unlink($tmp);
        return 'echec ecriture localisation';
    }
    if(file_exists($cache_file)) @unlink($cache_file);
    return true;
}

try {
    $db = new PDO('sqlite:' . $db_path);
    $db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $action = isset($_GET['action']) ? $_GET['action'] : 'current';

    switch ($action) {
        case 'current':
            $row = $db->query("SELECT temperature, humidity, timestamp FROM mesures ORDER BY id DESC LIMIT 1")->fetch(PDO::FETCH_ASSOC);
            if ($row) {
                echo json_encode([
                    'temperature' => (float)$row['temperature'],
                    'humidity' => (float)$row['humidity'],
                    'last_update' => $row['timestamp']
                ]);
            } else {
                echo json_encode(['error' => 'Aucune mesure']);
            }
            break;

        case 'live':
            $output = shell_exec("timeout 20 /home/rpi/meteo-env/bin/python3 /home/rpi/meteo/live_read.py 2>/dev/null");
            $output = trim($output);
            if (preg_match('/OK:([0-9.-]+):([0-9.-]+)/', $output, $m)) {
                echo json_encode(['temperature' => (float)$m[1], 'humidity' => (float)$m[2]]);
            } else {
                http_response_code(500);
                echo json_encode(['error' => 'Capteur injoignable']);
            }
            break;

        case 'forecast':
            $fc = getForecast();
            if ($fc && !isset($fc['error'])) {
                echo json_encode($fc);
            } else {
                http_response_code(503);
                echo json_encode(['error' => $fc['error'] ?? 'Previsions indisponibles']);
            }
            break;

        case 'stats_24h':
            $row = $db->query("
                SELECT MIN(temperature) as min_t, MAX(temperature) as max_t,
                       AVG(temperature) as avg_t, MIN(humidity) as min_h,
                       MAX(humidity) as max_h, AVG(humidity) as avg_h
                FROM mesures WHERE timestamp >= datetime('now', 'localtime', '-24 hours')
            ")->fetch(PDO::FETCH_ASSOC);
            if ($row && $row['min_t'] !== null) {
                echo json_encode([
                    'min_temp' => round((float)$row['min_t'], 1),
                    'max_temp' => round((float)$row['max_t'], 1),
                    'avg_temp' => round((float)$row['avg_t'], 1),
                    'min_hum' => round((float)$row['min_h'], 1),
                    'max_hum' => round((float)$row['max_h'], 1),
                    'avg_hum' => round((float)$row['avg_h'], 1)
                ]);
            } else {
                echo json_encode(['error' => 'Pas de donnees']);
            }
            break;

        case 'chart_24h':
        case 'chart_7j':
        case 'chart_30j':
            $periods = ['chart_24h' => '-24 hours', 'chart_7j' => '-7 days', 'chart_30j' => '-30 days'];
            $rows = $db->query("SELECT timestamp, temperature, humidity FROM mesures WHERE timestamp >= datetime('now', 'localtime', '".$periods[$action]."') ORDER BY timestamp ASC")->fetchAll(PDO::FETCH_ASSOC);
            $data = [];
            foreach ($rows as $r) {
                $data[] = ['t' => $r['timestamp'], 'temp' => (float)$r['temperature'], 'hum' => (float)$r['humidity']];
            }
            echo json_encode($data);
            break;

        case 'sensor_status':
            $row = $db->query("SELECT timestamp FROM mesures ORDER BY id DESC LIMIT 1")->fetch(PDO::FETCH_ASSOC);
            if ($row) {
                $diff = time() - strtotime($row['timestamp']);
                echo json_encode(['ok' => $diff < 600, 'age' => $diff]);
            } else {
                echo json_encode(['ok' => false, 'age' => -1]);
            }
            break;

        case 'cpu_temp':
            $f='/sys/class/thermal/thermal_zone0/temp';
            if(file_exists($f) && is_readable($f)){
                $v=trim(@file_get_contents($f));
                if(is_numeric($v)){
                    echo json_encode(['temperature'=>(int)round($v/1000)]);
                    break;
                }
            }
            echo json_encode(['error'=>'Temperature CPU indisponible']);
            break;

        case 'location':
            $loc = getLocation();
            if($loc){
                echo json_encode([
                    'configured' => true,
                    'name' => $loc['name'],
                    'admin1' => $loc['admin1'] ?? '',
                    'admin2' => $loc['admin2'] ?? '',
                    'country' => $loc['country'] ?? '',
                    'latitude' => (float)$loc['latitude'],
                    'longitude' => (float)$loc['longitude'],
                    'timezone' => $loc['timezone']
                ]);
            } else {
                echo json_encode(['configured' => false]);
            }
            break;

        case 'location_search':
            $q = isset($_GET['q']) ? trim($_GET['q']) : '';
            $out = [];
            if($q !== ''){
                $gurl = 'https://geocoding-api.open-meteo.com/v1/search?name='.urlencode($q).'&count=10&language=fr&format=json&countryCode=FR';
                $ctx = stream_context_create(['http' => ['timeout' => 10]]);
                $resp = @file_get_contents($gurl, false, $ctx);
                if($resp !== false){
                    $j = json_decode($resp, true);
                    if(isset($j['results'])){
                        foreach($j['results'] as $r){
                            $out[] = [
                                'name' => $r['name'] ?? '',
                                'admin1' => $r['admin1'] ?? '',
                                'admin2' => $r['admin2'] ?? '',
                                'country' => $r['country'] ?? '',
                                'latitude' => isset($r['latitude']) ? (float)$r['latitude'] : 0,
                                'longitude' => isset($r['longitude']) ? (float)$r['longitude'] : 0,
                                'timezone' => $r['timezone'] ?? 'Europe/Paris'
                            ];
                        }
                    }
                }
            }
            echo json_encode($out);
            break;

        case 'location_save':
            if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
                http_response_code(405);
                echo json_encode(['ok' => false, 'error' => 'POST requis']);
                break;
            }
            $raw = file_get_contents('php://input');
            $d = json_decode($raw, true);
            if(!is_array($d)){
                http_response_code(400);
                echo json_encode(['ok' => false, 'error' => 'JSON invalide']);
                break;
            }
            $res = saveLocation($d);
            if($res !== true){
                http_response_code(400);
                echo json_encode(['ok' => false, 'error' => $res]);
                break;
            }
            echo json_encode(['ok' => true]);
            break;

        case 'location_reset':
            if ($_SERVER['REQUEST_METHOD'] !== 'POST') {
                http_response_code(405);
                echo json_encode(['ok' => false, 'error' => 'POST requis']);
                break;
            }
            if(file_exists($loc_file)) @unlink($loc_file);
            if(file_exists($cache_file)) @unlink($cache_file);
            echo json_encode(['ok' => true]);
            break;

        case 'pressure':
            $pfile = '/home/rpi/meteo/data/pressure_history.json';
            $out = trim((string)shell_exec("timeout 20 /usr/bin/python3 /home/rpi/meteo/bmp280_read.py 2>/dev/null"));
            $j = json_decode($out, true);
            if (!$j || empty($j['ok']) || !is_numeric($j['hpa'])) {
                echo json_encode(['ok' => false, 'error' => 'Barometre indisponible']);
                break;
            }
            $hpa = (float)$j['hpa'];
            $hist = [];
            if (file_exists($pfile)) {
                $raw = json_decode(file_get_contents($pfile), true);
                if (is_array($raw)) $hist = $raw;
            }
            $now = time();
            $hist[] = ['ts' => $now, 'hpa' => round($hpa, 2)];
            $keep = [];
            foreach ($hist as $s) {
                if ($s['ts'] >= $now - 86400) $keep[] = $s;
            }
            @file_put_contents($pfile, json_encode($keep), LOCK_EX);
            $trend = 'na'; $delta = 0.0;
            $refs = [];
            foreach ($keep as $s) {
                if ($s['ts'] >= $now - 12600 && $s['ts'] <= $now - 10200) $refs[] = (float)$s['hpa'];
            }
            if (count($refs) >= 2) {
                $delta = $hpa - (array_sum($refs) / count($refs));
                if ($delta >= 1.0) $trend = 'up';
                elseif ($delta <= -1.0) $trend = 'down';
                else $trend = 'stable';
            }
            $note = '';
            if ($trend === 'up') $note = 'Amelioration probable';
            elseif ($trend === 'down') $note = 'Degradation probable';
            elseif ($trend === 'stable') $note = 'stable';
            $hist24 = [];
            foreach ($keep as $s) {
                if ($s['ts'] >= $now - 86400) $hist24[] = ['t' => $s['ts'], 'h' => $s['hpa']];
            }
            $hpas = array_map(function($s){return $s['hpa'];}, $keep);
            $min24 = count($hpas) ? min($hpas) : $hpa;
            $max24 = count($hpas) ? max($hpas) : $hpa;
            $delta1h = 0.0;
            $refs1h = [];
            foreach ($keep as $s) {
                if ($s['ts'] >= $now - 4200 && $s['ts'] <= $now - 3000) $refs1h[] = (float)$s['hpa'];
            }
            if (count($refs1h) >= 1) $delta1h = round($hpa - (array_sum($refs1h) / count($refs1h)), 1);
            $delta24h = 0.0;
            $refs24 = [];
            foreach ($keep as $s) {
                if ($s['ts'] >= $now - 90000 && $s['ts'] <= $now - 78000) $refs24[] = (float)$s['hpa'];
            }
            if (count($refs24) >= 1) $delta24h = round($hpa - (array_sum($refs24) / count($refs24)), 1);
            $forecast = 'stabilite';
            if ($delta >= 2.0 || $delta1h >= 1.5) $forecast = 'orage';
            elseif ($delta >= 1.0 || $delta1h >= 0.8) $forecast = 'pluie';
            elseif ($delta <= -2.0 || $delta1h <= -1.5) $forecast = 'orage';
            elseif ($delta <= -1.0 || $delta1h <= -0.8) $forecast = 'pluie';
            elseif ($delta > 0.2) $forecast = 'degage';
            elseif ($delta < -0.2) $forecast = 'degradation';
            echo json_encode([
                'ok' => true,
                'hpa' => round($hpa, 1),
                'temp' => round((float)$j['temp'], 1),
                'trend' => $trend,
                'delta' => round($delta, 1),
                'delta1h' => $delta1h,
                'delta24h' => $delta24h,
                'note' => $note,
                'forecast' => $forecast,
                'min24' => round($min24, 1),
                'max24' => round($max24, 1),
                'samples' => count($keep),
                'history' => $hist24
            ]);
            break;

        case 'air_quality':
            $loc = getLocation();
            if (!$loc) {
                echo json_encode(['ok' => false, 'error' => 'Localisation non configuree']);
                break;
            }
            $lat = $loc['latitude'];
            $lon = $loc['longitude'];
            $tz = isset($loc['timezone']) ? $loc['timezone'] : 'Europe/Paris';
            $url = "https://air-quality-api.open-meteo.com/v1/air-quality?latitude=$lat&longitude=$lon&hourly=european_aqi,pm2_5,pm10,ozone&timezone=" . urlencode($tz) . "&forecast_days=1";
            $ctx = stream_context_create(['http' => ['timeout' => 10]]);
            $resp = @file_get_contents($url, false, $ctx);
            if ($resp === false) {
                echo json_encode(['ok' => false, 'error' => 'Donnees indisponibles']);
                break;
            }
            $data = json_decode($resp, true);
            if (!$data || !isset($data['hourly']) || !isset($data['hourly']['time'])) {
                echo json_encode(['ok' => false, 'error' => 'Format invalide']);
                break;
            }
            $now = date('Y-m-d\TH:00');
            $cur = null;
            for ($i = count($data['hourly']['time']) - 1; $i >= 0; $i--) {
                if ($data['hourly']['time'][$i] <= $now) {
                    $cur = [
                        'aqi' => isset($data['hourly']['european_aqi'][$i]) ? (int)$data['hourly']['european_aqi'][$i] : null,
                        'pm25' => isset($data['hourly']['pm2_5'][$i]) ? round((float)$data['hourly']['pm2_5'][$i], 1) : null,
                        'pm10' => isset($data['hourly']['pm10'][$i]) ? round((float)$data['hourly']['pm10'][$i], 1) : null,
                        'ozone' => isset($data['hourly']['ozone'][$i]) ? round((float)$data['hourly']['ozone'][$i], 1) : null
                    ];
                    break;
                }
            }
            if ($cur === null) {
                $cur = [
                    'aqi' => isset($data['hourly']['european_aqi'][0]) ? (int)$data['hourly']['european_aqi'][0] : null,
                    'pm25' => isset($data['hourly']['pm2_5'][0]) ? round((float)$data['hourly']['pm2_5'][0], 1) : null,
                    'pm10' => isset($data['hourly']['pm10'][0]) ? round((float)$data['hourly']['pm10'][0], 1) : null,
                    'ozone' => isset($data['hourly']['ozone'][0]) ? round((float)$data['hourly']['ozone'][0], 1) : null
                ];
            }
            $aqi = $cur['aqi'];
            $level = 'Bon';
            $cls = 'aq-good';
            if ($aqi !== null) {
                if ($aqi >= 60) { $level = 'Tres mauvais'; $cls = 'aq-very'; }
                elseif ($aqi >= 40) { $level = 'Mauvais'; $cls = 'aq-bad'; }
                elseif ($aqi >= 20) { $level = 'Moyen'; $cls = 'aq-moy'; }
            }
            echo json_encode([
                'ok' => true,
                'aqi' => $aqi,
                'level' => $level,
                'cls' => $cls,
                'pm25' => $cur['pm25'],
                'pm10' => $cur['pm10'],
                'ozone' => $cur['ozone']
            ]);
            break;

        default:
            http_response_code(400);
            echo json_encode(['error' => 'Action inconnue']);
    }
} catch (PDOException $e) {
    http_response_code(500);
    error_log('meteo: erreur base de donnees');
    echo json_encode(['error' => 'Erreur interne']);
}
