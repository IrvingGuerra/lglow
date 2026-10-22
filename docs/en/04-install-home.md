# 4. Install the refreshed home

[Español](../04-instalar-home.md)

Requirements: a rooted TV (steps 1 to 3), root SSH access to the TV and, on your computer, `git`, `ssh` and Python 3 with
Pillow (`pip install pillow`, only needed to generate the tiles).

## Install

```bash
git clone https://github.com/IrvingGuerra/lglow && cd lglow
./instalar.sh 192.168.1.50        # your TV's IP (or an alias from ~/.ssh/config)
```

`instalar.sh` copies the `tv/` folder to the TV and runs `install.sh` there, which:

1. **Checks the version** of each home file that is going to be patched (md5 in `tv/patches/*/originales.md5`).
   If your firmware is different, it stops without touching anything.
2. Copies the original home QML to `/var/lib/webosbrew/fullhomecustom/qml` (and the old bar's QML to
   `/var/lib/webosbrew/homecustom/qml`), applies the patches and adds the new components.
3. Installs the boot scripts in `/var/lib/webosbrew/init.d/`: `10-homecustom` (mounts the home) and
   `60-sinprecarga` (turns off app preloading).
4. Applies it right away. Press Home and you're done.

Expected output (the installer's messages are in Spanish):

```text
==> com.webos.app.fullhome: revisando versión de los archivos originales
==> com.webos.app.fullhome: copiando el QML original y aplicando parches
==> com.webos.app.home: revisando versión de los archivos originales
==> com.webos.app.home: copiando el QML original y aplicando parches
==> copiando configuración, fondos y pantalla de carga
==> creado /var/lib/webosbrew/fullhomecustom/config.json: edítalo con tu ciudad y tu llave de TMDB
==> instalando scripts de arranque
==> aplicando ahora
==> listo. La pantalla de carga nueva se ve después del próximo reinicio.
```

## Set up "Para ti" (For you) and the weather

On the TV, edit `/var/lib/webosbrew/fullhomecustom/config.json`:

```json
{
    "tmdbKey": "your TMDB key (API Key v3)",
    "region": "MX",
    "language": "es-MX",
    "latitude": 19.4326,
    "longitude": -99.1332,
    "city": "Ciudad de México"
}
```

- **tmdbKey:** free at [themoviedb.org/settings/api](https://www.themoviedb.org/settings/api). Without a key, the
  home still works, but it only shows the date, time and weather.
- **region:** your two-letter country code. It decides which apps each title is available in.
- **latitude / longitude / city:** for the weather. Look up your coordinates on any map.

To pick up the changes, press Home twice or restart the TV.

### Other countries

TMDB providers vary by country. The ones built into the code are Mexico's. If you're in another
country, add `"providers"` to `config.json` with your region's ids and the app id on your TV:

```json
"providers": {
    "8":   ["Netflix", "netflix"],
    "337": ["Disney+", "com.disney.disneyplus-prod"],
    "119": ["Prime Video", "amazon"]
}
```

- Provider ids: `https://api.themoviedb.org/3/watch/providers/tv?watch_region=XX&api_key=TU_LLAVE`.
- App ids on your TV: `ssh -tt tv "luna-send -n 1 luna://com.webos.applicationManager/listLaunchPoints '{}'"`.

## Rectangular tiles for your apps

The large tiles in each brand's color are generated from the icons already on your TV:

```bash
python3 tools/make-tiles.py 192.168.1.50
```

The script downloads each app's icon, detects its background color, builds a 300×180 PNG with rounded
corners and uploads it to `/var/lib/webosbrew/fullhomecustom/tiles/`. **Run it again whenever you install a
new app.** Without a tile, the app shows its icon on top of its color.

## Hidden apps

On the TV, `/var/lib/webosbrew/fullhomecustom/apps-ocultas.txt` lists one app per line. By default it hides the
web browser, LG Content Store, Photo & Video, Music, Home Dashboard and Developer Mode. **They are not uninstalled**:
they just don't appear on the home. After editing it, run `./instalar.sh <ip-tv>` again.

> If you hide LG Content Store and want to install an app, remove it from the list for a moment or open it with
> `ssh -tt tv "luna-send -n 1 luna://com.webos.applicationManager/launch '{\"id\":\"com.webos.app.discovery\"}'"`.

## Pin and reorder apps

The home pins the **first 6 apps** in LG's order. To change them: ↓ down to all apps →
pencil **✎** at the end → LG's edit mode opens: select an app with OK, move it and confirm with OK.

## Background

The home has a **light, dark or automatic theme** (light by day, dark by night, following your city's
sunrise and sunset). Pick it with the theme button at the top (the half-filled circle); the TV remembers it.

Each theme has its own background: light uses `fondo.jpg` (the light "pearl" one by default) and dark uses
`fondo-aurora.jpg`. You can replace either with any 1920×1080 JPG, for example:

```bash
scp my-background.jpg root@<tv-ip>:/var/lib/webosbrew/fullhomecustom/fondo.jpg
```

Use a light image for `fondo.jpg` and a dark one for `fondo-aurora.jpg`: the text changes color with the theme.

## Update or uninstall

- **Update:** `git pull && ./instalar.sh <ip-tv>`. Keeps your `config.json`, your hidden apps, the background and
  the tiles.
- **Disable without deleting:** `ssh tv touch /var/lib/webosbrew/homecustom/DESACTIVADO` and restart.
- **Uninstall:** `./instalar.sh <ip-tv> --quitar` and restart. This brings back LG's original home.

Next: **[5. How it works](05-how-it-works.md)** or **[6. Cleanup and memory](06-cleanup-and-memory.md)**.
