<div align="center">

# LGlow

**Bring your old LG TV back to life.** A clean, fast, ad-free home screen for 2019 LG TVs on webOS 4.x,
built on top of the stock one.

[Español](README.md) · [Before and after](#before-and-after) · [Compatibility](#compatibility) · [Install](#install)

</div>

> [!WARNING]
> This requires a **rooted TV**. Use at your own risk. Everything in this repo is reversible and **never writes
> to LG's read-only partitions**, but mistakes in other rooting steps (not this project) can brick a TV.

The detailed guides are in Spanish (`docs/`). Commands and file paths are the same in any language.

## Before and after

| Before (stock LG home) | After |
| --- | --- |
| ![Stock LG home with banner and sponsored rows](docs/img/antes-home.jpg) | ![Refreshed home: For you, weather and one row of apps](docs/img/despues-home.jpg) |

| Movies / Shows tabs | All apps screen |
| --- | --- |
| ![Movies tab with a title selected](docs/img/despues-titulo.jpg) | ![All apps screen](docs/img/despues-apps.jpg) |

## What you get

- **No LG ads on the home screen:** no banner, no sponsored content rows, no screensaver ads.
- **"Para ti" (For you):** three trending titles every hour, **only from apps you have** ([TMDB](https://www.themoviedb.org)),
  with Explore / Movies / Shows tabs. OK opens the app that has it.
- **Weather, date and time** for your city ([Open-Meteo](https://open-meteo.com), no key needed).
- **Big rectangular app tiles** in each brand's color, **one row** of 5 pinned apps, and an **Apps** screen with
  the rest.
- **Hide apps** you don't use, without uninstalling them.
- **More free memory:** the old launcher bar stops running and LG stops preloading Netflix/YouTube/Prime.
  On the test TV, free RAM at idle went from ~106 MB to ~160–250 MB and swap in use from ~265 MB to ~30 MB.
- **Root protection:** disables a Developer Mode trap that **wipes Homebrew Channel and root** on reboot when
  the LG Developer Mode app is still installed ([details](docs/02-trampa-developer-mode.md)).

## Compatibility

- **Tested on:** LG 43LM5770PUA (2019), webOS 4.10.2 (Rockhopper 4.10.2-29), firmware 05.40.97.
- **Should work on:** other 2019 LGs on webOS 4.5 with the 2025 home (`com.webos.app.fullhome`). The installer
  **checks the md5 of every file it patches** and stops without changing anything if they don't match.
- **Requires:** root via [faultmanager-autoroot](https://github.com/throwaway96/faultmanager-autoroot) +
  [Homebrew Channel](https://github.com/webosbrew/webos-homebrew-channel), and SSH root access.
- **Not for** webOS 5+. For webOS 10, see [mareklarek/webos10-homescreen-customization](https://github.com/mareklarek/webos10-homescreen-customization).

## Install

```bash
git clone https://github.com/IrvingGuerra/lglow && cd lglow
./instalar.sh 192.168.1.50                 # your TV's IP
ssh root@192.168.1.50 vi /var/lib/webosbrew/fullhomecustom/config.json   # TMDB key, city, coordinates
python3 tools/make-tiles.py 192.168.1.50   # rectangular tiles from your TV's app icons
```

Uninstall: `./instalar.sh 192.168.1.50 --quitar`, then reboot the TV.

If you're outside Mexico, add your country's TMDB provider ids to `config.json`
(see [docs/04-instalar-home.md](docs/04-instalar-home.md#otros-países)). UI text is in Spanish.

## How it works (short version)

- The installer copies the stock QML from your TV to `/var/lib/webosbrew`, applies the patches in
  `tv/patches/` and adds three new components (`tv/qml/`). **No LG code is distributed.**
- A boot script (`init.d/10-homecustom`) `mount --bind`s the patched copy over the original.
- **The CRIU trick:** on webOS 4 the home is *restored* from a factory CRIU image that already holds the stock
  QML in memory. The script covers `/tmp/checkpoint/<app>` and `/mnt/lg/cmn_data/checkpoint/<app>` with an
  empty folder so the home cold-starts and reads the mounted QML.
- Root starts ~42 s after power-on, so the stock design is visible for the first ~45 s after a full boot.

Full technical notes: [docs/05-como-funciona.md](docs/05-como-funciona.md).

## Credits

[faultmanager-autoroot](https://github.com/throwaway96/faultmanager-autoroot),
[Homebrew Channel / webosbrew](https://www.webosbrew.org),
[webos10-homescreen-customization](https://github.com/mareklarek/webos10-homescreen-customization) (the
bind-mount idea), [Free My TV](https://github.com/simbasjungles/free-my-tv) (the design),
[TMDB](https://www.themoviedb.org) (this product uses the TMDB API but is not endorsed or certified by TMDB)
and [Open-Meteo](https://open-meteo.com).

## License

MIT for everything in this repo. LG's home screen code is not included. Not affiliated with LG.
