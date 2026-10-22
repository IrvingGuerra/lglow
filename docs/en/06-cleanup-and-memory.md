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
or after unplugging the TV. *(Not tested on the test TV, which was left with Quick Start+ off.)*

Next: **[7. Troubleshooting and uninstall](07-troubleshooting-and-uninstall.md)**.
