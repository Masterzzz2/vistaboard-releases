#!/usr/bin/env bash
set -euo pipefail

APP_USER="${VISTABOARD_USER:-vistaboard}"
APP_DIR="${VISTABOARD_APP_DIR:-/home/vistaboard/app}"
PORT="${VISTABOARD_PORT:-3000}"
PACKAGE_URL="${VISTABOARD_PACKAGE_URL:-https://www.vista-board.com/downloads/vistaboard-latest.tar.gz}"
ZENTRALE_URL="${VISTABOARD_ZENTRALE:-https://update.vista-board.com/vistaboard}"

log() { printf '\n[VistaBoard] %s\n' "$*"; }
ok()  { printf '[OK] %s\n' "$*"; }
fail() { printf '\n[VistaBoard] FEHLER: %s\n' "$*" >&2; exit 1; }

if [[ "$(id -u)" -ne 0 ]]; then
  fail "Bitte mit sudo starten: sudo bash vistaboard-install.sh"
fi

if ! command -v apt-get >/dev/null 2>&1; then
  fail "Dieser Installer ist fuer Debian/Raspberry Pi OS/Ubuntu gedacht."
fi

# ── 1. Systempakete ──────────────────────────────────────────────────────────
log "Installiere Systempakete..."
apt-get update -qq
apt-get install -y curl ca-certificates tar gzip nodejs npm \
  mariadb-server \
  fonts-liberation unclutter wlr-randr \
  chromium 2>/dev/null \
|| apt-get install -y curl ca-certificates tar gzip nodejs npm \
  mariadb-server \
  fonts-liberation unclutter wlr-randr \
  chromium-browser 2>/dev/null \
|| fail "Systempakete konnten nicht installiert werden."
ok "Systempakete installiert"

# ── 2. MariaDB einrichten ────────────────────────────────────────────────────
log "Richte Datenbank ein..."
systemctl enable mariadb
systemctl start mariadb

mysql -e "CREATE DATABASE IF NOT EXISTS vistaboard CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -e "CREATE USER IF NOT EXISTS 'vistaboard'@'localhost' IDENTIFIED BY 'vistaboard';"
mysql -e "GRANT ALL PRIVILEGES ON vistaboard.* TO 'vistaboard'@'localhost'; FLUSH PRIVILEGES;"

mysql vistaboard <<'SCHEMA'
CREATE TABLE IF NOT EXISTS users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  openId VARCHAR(64) NOT NULL UNIQUE,
  name TEXT,
  email VARCHAR(320),
  loginMethod VARCHAR(64),
  role ENUM('user','admin') NOT NULL DEFAULT 'user',
  createdAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updatedAt TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  lastSignedIn TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS dashboard_config (
  id INT AUTO_INCREMENT PRIMARY KEY,
  activation_code VARCHAR(64) UNIQUE,
  is_activated INT NOT NULL DEFAULT 0,
  activated_at TIMESTAMP NULL,
  weather_location VARCHAR(255) NOT NULL DEFAULT 'Berlin, Germany',
  weather_latitude VARCHAR(32),
  weather_longitude VARCHAR(32),
  weather_api_key VARCHAR(255),
  ical_url TEXT,
  calendar_update_interval INT NOT NULL DEFAULT 420,
  rss_feed_url TEXT,
  rss_feed_enabled INT NOT NULL DEFAULT 0,
  rss_feed_mode VARCHAR(32) NOT NULL DEFAULT 'static',
  rss_feed_update_interval INT NOT NULL DEFAULT 300,
  image_sources TEXT NOT NULL DEFAULT '[{"type":"bing","enabled":true}]',
  image_slideshow_interval INT NOT NULL DEFAULT 30,
  use_bing_daily_image INT NOT NULL DEFAULT 1,
  display_brightness INT NOT NULL DEFAULT 100,
  display_timeout INT NOT NULL DEFAULT 0,
  display_off_time_start VARCHAR(5) NOT NULL DEFAULT '22:00',
  display_off_time_end VARCHAR(5) NOT NULL DEFAULT '06:00',
  display_orientation VARCHAR(32) NOT NULL DEFAULT 'landscape',
  display_resolution VARCHAR(32) NOT NULL DEFAULT '1080p',
  display_custom_width INT,
  display_custom_height INT,
  timezone VARCHAR(64) NOT NULL DEFAULT 'Europe/Berlin',
  dst_enabled INT NOT NULL DEFAULT 1,
  wifi_ssid VARCHAR(255),
  wifi_password VARCHAR(255),
  onboarding_completed INT NOT NULL DEFAULT 0,
  onboarding_completed_at TIMESTAMP NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

INSERT IGNORE INTO dashboard_config (id, image_sources) VALUES (1, '[{"type":"bing","enabled":true}]');

CREATE TABLE IF NOT EXISTS activation_codes (
  id INT AUTO_INCREMENT PRIMARY KEY,
  code VARCHAR(64) NOT NULL UNIQUE,
  is_active INT NOT NULL DEFAULT 1,
  is_master_key INT NOT NULL DEFAULT 0,
  max_usage INT,
  usage_count INT NOT NULL DEFAULT 0,
  expires_at TIMESTAMP NULL,
  created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP
);
SCHEMA
ok "Datenbank und Schema erstellt"

# ── 3. App-Benutzer ─────────────────────────────────────────────────────────
if ! id "$APP_USER" >/dev/null 2>&1; then
  log "Lege Benutzer $APP_USER an"
  useradd --system --create-home --home-dir "/home/$APP_USER" --shell /bin/bash "$APP_USER"
fi

# ── 4. VistaBoard herunterladen und installieren ─────────────────────────────
log "Lade VistaBoard herunter..."
mkdir -p "$APP_DIR" "$APP_DIR/data"

# Lokales Paket oder Download
if [[ -f /boot/firmware/vistaboard/vistaboard-latest.tar.gz ]]; then
  tmp_pkg="/boot/firmware/vistaboard/vistaboard-latest.tar.gz"
  log "Nutze lokales Paket von SD-Karte"
else
  tmp_pkg="$(mktemp /tmp/vistaboard-latest.XXXXXX.tar.gz)"
  curl -fL "$PACKAGE_URL" -o "$tmp_pkg"
fi

# Entpacken direkt ins App-Verzeichnis (nicht in dist/)
rm -rf "$APP_DIR/app.new"
mkdir -p "$APP_DIR/app.new"
tar -xzf "$tmp_pkg" -C "$APP_DIR/app.new" 2>/dev/null || tar --no-xattrs -xzf "$tmp_pkg" -C "$APP_DIR/app.new"

# Falls Tarball ein Unterverzeichnis enthält, Inhalt hochziehen
if [[ ! -f "$APP_DIR/app.new/index.js" ]]; then
  subdir="$(find "$APP_DIR/app.new" -maxdepth 1 -mindepth 1 -type d | head -1)"
  if [[ -n "$subdir" && -f "$subdir/index.js" ]]; then
    mv "$subdir"/* "$APP_DIR/app.new/" 2>/dev/null || true
    mv "$subdir"/.* "$APP_DIR/app.new/" 2>/dev/null || true
    rmdir "$subdir" 2>/dev/null || true
  fi
fi

# Backup data/ und .env, dann atomic swap
[[ -d "$APP_DIR/data" ]] && cp -a "$APP_DIR/data" "$APP_DIR/app.new/data" 2>/dev/null || true
[[ -f "$APP_DIR/.env" ]] && cp "$APP_DIR/.env" "$APP_DIR/app.new/.env" 2>/dev/null || true

# Alte Dateien ersetzen (data/ und .env bleiben erhalten)
find "$APP_DIR" -maxdepth 1 -not -name data -not -name .env -not -name app.new -not -path "$APP_DIR" -exec rm -rf {} + 2>/dev/null || true
mv "$APP_DIR/app.new"/* "$APP_DIR/" 2>/dev/null || true
mv "$APP_DIR/app.new"/.* "$APP_DIR/" 2>/dev/null || true
rmdir "$APP_DIR/app.new" 2>/dev/null || true
ok "VistaBoard entpackt nach $APP_DIR"

# ── 4b. Startdatei erkennen ─────────────────────────────────────────────────
APP_START=""
for candidate in "$APP_DIR/index.js" "$APP_DIR/dist/index.js" "$APP_DIR/server/index.js"; do
  if [[ -f "$candidate" ]]; then
    APP_START="$candidate"
    break
  fi
done

if [[ -z "$APP_START" ]]; then
  log "Gefundene Dateien im App-Verzeichnis:"
  find "$APP_DIR" -maxdepth 3 -type f | sed "s#^$APP_DIR/##" | head -80 || true
  fail "Keine VistaBoard-Startdatei gefunden. Erwartet wurde index.js oder dist/index.js."
fi
ok "Startdatei erkannt: $APP_START"

# ── 5. Node-Abhaengigkeiten ─────────────────────────────────────────────────
log "Installiere Node.js-Abhaengigkeiten..."
cd "$APP_DIR"
if [[ -f package.json ]]; then
  npm install --omit=dev --legacy-peer-deps --no-audit --no-fund \
  || npm install --omit=dev --no-audit --no-fund \
  || fail "Node.js-Abhaengigkeiten konnten nicht installiert werden. Bitte Internetverbindung pruefen und erneut starten."

  if [[ ! -d node_modules/dotenv ]]; then
    npm install dotenv --omit=dev --no-audit --no-fund \
    || fail "Pflichtpaket dotenv konnte nicht installiert werden."
  fi
fi
ok "Abhaengigkeiten installiert"

# ── 6. Kiosk-Benutzer erkennen ───────────────────────────────────────────────
KIOSK_USER=""
for candidate in pi vista; do
  if id "$candidate" >/dev/null 2>&1; then KIOSK_USER="$candidate"; break; fi
done
if [[ -z "$KIOSK_USER" ]]; then
  for home in /home/*; do
    [[ -d "$home" ]] || continue
    u="$(basename "$home")"
    [[ "$u" == "$APP_USER" ]] && continue
    if id "$u" >/dev/null 2>&1; then KIOSK_USER="$u"; break; fi
  done
fi
KIOSK_USER="${KIOSK_USER:-pi}"
KIOSK_HOME="/home/$KIOSK_USER"

# ── 7. HDMI-Output erkennen ──────────────────────────────────────────────────
HDMI_OUTPUT="HDMI-A-1"
if command -v wlr-randr >/dev/null 2>&1; then
  detected="$(su - "$KIOSK_USER" -c 'XDG_RUNTIME_DIR=/run/user/$(id -u) WAYLAND_DISPLAY=wayland-0 wlr-randr 2>/dev/null' | head -1 | awk '{print $1}')" || true
  [[ -n "$detected" ]] && HDMI_OUTPUT="$detected"
fi

# ── 8. .env Datei ────────────────────────────────────────────────────────────
log "Erstelle Konfiguration..."
if [[ ! -f "$APP_DIR/.env" ]]; then
  cat > "$APP_DIR/.env" <<EOF
DATABASE_URL=mysql://vistaboard:vistaboard@localhost:3306/vistaboard
NODE_ENV=production
PORT=$PORT
VB_UPDATE_SERVER=$ZENTRALE_URL
VISTABOARD_KIOSK_USER=$KIOSK_USER
VISTABOARD_KIOSK_HOME=$KIOSK_HOME
VISTABOARD_DISPLAY_HELPER_PATH=$KIOSK_HOME/.local/bin/vistaboard-display-helper.js
VISTABOARD_DISPLAY_OUTPUT=$HDMI_OUTPUT
VISTABOARD_ENTRY=$APP_START
EOF
else
  log ".env existiert bereits, ueberspringe"
  if ! grep -q '^VISTABOARD_ENTRY=' "$APP_DIR/.env"; then
    printf '\nVISTABOARD_ENTRY=%s\n' "$APP_START" >> "$APP_DIR/.env"
  else
    sed -i "s#^VISTABOARD_ENTRY=.*#VISTABOARD_ENTRY=$APP_START#" "$APP_DIR/.env"
  fi
fi
ok ".env konfiguriert"

# ── 9. Display-Helper installieren ───────────────────────────────────────────
log "Installiere Display-Helper..."
HELPER_DEST="$KIOSK_HOME/.local/bin/vistaboard-display-helper.js"
mkdir -p "$(dirname "$HELPER_DEST")"

if [[ -f /boot/firmware/vistaboard/vistaboard-display-helper.js ]]; then
  cp /boot/firmware/vistaboard/vistaboard-display-helper.js "$HELPER_DEST"
elif [[ -f "$APP_DIR/display-helper.js" ]]; then
  cp "$APP_DIR/display-helper.js" "$HELPER_DEST"
fi

if [[ -f "$HELPER_DEST" ]]; then
  chmod +x "$HELPER_DEST"
  chown "$KIOSK_USER:$KIOSK_USER" "$HELPER_DEST"
  ok "Display-Helper installiert"
else
  log "Display-Helper nicht gefunden (optional)"
fi

# ── 10. Chromium Managed Policy (kein Translate/Passwort-Popup) ─────────────
log "Konfiguriere Chromium..."
mkdir -p /etc/chromium/policies/managed
cat > /etc/chromium/policies/managed/vistaboard.json <<'POLICY'
{
  "TranslateEnabled": false,
  "DefaultBrowserSettingEnabled": false,
  "BookmarkBarEnabled": false,
  "PasswordManagerEnabled": false
}
POLICY
ok "Chromium-Policy gesetzt"

# ── 11. Berechtigungen ──────────────────────────────────────────────────────
chown -R "$APP_USER:$APP_USER" "$APP_DIR"

# ── 12. Systemd Service ─────────────────────────────────────────────────────
log "Erstelle Systemdienst..."
cat > /etc/systemd/system/vistaboard.service <<EOF
[Unit]
Description=VistaBoard
After=network-online.target mariadb.service
Wants=network-online.target
Requires=mariadb.service

[Service]
Type=simple
User=$APP_USER
WorkingDirectory=$APP_DIR
EnvironmentFile=$APP_DIR/.env
ExecStart=/usr/bin/node $APP_START
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

# ── 13. Display-Helper Service ──────────────────────────────────────────────
if [[ -f "$HELPER_DEST" ]]; then
  KIOSK_UID="$(id -u "$KIOSK_USER")"
  cat > /etc/systemd/system/vistaboard-display-helper.service <<EOF
[Unit]
Description=VistaBoard Display Helper
After=graphical.target

[Service]
Type=simple
User=$KIOSK_USER
Environment=XDG_RUNTIME_DIR=/run/user/$KIOSK_UID
Environment=WAYLAND_DISPLAY=wayland-0
Environment=VISTABOARD_DISPLAY_OUTPUT=$HDMI_OUTPUT
ExecStart=/usr/bin/node $HELPER_DEST
Restart=always
RestartSec=5

[Install]
WantedBy=graphical.target
EOF
  systemctl daemon-reload
  systemctl enable vistaboard-display-helper
fi

# ── 14. Kiosk-Autostart (labwc/Wayland) ─────────────────────────────────────
log "Konfiguriere Kiosk-Modus..."
CHROMIUM_FLAGS="--password-store=basic --kiosk --start-fullscreen --no-first-run --noerrdialogs --disable-infobars --disable-translate --disable-suggestions-ui --disable-features=TranslateUI,Translate --lang=de --ozone-platform=wayland"

cat > /usr/local/bin/vistaboard-kiosk.sh <<EOF
#!/usr/bin/env bash
set -euo pipefail
URL="http://127.0.0.1:$PORT/"
for _ in \$(seq 1 120); do
  if curl -fsS "\$URL" >/dev/null 2>&1; then
    break
  fi
  sleep 1
done

xset s off -dpms 2>/dev/null || true
unclutter -idle 1 2>/dev/null &

exec chromium $CHROMIUM_FLAGS "\$URL" \\
  || exec chromium-browser --password-store=basic --kiosk --start-fullscreen --no-first-run --noerrdialogs --disable-infobars "\$URL"
EOF
chmod +x /usr/local/bin/vistaboard-kiosk.sh

if [[ -d "$KIOSK_HOME" ]]; then
  mkdir -p "$KIOSK_HOME/.config/labwc"
  cat > "$KIOSK_HOME/.config/labwc/autostart" <<EOF
# VistaBoard Display Helper
sleep 1 && VISTABOARD_DISPLAY_OUTPUT=$HDMI_OUTPUT /usr/bin/node $HELPER_DEST &

# VistaBoard Kiosk (wartet, bis der lokale Server erreichbar ist)
/usr/local/bin/vistaboard-kiosk.sh &
EOF
  chown -R "$KIOSK_USER:$KIOSK_USER" "$KIOSK_HOME/.config/labwc"
fi

# Fallback: XDG autostart
mkdir -p /etc/xdg/autostart
cat > /etc/xdg/autostart/vistaboard-kiosk.desktop <<EOF
[Desktop Entry]
Type=Application
Name=VistaBoard Kiosk
Exec=/usr/local/bin/vistaboard-kiosk.sh
Terminal=false
EOF
ok "Kiosk-Modus konfiguriert"

# ── 15. Service starten ──────────────────────────────────────────────────────
log "Starte VistaBoard..."
systemctl daemon-reload
systemctl enable vistaboard
systemctl restart vistaboard

log "Warte auf VistaBoard..."
ok_flag=0
for _ in $(seq 1 60); do
  if curl -fsS "http://127.0.0.1:$PORT/" >/dev/null 2>&1; then
    ok_flag=1
    break
  fi
  sleep 1
done

if [[ "$ok_flag" != "1" ]]; then
  systemctl status vistaboard --no-pager || true
  fail "VistaBoard ist nicht erreichbar. Logs: sudo journalctl -u vistaboard -n 50"
fi

IP_ADDR="$(hostname -I | awk '{print $1}')"

cat <<EOF

======================================
  VistaBoard erfolgreich installiert!
======================================

Dashboard:     http://${IP_ADDR}:${PORT}/
Einstellungen: http://${IP_ADDR}:${PORT}/ (Zahnrad oben rechts)

Beim ersten Start fuehrt VistaBoard durch die Einrichtung.
Sie koennen die Einrichtung auch bequem von einem
anderen Geraet im gleichen Netzwerk durchfuehren.

Nach einem Neustart startet der Kiosk-Modus automatisch.
  sudo reboot
EOF
