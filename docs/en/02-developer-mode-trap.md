# 2. The Developer Mode trap (what wipes the root)

[Español](../02-trampa-developer-mode.md)

**If your rooted TV still has LG's Developer Mode app installed, read this before rebooting it.**

It happened to us several times: after a reboot, SSH on port 9922 gave *Connection refused*, and Homebrew Channel
and all the homebrew apps had **disappeared**. At first we blamed a change to `/etc/hosts`, but that wasn't
it. This is the real cause.

## What happens on every boot

1. `/etc/init/devmode.conf` (LG's, read-only) runs at boot. If
   `/var/luna/preferences/devmode_enabled` exists and the Developer Mode app's `start-devmode.sh` script has a
   valid signature, it runs it.
2. `start-devmode.sh` reads the session token from `devmode_enabled` and validates it online:

   ```text
   https://developer.lge.com/secure/CheckDevModeSession.dev?sessionToken=<token>
   ```

3. If LG responds `"result":"fail"`, the script **deletes** `devmode_enabled`.
4. At the end of `devmode.conf`, since `devmode_enabled` no longer exists, LG runs:

   ```sh
   rm -rf /media/developer
   ```

   That's where Homebrew Channel and all the homebrew apps live. **The root is lost.**

On a TV rooted with faultmanager, `devmode_enabled` usually ends up as an **empty folder**. The token is read
as empty and LG responds `{"result":"fail","errorCode":"ERR_006","errorMsg":"Check sessionToken"}`. So **the
wipe is guaranteed on the next reboot** if the Developer Mode app is installed.

## The fix

Uninstall LG's Developer Mode app, or, if you'd rather not delete anything, **rename its `start-devmode.sh`**
so `devmode.conf` doesn't run it. This is the same thing `autoroot.sh` does. That way `devmode_enabled` stays and
`/media/developer` is left alone.

This repo includes a script that does the latter, after showing you what LG responds with your current token:

```bash
scp tv/extras/desactivar-trampa-devmode.sh root@<ip-tv>:/tmp/
ssh root@<ip-tv> sh /tmp/desactivar-trampa-devmode.sh
```

> Do it from **Homebrew Channel**'s SSH (port 22 or telnet 23, see
> [step 3](03-access-and-updates.md)), not from Developer Mode's: that one stops existing after
> this, on purpose.

After this:

- **Don't open or update the Developer Mode app.** The refreshed home hides it by default.
- Access is through Homebrew Channel's SSH/telnet, which doesn't expire.
- You no longer need to "extend" the Developer Mode session (it lasts ~40 days).

## How to check it

```bash
ls /media/cryptofs/apps/usr/palm/services/com.palmdts.devmode.service/ | grep start-devmode
# start-devmode.sh.DESACTIVADO
# start-devmode.sig.DESACTIVADO
```

Reboot the TV and check that Homebrew Channel is still there. The test TV was rebooted more than 10 times after
the change without losing root.

Next: **[3. Access and blocking updates](03-access-and-updates.md)**.
