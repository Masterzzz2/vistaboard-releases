#!/usr/bin/env bash
set -euo pipefail
umask 027

APP_USER="${VISTABOARD_USER:-vistaboard}"
APP_DIR="${VISTABOARD_APP_DIR:-/home/vistaboard/app}"
PORT="${VISTABOARD_PORT:-3000}"
PACKAGE_URL="${VISTABOARD_PACKAGE_URL:-https://www.vista-board.com/downloads/vistaboard-latest.tar.gz}"
PACKAGE_SHA256="${VISTABOARD_PACKAGE_SHA256:-}"
PACKAGE_MANIFEST_URL="${VISTABOARD_PACKAGE_MANIFEST_URL:-https://www.vista-board.com/downloads/vistaboard-latest.json}"
ZENTRALE_URL="${VISTABOARD_ZENTRALE:-https://www.vista-board.com/vistaboard}"
export DEBIAN_FRONTEND="${DEBIAN_FRONTEND:-noninteractive}"

log() { printf '\n[VistaBoard] %s\n' "$*"; }
ok()  { printf '[OK] %s\n' "$*"; }
fail() { printf '\n[VistaBoard] FEHLER: %s\n' "$*" >&2; exit 1; }

if [[ "$(id -u)" -ne 0 ]]; then
  fail "Bitte mit sudo starten: sudo bash vistaboard-install.sh"
fi

if ! command -v apt-get >/dev/null 2>&1; then
  fail "Dieser Installer ist fuer Debian/Raspberry Pi OS/Ubuntu gedacht."
fi

[[ "$APP_USER" =~ ^[a-z_][a-z0-9_-]{0,31}$ ]] || fail "Ungueltiger VistaBoard-Systembenutzer."
[[ "$APP_DIR" == "/home/$APP_USER/app" ]] || fail "Ungueltiges VistaBoard-App-Verzeichnis."
[[ "$PORT" =~ ^[0-9]+$ ]] && (( PORT >= 1024 && PORT <= 65535 )) || fail "Ungueltiger Netzwerk-Port."
[[ "$PACKAGE_URL" == https://* || "$PACKAGE_URL" == file:///boot/firmware/vistaboard/* ]] || fail "Paket-URL muss HTTPS verwenden."
[[ "$PACKAGE_MANIFEST_URL" == https://* ]] || fail "Manifest-URL muss HTTPS verwenden."
[[ "$ZENTRALE_URL" == https://* ]] || fail "Update-Server muss HTTPS verwenden."

# ── 1. Systempakete ──────────────────────────────────────────────────────────
log "Installiere Systempakete..."
apt-get update -qq
system_packages=(
  curl ca-certificates tar gzip nodejs npm rsync
  mariadb-server fonts-liberation unclutter wlr-randr
)
if ! apt-get install -y -o DPkg::Lock::Timeout=300 "${system_packages[@]}" chromium; then
  log "Paketname chromium ist nicht verfuegbar, versuche chromium-browser..."
  apt-get install -y -o DPkg::Lock::Timeout=300 "${system_packages[@]}" chromium-browser \
    || fail "Systempakete konnten nicht installiert werden."
fi
ok "Systempakete installiert"

# ── 2. MariaDB einrichten ────────────────────────────────────────────────────
log "Richte Datenbank ein..."
systemctl enable mariadb
systemctl start mariadb

DB_PASSWORD=""
if [[ -f "$APP_DIR/.env" ]]; then
  DB_PASSWORD="$(sed -n 's#^DATABASE_URL=mysql://vistaboard:\([a-f0-9]\{48\}\)@localhost:3306/vistaboard$#\1#p' "$APP_DIR/.env" | head -n 1)"
fi
if [[ ! "$DB_PASSWORD" =~ ^[a-f0-9]{48}$ ]]; then
  DB_PASSWORD="$(od -An -N24 -tx1 /dev/urandom | tr -d ' \n')"
fi

mysql -e "CREATE DATABASE IF NOT EXISTS vistaboard CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;"
mysql -e "CREATE USER IF NOT EXISTS 'vistaboard'@'localhost' IDENTIFIED BY '$DB_PASSWORD';"
mysql -e "ALTER USER 'vistaboard'@'localhost' IDENTIFIED BY '$DB_PASSWORD';"
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
  display_orientation VARCHAR(32) NOT NULL DEFAULT 'portrait',
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

if [[ ! "$PACKAGE_SHA256" =~ ^[a-fA-F0-9]{64}$ ]]; then
  manifest_file="$(mktemp /tmp/vistaboard-manifest.XXXXXX.json)"
  curl -fL --proto '=https' --tlsv1.2 "$PACKAGE_MANIFEST_URL" -o "$manifest_file"
  PACKAGE_SHA256="$(node -e '
    const fs = require("fs");
    const value = JSON.parse(fs.readFileSync(process.argv[1], "utf8")).sha256 || "";
    if (!/^[a-f0-9]{64}$/i.test(value)) process.exit(2);
    process.stdout.write(value.toLowerCase());
  ' "$manifest_file")" || fail "Das Download-Manifest enthaelt keine gueltige SHA-256-Pruefsumme."
  rm -f "$manifest_file"
fi
PACKAGE_SHA256="${PACKAGE_SHA256,,}"

# Lokales Paket oder Download
package_is_temporary=0
if [[ -f /boot/firmware/vistaboard/vistaboard-latest.tar.gz ]]; then
  tmp_pkg="/boot/firmware/vistaboard/vistaboard-latest.tar.gz"
  log "Nutze lokales Paket von SD-Karte"
else
  tmp_pkg="$(mktemp /tmp/vistaboard-latest.XXXXXX.tar.gz)"
  package_is_temporary=1
  if [[ "$PACKAGE_URL" == https://* ]]; then
    curl -fL --proto '=https' --tlsv1.2 "$PACKAGE_URL" -o "$tmp_pkg"
  else
    cp "${PACKAGE_URL#file://}" "$tmp_pkg"
  fi
fi

actual_sha256="$(sha256sum "$tmp_pkg" | awk '{print $1}')"
[[ "$actual_sha256" == "$PACKAGE_SHA256" ]] || fail "Paket-Pruefsumme stimmt nicht. Download oder Image wurde veraendert."
package_size="$(stat -c %s "$tmp_pkg")"
(( package_size >= 1024 && package_size <= 300 * 1024 * 1024 )) || fail "VistaBoard-Paket hat eine ungueltige Groesse."

archive_names="$(mktemp /tmp/vistaboard-archive.XXXXXX.list)"
archive_types="$(mktemp /tmp/vistaboard-archive.XXXXXX.types)"
tar -tzf "$tmp_pkg" > "$archive_names" || fail "VistaBoard-Paket ist kein gueltiges tar.gz-Archiv."
entry_count="$(wc -l < "$archive_names" | tr -d ' ')"
(( entry_count > 0 && entry_count <= 10000 )) || fail "VistaBoard-Paket hat eine ungueltige Dateianzahl."
while IFS= read -r archive_name; do
  normalized="${archive_name#./}"
  [[ -z "$normalized" ]] && continue
  case "$normalized" in
    /*|../*|*/../*|*/..|-*) fail "Unsicherer Pfad im VistaBoard-Paket: $archive_name" ;;
  esac
done < "$archive_names"
tar -tvzf "$tmp_pkg" > "$archive_types" || fail "VistaBoard-Paket konnte nicht geprueft werden."
while IFS= read -r archive_line; do
  case "${archive_line:0:1}" in
    -|d) ;;
    *) fail "VistaBoard-Paket enthaelt unzulaessige Links oder Spezialdateien." ;;
  esac
done < "$archive_types"
rm -f "$archive_names" "$archive_types"

# Entpacken direkt ins App-Verzeichnis (nicht in dist/)
rm -rf "$APP_DIR/app.new"
mkdir -p "$APP_DIR/app.new"
tar -xzf "$tmp_pkg" -C "$APP_DIR/app.new" 2>/dev/null || tar --no-xattrs -xzf "$tmp_pkg" -C "$APP_DIR/app.new"
if (( package_is_temporary )); then rm -f "$tmp_pkg"; fi

# Falls Tarball ein Unterverzeichnis enthält, Inhalt hochziehen
if [[ ! -f "$APP_DIR/app.new/index.js" ]]; then
  subdir="$(find "$APP_DIR/app.new" -maxdepth 1 -mindepth 1 -type d | head -1)"
  if [[ -n "$subdir" && -f "$subdir/index.js" ]]; then
    mv "$subdir"/* "$APP_DIR/app.new/" 2>/dev/null || true
    mv "$subdir"/.* "$APP_DIR/app.new/" 2>/dev/null || true
    rmdir "$subdir" 2>/dev/null || true
  fi
fi

# Validate the complete runtime before replacing any existing installation.
for required in index.js package.json package-lock.json VERSION public/index.html; do
  [[ -f "$APP_DIR/app.new/$required" ]] || fail "VistaBoard-Paket ist unvollstaendig: $required fehlt."
done
new_index_size="$(stat -c %s "$APP_DIR/app.new/index.js" 2>/dev/null || echo 0)"
(( new_index_size > 10000 )) || fail "VistaBoard-Paket enthaelt eine unvollstaendige index.js."
/usr/bin/node --check "$APP_DIR/app.new/index.js" >/dev/null \
  || fail "VistaBoard-Paket enthaelt ungueltiges Server-JavaScript."
package_version="$(node -e '
  const fs = require("fs");
  const value = JSON.parse(fs.readFileSync(process.argv[1], "utf8")).version || "";
  if (!/^\d+\.\d+\.\d+(?:[-+][0-9A-Za-z.-]+)?$/.test(value)) process.exit(2);
  process.stdout.write(value);
' "$APP_DIR/app.new/package.json")" || fail "VistaBoard-Paket enthaelt eine ungueltige Version."
version_file="$(tr -d '[:space:]' < "$APP_DIR/app.new/VERSION")"
[[ "$package_version" == "$version_file" ]] || fail "VistaBoard-Paket hat widerspruechliche Versionsangaben."

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
chown -R "$APP_USER:$APP_USER" "$APP_DIR"
[[ -f package-lock.json ]] || fail "Gesperrte Node.js-Abhaengigkeiten fehlen."
runuser -u "$APP_USER" -- env NODE_OPTIONS=--max-old-space-size=384 \
  npm ci --omit=dev --ignore-scripts --legacy-peer-deps --no-audit --no-fund \
  || fail "Node.js-Abhaengigkeiten konnten nicht reproduzierbar installiert werden. Bitte Internetverbindung pruefen und erneut starten."
[[ -d node_modules/dotenv ]] || fail "Pflichtpaket dotenv fehlt nach der Installation."
ok "Abhaengigkeiten installiert"

# ── 6. Kiosk-Benutzer erkennen ───────────────────────────────────────────────
# A customer image passes the user created by Raspberry Pi Imager explicitly.
# This prevents a stale default account from becoming the kiosk account.
KIOSK_USER="${VISTABOARD_KIOSK_USER:-}"
if [[ -n "$KIOSK_USER" ]] && ! id "$KIOSK_USER" >/dev/null 2>&1; then
  KIOSK_USER=""
fi
if [[ -z "$KIOSK_USER" ]]; then
  for candidate in pi vista; do
    if id "$candidate" >/dev/null 2>&1; then KIOSK_USER="$candidate"; break; fi
  done
fi
if [[ -z "$KIOSK_USER" ]]; then
  for home in /home/*; do
    [[ -d "$home" ]] || continue
    u="$(basename "$home")"
    [[ "$u" == "$APP_USER" ]] && continue
    if id "$u" >/dev/null 2>&1; then KIOSK_USER="$u"; break; fi
  done
fi
KIOSK_USER="${KIOSK_USER:-pi}"
if ! id "$KIOSK_USER" >/dev/null 2>&1; then
  fail "Kein Raspberry-Pi-Benutzer gefunden. Bitte im Raspberry Pi Imager Benutzername und Passwort festlegen."
fi
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
DATABASE_URL=mysql://vistaboard:$DB_PASSWORD@localhost:3306/vistaboard
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
  log "Aktualisiere vorhandene .env ohne Kundeneinstellungen zu loeschen"
  set_env_value() {
    local key="$1" value="$2" env_tmp
    env_tmp="$(mktemp /tmp/vistaboard-env.XXXXXX)"
    grep -v "^${key}=" "$APP_DIR/.env" > "$env_tmp" || true
    printf '%s=%s\n' "$key" "$value" >> "$env_tmp"
    mv "$env_tmp" "$APP_DIR/.env"
  }
  set_env_value DATABASE_URL "mysql://vistaboard:$DB_PASSWORD@localhost:3306/vistaboard"
  set_env_value NODE_ENV production
  set_env_value PORT "$PORT"
  set_env_value VB_UPDATE_SERVER "$ZENTRALE_URL"
  set_env_value VISTABOARD_KIOSK_USER "$KIOSK_USER"
  set_env_value VISTABOARD_KIOSK_HOME "$KIOSK_HOME"
  set_env_value VISTABOARD_DISPLAY_HELPER_PATH "$KIOSK_HOME/.local/bin/vistaboard-display-helper.js"
  set_env_value VISTABOARD_DISPLAY_OUTPUT "$HDMI_OUTPUT"
  set_env_value VISTABOARD_ENTRY "$APP_START"
fi
chmod 600 "$APP_DIR/.env"
chown "$APP_USER:$APP_USER" "$APP_DIR/.env"
ok ".env konfiguriert"

# ── 8b. Desktop-Autologin fuer den vom Kunden gewaehlten Benutzer ───────────
# The credentials remain the customer's own Raspberry Pi Imager credentials.
if [[ -d /etc/lightdm/lightdm.conf.d || -f /etc/lightdm/lightdm.conf ]]; then
  mkdir -p /etc/lightdm/lightdm.conf.d
  cat > /etc/lightdm/lightdm.conf.d/99-vistaboard-autologin.conf <<EOF
[Seat:*]
autologin-user=$KIOSK_USER
autologin-user-timeout=0
user-session=rpd-labwc
autologin-session=rpd-labwc
EOF
  ok "Desktop-Autologin fuer $KIOSK_USER konfiguriert"
fi

# ── 9. Display-Helper installieren ───────────────────────────────────────────
log "Installiere Display-Helper..."
HELPER_DEST="$KIOSK_HOME/.local/bin/vistaboard-display-helper.js"
install -d -o "$KIOSK_USER" -g "$KIOSK_USER" -m 0755 "$(dirname "$HELPER_DEST")"

if [[ -f /boot/firmware/vistaboard/vistaboard-display-helper.js ]]; then
  cp /boot/firmware/vistaboard/vistaboard-display-helper.js "$HELPER_DEST"
elif [[ -f "$APP_DIR/display-helper.js" ]]; then
  cp "$APP_DIR/display-helper.js" "$HELPER_DEST"
fi

if [[ -f "$HELPER_DEST" ]]; then
  chmod 0755 "$HELPER_DEST"
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
Group=$APP_USER
WorkingDirectory=$APP_DIR
EnvironmentFile=$APP_DIR/.env
ExecStart=/usr/bin/node $APP_START
Restart=always
RestartSec=5
UMask=0077
NoNewPrivileges=true
PrivateTmp=true
ProtectSystem=strict
ProtectHome=read-only
ReadWritePaths=$APP_DIR ${APP_DIR}.bak $KIOSK_HOME/.config/labwc
ProtectKernelTunables=true
ProtectKernelModules=true
ProtectControlGroups=true
RestrictSUIDSGID=true
LockPersonality=true
CapabilityBoundingSet=
RestrictAddressFamilies=AF_UNIX AF_INET AF_INET6

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
CHROMIUM_FLAGS="--password-store=basic --kiosk --start-fullscreen --no-first-run --noerrdialogs --disable-infobars --disable-translate --disable-suggestions-ui --disable-features=TranslateUI,Translate --lang=de --ozone-platform=wayland --disable-gpu"

cat > /usr/local/bin/vistaboard-kiosk.sh <<EOF
#!/usr/bin/env bash
set -u
URL="http://127.0.0.1:$PORT/"
LOG="\${HOME:-/tmp}/.vistaboard-kiosk.log"
LOCK_DIR="\${XDG_RUNTIME_DIR:-/tmp}/vistaboard-kiosk.lock"

if ! mkdir "\$LOCK_DIR" 2>/dev/null; then
  exit 0
fi
trap 'rmdir "\$LOCK_DIR" 2>/dev/null || true' EXIT

{
  echo "[\$(date -Is)] VistaBoard kiosk waiting for \$URL"
  until curl -fsS "\$URL" >/dev/null 2>&1; do
    sleep 2
  done
  echo "[\$(date -Is)] VistaBoard server reachable, starting Chromium"
} >>"\$LOG" 2>&1

xset s off -dpms >>"\$LOG" 2>&1 || true
if ! pgrep -x unclutter >/dev/null 2>&1; then
  unclutter -idle 1 >>"\$LOG" 2>&1 &
fi

while true; do
  chromium $CHROMIUM_FLAGS "\$URL" >>"\$LOG" 2>&1 \\
    || chromium-browser --password-store=basic --kiosk --start-fullscreen --no-first-run --noerrdialogs --disable-infobars "\$URL" >>"\$LOG" 2>&1 \\
    || true
  echo "[\$(date -Is)] Chromium exited; restarting kiosk in 2s" >>"\$LOG" 2>&1
  sleep 2
done
EOF
chmod 0755 /usr/local/bin/vistaboard-kiosk.sh

# Das Hilfsprogramm laeuft absichtlich als unprivilegierter App-Benutzer.
# So kann ein Fehler in der Web-App niemals ueber den Updater zu root werden.
[[ -f "$APP_DIR/vistaboard-update.sh" ]] || fail "Sicheres Update-Script fehlt im VistaBoard-Paket."
install -o root -g root -m 0755 "$APP_DIR/vistaboard-update.sh" /usr/local/bin/vistaboard-update.sh
rm -f /etc/sudoers.d/vistaboard-update
ok "Unprivilegiertes Update-Script installiert"

if [[ -d "$KIOSK_HOME" ]]; then
  mkdir -p "$KIOSK_HOME/.config/labwc"
  cat > "$KIOSK_HOME/.config/labwc/autostart" <<EOF
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
