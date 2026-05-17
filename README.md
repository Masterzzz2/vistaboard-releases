<p align="center">
  <img src="https://github.com/Masterzzz2/vistaboard-releases/releases/download/v2.7.56/VistaBoard-2.7.56-Preview.png" alt="VistaBoard smart wall display preview" width="520">
</p>

# VistaBoard - Smart Wall Display for Raspberry Pi

VistaBoard turns a Raspberry Pi 2B / 3 / 4 / 5 or a comparable Linux mini PC into a smart portrait wall display for calendar, weather, photos, news, quotes and energy data.

It is designed for kitchens, hallways, offices, smart homes and PV/solar households that want one clean always-on screen instead of checking many separate apps.

## Features

- Apple/iCloud and Google calendar display
- Weather forecast with sunrise, sunset and optional weather details
- Photo display from Bing, Unsplash, iCloud/shared folders or local image sources
- RSS news ticker, quotes and custom information widgets
- Fronius PV data, battery status, grid import/export and wallbox status
- Tibber, flexible electricity prices or fixed electricity tariffs
- Portrait and landscape mode for wall-mounted displays
- Dark, pastel and flexible layouts
- Timezone and daylight saving time (DST) settings
- Full i18n: German and English UI
- 30-day trial and license activation
- Automatic updates from Vista Zentrale

## Supported Hardware

| Component | Requirement |
|-----------|-------------|
| Board | Raspberry Pi 5 (recommended), Pi 4, Pi 3, Pi 2B |
| RAM | 4 GB or 8 GB |
| Storage | MicroSD 16 GB minimum (32 GB recommended) |
| Power | USB-C 5V/5A (official Pi 5 PSU recommended) |
| Display | Any HDMI monitor or TV |
| Cable | Micro-HDMI to HDMI |
| Network | WiFi or Ethernet |

## Quick Install

> **Two commands** - that's all it takes.

```bash
# 1. Download the installer
curl -fsSL https://www.vista-board.com/downloads/vistaboard-install.sh -o vistaboard-install.sh

# 2. Run it
sudo bash vistaboard-install.sh
```

The installer handles everything automatically:
- System packages (Node.js, MariaDB, Chromium)
- Database setup
- VistaBoard download and configuration
- Systemd service
- Kiosk mode (fullscreen Chromium on reboot)

After installation, open `http://<PI-IP>:3000` in any browser.

## Step-by-Step Installation Guide

### 1. Prepare the SD Card

1. Download and install the [Raspberry Pi Imager](https://www.raspberrypi.com/software/) on your computer
2. Insert the MicroSD card
3. In the Imager, select:
   - **Device:** Your Raspberry Pi model (2B, 3, 4 or 5)
   - **OS:** Raspberry Pi OS (64-bit) Desktop (under "Raspberry Pi OS (other)")
   - **Storage:** Your MicroSD card
4. **Click the gear icon** (settings) before writing:
   - Set WiFi name and password
   - Set username and password (e.g. `pi`)
   - Enable SSH
5. Click **Write** and wait

### 2. Boot the Raspberry Pi

1. Insert the SD card into the Pi
2. Connect the monitor via HDMI (Pi 4/5: use the left Micro-HDMI port)
3. Connect keyboard and mouse via USB
4. Plug in the power supply - the Pi starts automatically
5. Wait for the desktop to appear (~1-2 minutes on first boot)

### 3. Open Terminal

Click the **black Terminal icon** in the taskbar (looks like `>_`).

Or connect remotely via SSH:
```bash
ssh pi@<IP-ADDRESS>
```

### 4. Run the Installer

```bash
curl -fsSL https://www.vista-board.com/downloads/vistaboard-install.sh -o vistaboard-install.sh
sudo bash vistaboard-install.sh
```

You will be asked for your password. **No characters are shown while typing** - this is normal.

Installation takes **5-15 minutes** depending on internet speed.

When you see **"VistaBoard erfolgreich installiert!"** - you're done!

### 5. First Setup

Open a browser (on the Pi or any device in the same network):

```
http://<PI-IP>:3000
```

VistaBoard guides you through:
1. Language selection (German / English)
2. Activation code (30-day free trial, no code needed)
3. Calendar setup (iCal URL from Google/Apple/Outlook)
4. Weather location
5. Done!

All settings can be changed anytime via the **gear icon** in the dashboard.

### 6. Kiosk Mode

After a reboot, VistaBoard starts automatically in fullscreen:

```bash
sudo reboot
```

The mouse cursor hides automatically. Display brightness and screen-off times can be configured in settings.

## Useful Commands

```bash
# Check status
sudo systemctl status vistaboard

# View logs
sudo journalctl -u vistaboard -n 50

# Restart
sudo systemctl restart vistaboard

# Find your Pi's IP
hostname -I
```

## Updates

VistaBoard checks for updates automatically. You can also trigger updates manually in **Settings > Updates**, or upload an update package manually.

## Download

The latest release is available here:

[Download VistaBoard releases](https://github.com/Masterzzz2/vistaboard-releases/releases/latest)

Website and full documentation:

[www.vista-board.com](https://www.vista-board.com) | [Installation Guide](https://www.vista-board.com/installation)

## Use Cases

VistaBoard is useful as a family calendar display, smart home dashboard, solar/PV energy monitor, wall-mounted weather display, kitchen information screen or Raspberry Pi dashboard.

## License

VistaBoard is proprietary software with a 30-day free trial. See [www.vista-board.com](https://www.vista-board.com) for pricing.

---

# Deutsch

VistaBoard macht aus einem Raspberry Pi 2B / 3 / 4 / 5 oder einem vergleichbaren Linux-Mini-PC ein smartes Wanddisplay im Hochformat.

Das Board zeigt Kalender, Wetter, Bilder, Nachrichten, Zitate und optional Energiedaten wie Fronius PV, Hausakku, Netzbezug, Einspeisung, Wallbox und Strompreise. Es ist gedacht fuer Kueche, Flur, Buero, Wohnzimmer, Technikraum oder Smart-Home-Installationen.

## Funktionen

- Apple/iCloud- und Google-Kalender
- Wettervorschau, Sonnenaufgang, Sonnenuntergang und optionale Wetterdetails
- Bilder von Bing, Unsplash, iCloud/geteilten Ordnern oder lokalen Quellen
- RSS-/Nachrichtenanzeige, Zitate und eigene Widgets
- Fronius PV-Daten, Hausakku, Netzbezug, Einspeisung und Wallbox-Status
- Tibber-Strompreise oder feste/flexible Stromtarife
- Hoch- und Querformat fuer Wanddisplays
- Dunkles Layout, Pastell-Layout und freies Layout
- Zeitzone und Sommerzeit (DST) einstellbar
- Vollstaendige Zweisprachigkeit: Deutsch und Englisch
- 30-Tage-Testphase und Lizenzaktivierung
- Automatische Updates ueber Vista Zentrale

## Schnellinstallation

```bash
# 1. Installer herunterladen
curl -fsSL https://www.vista-board.com/downloads/vistaboard-install.sh -o vistaboard-install.sh

# 2. Installation starten
sudo bash vistaboard-install.sh
```

Die ausfuehrliche Schritt-fuer-Schritt-Anleitung findest du auf der Homepage:

[www.vista-board.com/installation](https://www.vista-board.com/installation)

## Download

Die aktuelle Version findest du unter:

[VistaBoard Releases herunterladen](https://github.com/Masterzzz2/vistaboard-releases/releases/latest)

Homepage:

[www.vista-board.com](https://www.vista-board.com)
