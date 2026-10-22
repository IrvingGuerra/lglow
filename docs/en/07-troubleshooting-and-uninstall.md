# 7. Common problems and how to uninstall

[Español](../07-problemas-y-desinstalar.md)

## Uninstall or disable

| I want to… | How |
| --- | --- |
| Remove everything and go back to LG's home | `./instalar.sh <ip-tv> --quitar` and restart the TV |
| Remove it but keep my config, backgrounds and tiles | On the TV: `sh /tmp/lglow/uninstall.sh --conservar` (after running `./instalar.sh`) |
| Disable it without deleting anything | `ssh tv touch /var/lib/webosbrew/homecustom/DESACTIVADO` and restart. To re-enable it, delete that file. |

Since everything is an in-memory mount, **a restart always leaves LG's home intact** if the boot script
doesn't run.

## "Los archivos no coinciden con el firmware probado" (The files don't match the tested firmware)

Your TV has a different version of the home. The installer didn't touch anything. See
[how to regenerate the patches](05-how-it-works.md#regenerating-the-patches-for-another-firmware) or open an issue with:

```bash
ssh -tt tv "cat /etc/starfish-release; luna-send -n 1 luna://com.webos.service.tv.systemproperty/getSystemInfo '{\"keys\":[\"modelName\",\"firmwareVersion\",\"sdkVersion\"]}'"
```

## I see LG's home when I turn on the TV

This is normal for the first ~45 s (see [how boot works](05-how-it-works.md#boot-order-and-timing)).
If LG's home is still there after a minute:

```bash
ssh tv "cat /tmp/homecustom.log; ls /var/lib/webosbrew/init.d/; mount | grep -c fullhome"
```

- `/tmp/homecustom.log` should contain `inicio:` and `fin:`. If it doesn't exist, Homebrew's `startup.sh` didn't run:
  open the Homebrew Channel app once and check *Root status*.
- `init.d` should contain `10-homecustom` **with no dot or extension**.

## The loading screen is still LG's gray one

The webOS compositor comes back on every boot from a factory snapshot that already has the original loading
image cached. The repo replaces the file (`default_app_splash.png`), but in several cases the cached image is
still shown. This is a known limitation. Apps with their own loading screen show theirs.

## A new app shows up with a small or square icon

Run `python3 tools/make-tiles.py <ip-tv>` to generate its tile.

## Focus is lost / the remote doesn't respond on the home

Press Home twice. If it happens again, open an issue describing what you did before (opening an app, edit
mode, all apps…) and attach `ssh tv tail -50 /var/log/fullhome`.

## I lost root after restarting

It was almost certainly [the Developer Mode trap](02-developer-mode-trap.md). You need to root again
([step 1](01-root.md)) and disable the trap **before** the next restart.

## Homebrew Channel failsafe mode

If the TV restarts while root is booting, the next boot enters *failsafe*: it only opens telnet,
doesn't run `init.d` and shows a notice. Fix the cause over telnet and restart. Homebrew Channel explains this in
its notice.
