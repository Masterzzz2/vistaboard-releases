<p align="center">
  <a href="https://www.vista-board.com">
    <img src="vistaboard-preview.png" alt="Vista-Board Raspberry Pi wall display for calendars, weather, energy and smart home" width="820">
  </a>
</p>

<h1 align="center">Vista-Board</h1>

<p align="center">
  <strong>Raspberry Pi calendar display and smart wall dashboard for families, smart homes and solar households.</strong><br>
  Apple iCloud, Google Calendar, weather, photos, PV energy, Tesla battery state, wallbox status and Tibber prices — on one always-visible screen.
</p>

<p align="center">
  <a href="https://github.com/Masterzzz2/vistaboard-releases/releases/latest"><img src="https://img.shields.io/github/v/release/Masterzzz2/vistaboard-releases?label=latest%20download&color=success" alt="Latest download"></a>
  <a href="https://www.vista-board.com/raspberry-pi-calendar-display/"><img src="https://img.shields.io/badge/Raspberry%20Pi-calendar%20display-7c3aed" alt="Raspberry Pi calendar display"></a>
  <a href="https://www.vista-board.com/installation"><img src="https://img.shields.io/badge/setup-guided-brightgreen" alt="Guided setup"></a>
  <a href="https://www.vista-board.com/tester/en/"><img src="https://img.shields.io/badge/tester-30%20day%20trial-orange" alt="Become a tester"></a>
  <img src="https://img.shields.io/badge/platform-Raspberry%20Pi%20%7C%20Linux%20mini--PC-red" alt="Platform">
</p>

<p align="center">
  <a href="https://www.vista-board.com/installation"><strong>Installation guide</strong></a> ·
  <a href="https://github.com/Masterzzz2/vistaboard-releases/releases/latest"><strong>Latest release</strong></a> ·
  <a href="https://www.vista-board.com/raspberry-pi-calendar-display/"><strong>Raspberry Pi calendar display</strong></a> ·
  <a href="https://www.vista-board.com/tester/en/"><strong>Become a tester</strong></a> ·
  <a href="https://www.vista-board.com/business/en/"><strong>Business displays</strong></a>
</p>

---

## What is Vista-Board?

Vista-Board turns a Raspberry Pi, Linux mini-PC or old display setup into an always-on information screen for the kitchen, hallway, office, workshop, waiting room, hotel room or lobby.

It brings the things people check several times a day onto one shared screen:

- family calendar, birthdays and waste collection dates
- local weather and forecast
- personal photos or calm background images
- RSS news ticker, quotes, reminders and custom information widgets
- PV / solar production, home battery, grid import/export and electricity prices
- wallbox, EV charging and Tesla battery state
- smart-home values such as Shelly, SmartLife/Tuya or pool temperature

**No coding. No YAML. No cloud display account required for the dashboard itself.**

Vista-Board runs locally in your home network. Optional online services are only used for the data sources you enable, such as calendar sync, weather, photos, energy prices or Tesla data.

## Download: choose the right start

| If you want... | Use this | Link |
| --- | --- | --- |
| The easiest first setup | Ready-made Raspberry Pi SD card image | [SD image release](https://github.com/Masterzzz2/vistaboard-releases/releases/tag/sd-image) or [installation page](https://www.vista-board.com/installation) |
| Existing Raspberry Pi OS / Debian / Ubuntu | Installer script | [Installation guide](https://www.vista-board.com/installation) |
| To understand the product first | Website and screenshots | [vista-board.com](https://www.vista-board.com) |
| Help testing and give feedback | Tester flow | [Become a tester](https://www.vista-board.com/tester/en/) |
| A hotel, lobby, practice or office display | Custom project page | [Business / project displays](https://www.vista-board.com/business/en/) |

### Which image should I download?

- **Raspberry Pi 3 / 4 / 5:** use `VistaBoard-RaspberryPi-64bit.img.xz` from the [SD image release](https://github.com/Masterzzz2/vistaboard-releases/releases/tag/sd-image).
- **Raspberry Pi 2B:** use `VistaBoard-RaspberryPi-Pi2B-32bit.img.xz` from the [SD image release](https://github.com/Masterzzz2/vistaboard-releases/releases/tag/sd-image).
- **Mini PC / existing Linux:** use the installer script instead of an SD card image.

If you are unsure, start with the installation page: <https://www.vista-board.com/installation>

## Who is Vista-Board for?

| Use case | Why it helps |
| --- | --- |
| **Families** | One shared calendar on the kitchen wall, visible without opening a phone. |
| **Smart-home users** | Weather, reminders, news and sensor values in one calm dashboard. |
| **Solar / PV owners** | See production, battery, grid import/export and electricity prices at a glance. |
| **EV owners** | Show wallbox status, charging power and Tesla battery level on the wall. |
| **Old display / iPad reuse** | Give old screens a useful second life as a household display. |
| **Offices, hotels and waiting rooms** | Build a custom info display for reception, lobby, meeting room or guest TV. |

## Why people use it

| Problem | Vista-Board solves it by showing... |
| --- | --- |
| Family appointments are hidden on phones | shared Apple iCloud, Google, Outlook, Nextcloud and iCal calendars |
| A paper calendar is always outdated | live calendar changes on a large wall display |
| Smart-home information is split across apps | weather, photos, news, reminders and widgets in one place |
| Solar, Tesla and energy data are hidden in vendor apps | Fronius PV, home battery, grid import/export, Tesla battery state, wallbox and Tibber prices |
| MagicMirror is too technical for everyday use | a guided wall display product instead of a module/config project |
| DAKboard or tablet apps feel too limited | local dashboard software that can be adapted to your own display and data sources |

## Easiest setup: ready-made Raspberry Pi image

For beginners, the recommended installation is the ready-made Vista-Board Raspberry Pi image. You do not need to install Linux manually and you do not need terminal commands for the first start.

1. Download the SD card image from the [SD image release](https://github.com/Masterzzz2/vistaboard-releases/releases/tag/sd-image) or start from [vista-board.com/installation](https://www.vista-board.com/installation).
2. Install [Raspberry Pi Imager](https://www.raspberrypi.com/software/) on Windows, macOS or Linux.
3. In Raspberry Pi Imager choose your Pi model, then **Choose OS > Use custom image**.
4. Select the downloaded `.img.xz` file. Do not unzip it.
5. Choose your microSD card, enter Wi-Fi in the advanced settings if needed, and write the card.
6. Insert the card into the Raspberry Pi, connect HDMI and power. The first boot can take a few minutes.
7. Open `http://<PI-IP>:3000` from a phone, tablet or computer in the same network and follow the setup wizard.

Printable beginner PDF in German and English: [Vista-Board image guide](https://www.vista-board.com/downloads/vistaboard-image-anleitung.pdf)

### Quick decision: image or installer?

| Option | Best for | What you do |
| --- | --- | --- |
| **Ready-made image** | Beginners and new Raspberry Pi setups | Flash one `.img.xz` file to the SD card |
| **Installer script** | Existing Raspberry Pi OS / Debian / Ubuntu systems | Run the install command in a terminal |

## Quick install on existing Raspberry Pi OS / Debian / Ubuntu

```bash
curl -fsSL https://www.vista-board.com/downloads/vistaboard-install.sh -o vistaboard-install.sh
sudo bash vistaboard-install.sh
```

Then open `http://<PI-IP>:3000` in any browser and follow the setup wizard.

Full guide: <https://www.vista-board.com/installation>

## Features

### Calendar and everyday information

- Apple iCloud, Google Calendar, Outlook, Nextcloud, CalDAV and any iCal/ICS URL
- multiple calendars with individual colors
- weather forecast with sunrise, sunset, alerts and detailed conditions
- photos from Bing, Unsplash, iCloud/shared folders or local folders
- RSS/news ticker, quotes, reminders, countdowns and custom widgets

### Energy, EV and smart home

- Fronius PV inverter: real-time solar production, battery, grid import/export
- home battery charge status and power flow
- wallbox / EV charging status
- Tesla battery state, estimated range and charging status when connected
- Tibber dynamic electricity prices
- EPEX spot prices with custom surcharges
- fixed or flexible electricity tariffs
- Shelly, SmartLife/Tuya, pool and external data widgets

### Display and system

- portrait and landscape mode for wall-mounted monitors
- dark, pastel and free-position layouts
- browser-based settings from phone, tablet or computer
- German and English interface
- automatic OTA updates with rollback safety
- backup and restore of settings
- 30-day trial, then monthly or annual licence
- optional Vista AI beta for voice/text questions on the board

## Hardware requirements

| Component | Requirement |
| --- | --- |
| **Board** | Raspberry Pi 5 recommended; Pi 4, Pi 3 and Pi 2B supported depending on image/install path |
| **RAM** | 2 GB minimum, 4 GB recommended |
| **Storage** | microSD 16 GB+; 32 GB or SSD recommended |
| **Display** | HDMI monitor, TV or touchscreen; 24–27 inch portrait display works well |
| **Network** | Wi-Fi or Ethernet |
| **OS** | Raspberry Pi OS, Debian or Ubuntu for installer-based setup |

Also works on Linux mini PCs, old laptops or other Debian-based systems with a browser.

## Pricing

| Plan | Price | Notes |
| --- | --- | --- |
| **Trial** | 30 days | all features, no payment details for the trial |
| **Monthly** | 2.99 EUR/month | cancel anytime |
| **Yearly** | 29.49 EUR/year | lower yearly cost |

Activate directly in Vista-Board settings via PayPal. One licence per device.

## FAQ

### Is Vista-Board open source?

This repository is used for public releases, downloads and installation assets. The product itself is distributed as Vista-Board software with a 30-day trial and paid licence after the trial.

### Does the dashboard require a cloud account?

No proprietary Vista-Board cloud account is required for the local dashboard display. The software runs on your Raspberry Pi or Linux mini PC. External services such as Google Calendar, iCloud, weather data, Fronius, Tesla or Tibber are only used when you configure those features.

### Can I use it as a DAKboard or MagicMirror alternative?

Yes. Vista-Board is especially useful if you want a guided Raspberry Pi wall display for calendars, photos, weather and energy data without maintaining a custom dashboard project.

### Can Vista-Board show Tesla data?

Yes. Vista-Board can show Tesla battery state, estimated range and charging status when Tesla is connected in the settings. This is useful together with PV, wallbox and electricity prices because the car becomes part of the visible home-energy overview.

### Can it be used in hotels, lobbies or waiting rooms?

Yes. Vista-Board can be adapted as an information display for hotel rooms, reception areas, meeting rooms, practices and small businesses. Start here: <https://www.vista-board.com/business/en/>

### Where do I get support?

Use the website support page or email support@vista-board.com. If you are testing the software, the tester page explains what feedback is most helpful.

## Useful links

- Website: <https://www.vista-board.com>
- Raspberry Pi calendar display: <https://www.vista-board.com/raspberry-pi-calendar-display/>
- Installation guide: <https://www.vista-board.com/installation>
- Latest release: <https://github.com/Masterzzz2/vistaboard-releases/releases/latest>
- SD image release: <https://github.com/Masterzzz2/vistaboard-releases/releases/tag/sd-image>
- Tester page: <https://www.vista-board.com/tester/en/>
- DAKboard alternative: <https://www.vista-board.com/dakboard-alternative/en/>
- Tesla / EV charging wall display: <https://www.vista-board.com/tesla-battery-wall-display/>
- Tesla battery state article: <https://www.vista-board.com/blog/tesla-ladestand-auf-wanddisplay-anzeigen/en/>
- Business / project displays: <https://www.vista-board.com/business/en/>
- Support: support@vista-board.com

## Useful commands

```bash
sudo systemctl status vistaboard    # Check service status
sudo journalctl -u vistaboard -n 50 # View logs
sudo systemctl restart vistaboard   # Restart service
hostname -I                         # Find Pi IP address
```

---

# Deutsch

<p align="center">
  <strong>Raspberry-Pi-Kalender und smartes Wanddisplay fuer Familie, Smart Home und PV-Haushalte.</strong><br>
  Apple iCloud, Google Kalender, Wetter, Fotos, PV-Energie, Tesla-Ladestand, Wallbox und Tibber-Strompreise — ein Bildschirm fuer alles.
</p>

<p align="center">
  <a href="https://www.vista-board.com/installation"><strong>Installationsanleitung</strong></a> ·
  <a href="https://github.com/Masterzzz2/vistaboard-releases/releases/latest"><strong>Aktuelles Release</strong></a> ·
  <a href="https://www.vista-board.com/tester/"><strong>Tester werden</strong></a> ·
  <a href="https://www.vista-board.com/business/"><strong>Projektkunden</strong></a>
</p>

## Was ist Vista-Board?

Vista-Board macht aus einem Raspberry Pi oder Linux-Mini-PC ein dauerhaft sichtbares Wanddisplay. Es zeigt Familienkalender, Wetter, Fotos, Nachrichten und optional PV-Daten, Hausakku, Tesla-Ladestand, Wallbox und Strompreise.

Typische Einsaetze:

- **digitaler Familienkalender** in Kueche oder Flur
- **Raspberry-Pi-Wandkalender** fuer Apple iCloud und Google Kalender
- **Smart-Home-Dashboard** mit Wetter, Fotos, Nachrichten und Erinnerungen
- **PV-/Solar-Dashboard** fuer Fronius, Hausakku, Tesla-Ladestand, Wallbox und Tibber
- **Info-Display** fuer Buero, Wartezimmer, Lobby, Hotelzimmer oder Ferienwohnung

**Kein Programmieren. Keine YAML-Dateien. Kein Cloud-Display-Konto fuer die Anzeige selbst.**

## Download: welcher Weg ist richtig?

| Wenn du ... | Nimm diesen Weg | Link |
| --- | --- | --- |
| moeglichst einfach starten willst | fertiges Raspberry-Pi-SD-Karten-Image | [SD-Image-Release](https://github.com/Masterzzz2/vistaboard-releases/releases/tag/sd-image) oder [Installationsseite](https://www.vista-board.com/installation) |
| schon Raspberry Pi OS / Debian / Ubuntu installiert hast | Installationsskript | [Installationsanleitung](https://www.vista-board.com/installation) |
| erst verstehen willst, was Vista-Board macht | Webseite und Screenshots | [vista-board.com](https://www.vista-board.com) |
| Feedback geben und testen willst | Tester-Seite | [Tester werden](https://www.vista-board.com/tester/) |
| Hotel, Lobby, Praxis oder Buero ausstatten willst | Projektkunden-Seite | [Projektkunden](https://www.vista-board.com/business/) |

### Welche Datei brauche ich?

- **Raspberry Pi 3 / 4 / 5:** `VistaBoard-RaspberryPi-64bit.img.xz` aus dem [SD-Image-Release](https://github.com/Masterzzz2/vistaboard-releases/releases/tag/sd-image) verwenden.
- **Raspberry Pi 2B:** `VistaBoard-RaspberryPi-Pi2B-32bit.img.xz` aus dem [SD-Image-Release](https://github.com/Masterzzz2/vistaboard-releases/releases/tag/sd-image) verwenden.
- **Mini-PC / bestehendes Linux:** Installationsskript statt SD-Karten-Image verwenden.

Wenn du unsicher bist, starte mit der Installationsseite: <https://www.vista-board.com/installation>

## Warum Vista-Board?

| Problem | Vista-Board zeigt ... |
| --- | --- |
| Termine sind auf mehreren Handys verteilt | Apple iCloud, Google, Outlook, Nextcloud und iCal-Kalender gemeinsam |
| Papierkalender ist sofort veraltet | Live-Aenderungen auf einem grossen Wanddisplay |
| Smart-Home-Daten stecken in vielen Apps | Wetter, Fotos, Nachrichten, Erinnerungen und Widgets an einem Ort |
| PV, Tesla und Energie liegen in Hersteller-Apps | Fronius PV, Hausakku, Netzbezug/Einspeisung, Tesla, Wallbox und Tibber |
| MagicMirror ist zu technisch | gefuehrtes Produkt statt Modul-/Config-Projekt |

## Einfachster Start: fertiges Raspberry-Pi-Image

Fuer Einsteiger ist das fertige Vista-Board Raspberry-Pi-Image der beste Weg. Du musst Linux nicht manuell installieren und fuer den ersten Start keine Terminalbefehle eingeben.

1. SD-Karten-Image aus dem [SD-Image-Release](https://github.com/Masterzzz2/vistaboard-releases/releases/tag/sd-image) laden oder auf [vista-board.com/installation](https://www.vista-board.com/installation) starten.
2. [Raspberry Pi Imager](https://www.raspberrypi.com/software/) installieren.
3. Im Imager dein Pi-Modell waehlen, dann **OS waehlen > Eigenes Image verwenden**.
4. Die heruntergeladene `.img.xz`-Datei auswaehlen. Nicht entpacken.
5. microSD-Karte auswaehlen, bei Bedarf WLAN eintragen und Karte schreiben.
6. Karte in den Raspberry Pi stecken, HDMI und Strom anschliessen. Der erste Start kann einige Minuten dauern.
7. `http://<PI-IP>:3000` von Handy, Tablet oder Computer im selben Netzwerk oeffnen und dem Assistenten folgen.

Druckbare Einsteiger-Anleitung als PDF: [Vista-Board Image-Anleitung](https://www.vista-board.com/downloads/vistaboard-image-anleitung.pdf)

## Manuelle Installation auf Raspberry Pi OS / Debian / Ubuntu

```bash
curl -fsSL https://www.vista-board.com/downloads/vistaboard-install.sh -o vistaboard-install.sh
sudo bash vistaboard-install.sh
```

Danach `http://<PI-IP>:3000` im Browser oeffnen und dem Assistenten folgen.

## Funktionen

- Apple iCloud, Google Kalender, Outlook, Nextcloud, CalDAV und iCal/ICS
- Wetter, Sonnenaufgang, Sonnenuntergang, Warnungen und Details
- Fotos von Bing, Unsplash, iCloud/geteilten Ordnern oder lokalen Ordnern
- RSS-News, Zitate, Erinnerungen, Countdown und eigene Widgets
- Fronius PV, Hausakku, Netzbezug/Einspeisung
- Tesla-Ladestand, Reichweite und Ladestatus bei verbundener Tesla-Anbindung
- Wallbox / E-Auto-Ladestatus
- Tibber, EPEX und Stromtarife
- Hochformat, Querformat, dunkle, Pastell- und freie Layouts
- Einstellungen im Browser von Handy, Tablet oder Computer
- automatische Updates mit Rollback-Sicherheit
- optionale Vista-KI-Beta fuer Sprach- und Textfragen am Board

## Preise

| Tarif | Preis | Hinweis |
| --- | --- | --- |
| **Testphase** | 30 Tage | alle Funktionen, keine Zahlungsdaten fuer den Test |
| **Monatlich** | 2,99 EUR/Monat | jederzeit kuendbar |
| **Jaehrlich** | 29,49 EUR/Jahr | guenstiger als monatlich |

Die Aktivierung erfolgt direkt in Vista-Board per PayPal. Eine Lizenz gilt fuer ein Board/Geraet.

## Links

- Webseite: <https://www.vista-board.com>
- Raspberry-Pi-Kalender: <https://www.vista-board.com/raspberry-pi-calendar-display/>
- Installationsanleitung: <https://www.vista-board.com/installation>
- Aktuelles Release: <https://github.com/Masterzzz2/vistaboard-releases/releases/latest>
- SD-Image-Release: <https://github.com/Masterzzz2/vistaboard-releases/releases/tag/sd-image>
- Tester-Seite: <https://www.vista-board.com/tester/>
- DAKboard-Alternative: <https://www.vista-board.com/dakboard-alternative/>
- Tesla-Ladestand auf dem Wanddisplay: <https://www.vista-board.com/blog/tesla-ladestand-auf-wanddisplay-anzeigen/>
- Projektkunden: <https://www.vista-board.com/business/>
- Support: support@vista-board.com

---

<p align="center">
  Made with care in Germany · Vista-Board by Werner Goller
</p>
