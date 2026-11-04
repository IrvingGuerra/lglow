# 6. Cleanup and memory

[Español](../06-limpieza-y-memoria.md)

The test TV has **674 MB of RAM**, and the system alone already uses ~490 MB at idle. Every megabyte counts.

## What the refreshed home does on its own

| What | Savings |
| --- | --- |
| The old bar (`com.webos.app.home`) stops running | ~47 MB |
| No content rows or downloaded banners in the home | fewer images in memory and less network traffic |
| `60-sinprecarga`: LG no longer preloads Netflix, YouTube, Prime, Browser or Tips | Netflix alone took ~99 MB (RAM + swap) |

LG's preloader (`com.webos.service.preloadmanager`) launched Netflix ~65 s after power-on, even though
`getPreloadPolicy` reported it as disabled. `sin-precarga.sh` disables each app's policy
(`setPreloadPolicy '{"application":{"id":"…","isEnabled":false}}'`: a singular object; an array fails) and,
as a safety net, for 3 minutes it closes Netflix if it shows up running without you having opened it. The
preloads for the home, HDMI and live TV are kept, so the Home key and the inputs stay fast.

The cost: the first time you open Netflix after turning on the TV, it takes a few seconds longer.

## Turning off ads and extras (optional)

```bash
scp tv/extras/ajustes-sin-publicidad.sh root@<ip-tv>:/tmp/
ssh root@<ip-tv> sh /tmp/ajustes-sin-publicidad.sh
```

| Setting | What it is | Factory default |
| --- | --- | --- |
| `general.screenSaverAd` | Ads in the screen saver | on |
| `general.adCookie` | Advertising cookie | on |
| `option.watchedListCollection` | Collection of what you watch | on |
| `option.webOSPromotionVideo` | webOS promotional video | on |
| `option.animationGuide` | Guide animations | on |
| `option.helpOnSettings` | Help in settings | on |
| `option.menuTransparency` | Menu transparency (less work for the GPU) | on |
| `option.channelplus` | LG Channels | on |
| `option.smartSoundDemo` | Sound demo | on |

To revert a setting, set it back to `"on"` with `setSystemSettings`.

## LG ads and telemetry out (/etc/hosts)

LGlow installs `tools/bloqueo.sh`, which runs on every power-on from `init.d/15-bloqueo`. It adds the list in
`tools/bloqueo-dominios.txt` to `/etc/hosts`, pointing to `127.0.0.1` and `::1`, the same way Homebrew Channel does
with the update servers ([guide 3](03-access-and-updates.md)). The TV reads `/etc/hosts` before DNS, so those
connections fail instantly, with no waiting.

- It writes to the copy of `/etc/hosts` that Homebrew mounts in `/tmp` and to the copies of the apps that run in a
  "jail" (`/var/palm/jail/<app>/etc/hosts`, like Netflix and Prime Video). Nothing is written to LG's partition.
- The lines go between `# lglow-bloqueo: inicio` and `# lglow-bloqueo: fin`, so they can be removed without
  touching Homebrew's.
- In the list, `{pais}` is the TV's country code (for example `mx`) and `{region}` expands to `aic`, `eic` and
  `kic` (LG's data centers). On the test TV that comes to 26 domains.

### What it blocks

| Domains | What they're for |
| --- | --- |
| `lgsmartad.com`, `<country>.ad.lgsmartad.com`, `<country>.info.lgsmartad.com` | LG Smart Ad: ads on the home and in the screen saver |
| `ad.lgappstv.com`, `<country>.ibs.lgappstv.com`, `<country>.ibsstat.lgappstv.com` | Store banners and their stats |
| `<country>.rdx2.lgtvsdp.com` | Usage reports |
| `<region>.cdpbeacon`, `cdpsvc`, `homeprv`, `nudge`, `recommend`, `rdl` `.lgtvcommon.com` | Telemetry: what you watch, recommendations, promotions and logs |

### What it lets through, on purpose

`<country>.lgtvsdp.com`, `ngfts.lge.com` (and `<region>-ngfts.lge.com`) and `<region>.imagesvc.lgtvcommon.com` are
**not** blocked: the LG store needs them to load its services and images. Tested on the test TV: the LG Content
Store loads with its images, and Netflix and YouTube open normally.

### What it can't do

Ads **inside** YouTube or Prime Video come from the same domains as the video: blocking them via `/etc/hosts`
would break the app. That's what **YouTube AdFree** and **AmazOff**, in Homebrew Channel, are for.

### Turn off, remove, check and add domains

| I want to… | How |
| --- | --- |
| Turn it off without uninstalling | `"bloqueoAnuncios": false` in `/var/lib/webosbrew/fullhomecustom/config.json` and restart, or run `sh /var/lib/webosbrew/tools/bloqueo.sh` |
| Remove the lines by hand | `sh /var/lib/webosbrew/tools/bloqueo.sh --quitar` (`uninstall.sh` removes them too) |
| Check that it works | `ping -c1 mx.ad.lgsmartad.com` on the TV should show `127.0.0.1`; `tail -5 /etc/hosts` shows the end of the block |
| Add a domain | Edit `/var/lib/webosbrew/tools/bloqueo-dominios.txt` and restart or run `bloqueo.sh` |

> Heads up: `install.sh` copies `bloqueo-dominios.txt` from the repo again every time you reinstall. If you added
> domains on the TV, also save them in `tv/bloqueo-dominios.txt` in your copy.

### What about the router?

If you'd rather block on the router (Pi-hole, AdGuard Home, NextDNS), the community list for TVs is
[`SmartTV.txt` from Perflyst/PiHoleBlocklist](https://github.com/Perflyst/PiHoleBlocklist). They don't get in each
other's way: the TV's `/etc/hosts` and the router complement each other.

## Measured results

| | Before | After |
| --- | --- | --- |
| Free RAM at idle | ~106 MB | ~160–250 MB |
| Swap in use at idle | ~265 MB | ~12–35 MB |
| Home (`fullhome`, RSS) | ~77 MB + 42 MB of swap | ~76 MB |

## How much faster does it get?

Time until the app is in the foreground, measured after a reboot:

| | Time |
| --- | --- |
| YouTube, cold | 2.5 s |
| Prime Video, cold | 3.2 s |
| Switching between the two, both already open | 2.4 to 3.3 s |

Switching between apps that are already open costs almost the same as opening them cold. With two apps open, swap climbs
to ~140 MB: the TV either swaps out the one you're not watching or reloads it. **The bottleneck is the RAM and the 2019
chip.** This project prevents stutters at idle and frees memory, but it doesn't make switching between apps
instant.

### Quick Start+

With Quick Start+ on (*Settings → General → Quick Start+*), the TV suspends instead of shutting down:
it turns on instantly and keeps the refreshed home across power-ons, without the ~45 s window with LG's design.
It uses a bit more power in standby. If you use it, root and the scripts only run again after a real reboot
or after unplugging the TV. *(Tested: the test TV has it on; it turns on instantly and the refreshed home is
still there.)*

Next: **[7. Troubleshooting and uninstall](07-troubleshooting-and-uninstall.md)**.
