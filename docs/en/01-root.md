# 1. Rooting the TV

[Español](../01-rootear.md)

This project doesn't root the TV by itself: it uses the **faultmanager** exploit from
[throwaway96/faultmanager-autoroot](https://github.com/throwaway96/faultmanager-autoroot), which installs
[Homebrew Channel](https://github.com/webosbrew/webos-homebrew-channel). Here is a summary of how it was done
on the test TV. **The official source is always the faultmanager-autoroot README and
[webosbrew.org](https://www.webosbrew.org).**

## Before you start

1. Check that your firmware is vulnerable on **[CanI.RootMy.TV](https://cani.rootmy.tv)**. On the TV:
   *Settings → General → About this TV*.
2. **Don't update the firmware** in the meantime. LG has already patched almost all of webOS 5 and later, and an
   update can close the door.
3. You need a computer on the same Wi-Fi network as the TV.

## Steps

1. **LG Developer Mode:** install the *Developer Mode* app from the LG store, sign in with an
   [LG Developer](https://webostv.developer.lge.com) account (free), and turn on **Dev Mode Status** and **Key Server**.
2. **Developer Mode SSH** (port 9922): download the key from `http://<ip-tv>:9991/webos_rsa` and
   connect with the passphrase shown in the app. The *crashd* guide linked from the
   faultmanager-autoroot README and [Dev Manager](https://github.com/webosbrew/dev-manager-desktop) help with this.
3. **Run the exploit** inside that SSH session:

   ```bash
   curl -L -o /tmp/autoroot.sh -- 'https://raw.githubusercontent.com/throwaway96/faultmanager-autoroot/refs/heads/main/autoroot.sh'
   sh /tmp/autoroot.sh
   ```

   Wait for the *Payload complete* message. The script installs Homebrew Channel.
4. **Before rebooting, uninstall LG's Developer Mode app.** The exploit's README says it clearly:
   *don't have the Developer Mode app installed while the TV is rooted*. If for some reason you reinstall it
   (it happened to us while trying to fix a problem), **follow [guide 2](02-developer-mode-trap.md) before rebooting**.
5. Reboot the TV and open **Homebrew Channel**. Its settings should say *Root status: ok*.

## What ends up installed

- `/media/developer/apps/usr/palm/applications/org.webosbrew.hbchannel`: the Homebrew Channel app.
- `/var/lib/webosbrew/startup.sh`: the root's startup script. Homebrew Channel triggers it ~40 s
  after the TV turns on, through the `previewMetadata.targetEndpoint` in its `appinfo.json`.
- `/var/lib/webosbrew/init.d/`: your own scripts go here, like the ones in this project. They run with
  busybox's `run-parts`, which **ignores files with a dot in the name** (`something.sh` doesn't run;
  `10-something` does).

Next: **[2. The Developer Mode trap](02-developer-mode-trap.md)**.
