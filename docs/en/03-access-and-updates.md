# 3. SSH access and blocking updates

[Español](../03-acceso-y-actualizaciones.md)

## Root access

Homebrew Channel opens two root access points on every boot (from its `startup.sh`):

| Access | How | Notes |
| --- | --- | --- |
| **Telnet**, port 23 | `telnet <ip-tv>` | No password, straight to root. On by default. Anyone on your network can get in: turn it off in Homebrew Channel → Settings if that matters to you. |
| **SSH**, port 22 | `ssh root@<ip-tv>` | Turned on in Homebrew Channel → Settings → *SSH Server*. Without a key, the password is `alpine`. |

To use your key instead of the password (recommended; this repo's scripts use `ssh`/`scp`):

```bash
scp tv/extras/ssh-con-llave.sh root@<ip-tv>:/tmp/
ssh root@<ip-tv> sh /tmp/ssh-con-llave.sh "\"$(cat ~/.ssh/id_ed25519.pub)\""
```

Tip: an alias in `~/.ssh/config` saves you from typing the IP:

```text
Host tv
  HostName 192.168.1.50
  User root
```

> **`luna-send` over SSH only prints if there's a terminal.** Without a TTY it shows nothing and looks like it failed. Use
> `ssh -tt tv "luna-send …"` (and strip the `\r` from the output) or telnet.

## Blocking firmware updates

An LG update can close the exploit and **remove the root**. Homebrew Channel has a
*Block system updates* option: it creates `/var/luna/preferences/webosbrew_block_updates` and, on every boot, its
`startup.sh` mounts an `/etc/hosts` in `/tmp` that sends LG's update servers to `127.0.0.1`:

```text
127.0.0.1 snu.lge.com su-dev.lge.com su.lge.com su-ssl.lge.com
```

Turn it on from the Homebrew Channel app or with:

```bash
scp tv/extras/bloquear-actualizaciones.sh root@<ip-tv>:/tmp/
ssh root@<ip-tv> sh /tmp/bloquear-actualizaciones.sh
```

After the next reboot, `tail -3 /etc/hosts` on the TV should show those lines.

> This change to `/etc/hosts` is safe: it only blocks those four domains. If you want to block ads with
> large lists, do it via DNS on your router (Pi-hole, AdGuard Home, NextDNS) rather than on the TV.

Apps from the LG store can also update themselves. On the test TV they were already set to manual.
To check:

```bash
ssh -tt tv "luna-send -n 1 luna://com.webos.settingsservice/getSystemSettings '{\"category\":\"option\",\"keys\":[\"appUpdateMode\"]}'"
```

Next: **[4. Installing the refreshed home](04-install-home.md)**.
