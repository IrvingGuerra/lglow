# 3. Acceso por SSH y bloqueo de actualizaciones

## Acceso root

Homebrew Channel abre dos accesos root en cada arranque (desde su `startup.sh`):

| Acceso | Cómo | Notas |
| --- | --- | --- |
| **Telnet**, puerto 23 | `telnet <ip-tv>` | Sin contraseña, root directo. Viene encendido por defecto. Cualquiera en tu red puede entrar: apágalo en Homebrew Channel → Settings si te importa. |
| **SSH**, puerto 22 | `ssh root@<ip-tv>` | Se enciende en Homebrew Channel → Settings → *SSH Server*. Sin llave, la contraseña es `alpine`. |

Para usar tu llave en vez de la contraseña (recomendado; los scripts de este repo usan `ssh`/`scp`):

```bash
scp tv/extras/ssh-con-llave.sh root@<ip-tv>:/tmp/
ssh root@<ip-tv> sh /tmp/ssh-con-llave.sh "\"$(cat ~/.ssh/id_ed25519.pub)\""
```

Tip: un alias en `~/.ssh/config` ahorra escribir la IP:

```text
Host tv
  HostName 192.168.1.50
  User root
```

> **`luna-send` por SSH solo imprime si hay terminal.** Sin TTY no muestra nada y parece que falló. Usa
> `ssh -tt tv "luna-send …"` (y quita los `\r` de la salida) o telnet.

## Bloquear las actualizaciones de firmware

Una actualización de LG puede cerrar el exploit y **quitar el root**. Homebrew Channel tiene la opción
*Block system updates*: crea `/var/luna/preferences/webosbrew_block_updates` y, en cada arranque, su
`startup.sh` monta un `/etc/hosts` en `/tmp` que manda los servidores de actualización de LG a `127.0.0.1`:

```text
127.0.0.1 snu.lge.com su-dev.lge.com su.lge.com su-ssl.lge.com
```

Actívalo desde la app Homebrew Channel o con:

```bash
scp tv/extras/bloquear-actualizaciones.sh root@<ip-tv>:/tmp/
ssh root@<ip-tv> sh /tmp/bloquear-actualizaciones.sh
```

Después del siguiente reinicio, `tail -3 /etc/hosts` en la TV debe mostrar esas líneas.

> Este cambio a `/etc/hosts` es seguro: solo bloquea esos cuatro dominios. Si quieres bloquear anuncios con
> listas grandes, mejor hazlo por DNS en tu router (Pi-hole, AdGuard Home, NextDNS) y no en la TV.

Desde la tienda de LG, las apps también pueden actualizarse solas. En la TV de prueba ya estaban en manual.
Para revisarlo:

```bash
ssh -tt tv "luna-send -n 1 luna://com.webos.settingsservice/getSystemSettings '{\"category\":\"option\",\"keys\":[\"appUpdateMode\"]}'"
```

Siguiente: **[4. Instalar el home renovado](04-instalar-home.md)**.
