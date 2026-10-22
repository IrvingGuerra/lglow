# 7. Problemas comunes y cómo desinstalar

[English](en/07-troubleshooting-and-uninstall.md)

## Desinstalar o desactivar

| Quiero… | Cómo |
| --- | --- |
| Quitar todo y volver al home de LG | `./instalar.sh <ip-tv> --quitar` y reiniciar la TV |
| Quitarlo pero conservar mi config, fondos y tiles | En la TV: `sh /tmp/lglow/uninstall.sh --conservar` (después de un `./instalar.sh`) |
| Desactivarlo sin borrar nada | `ssh tv touch /var/lib/webosbrew/homecustom/DESACTIVADO` y reiniciar. Para reactivar, borra ese archivo. |

Como todo son montajes en memoria, **un reinicio siempre deja el home de LG intacto** si el script de arranque
no corre.

## "Los archivos no coinciden con el firmware probado"

Tu TV tiene otra versión del home. El instalador no tocó nada. Ve
[cómo regenerar los parches](05-como-funciona.md#regenerar-los-parches-para-otro-firmware) o abre un issue con:

```bash
ssh -tt tv "cat /etc/starfish-release; luna-send -n 1 luna://com.webos.service.tv.systemproperty/getSystemInfo '{\"keys\":[\"modelName\",\"firmwareVersion\",\"sdkVersion\"]}'"
```

## Veo el home de LG al prender la TV

Normal durante los primeros ~45 s (ver [cómo funciona el arranque](05-como-funciona.md#el-orden-y-el-momento-del-arranque)).
Si después de un minuto sigue el de LG:

```bash
ssh tv "cat /tmp/homecustom.log; ls /var/lib/webosbrew/init.d/; mount | grep -c fullhome"
```

- `/tmp/homecustom.log` debe tener `inicio:` y `fin:`. Si no existe, el `startup.sh` de Homebrew no corrió:
  abre la app Homebrew Channel una vez y revisa *Root status*.
- `init.d` debe tener `10-homecustom` **sin punto ni extensión**.

## La pantalla de carga sigue siendo la gris de LG

El compositor de webOS regresa en cada arranque desde un snapshot de fábrica que ya trae en caché la imagen
de carga original. El repo reemplaza el archivo (`default_app_splash.png`), pero en varios casos se sigue
viendo la imagen de la caché. Es una limitación conocida. Las apps con pantalla de carga propia muestran la
suya.

## Una app nueva sale con ícono chico o cuadrado

Corre `python3 tools/make-tiles.py <ip-tv>` para generar su tile.

## Se perdió el foco / no responde el control en el home

Presiona Home dos veces. Si se repite, abre un issue describiendo qué hiciste antes (abrir una app, el modo
edición, todas las apps…) y adjunta `ssh tv tail -50 /var/log/fullhome`.

## Perdí el root después de reiniciar

Casi seguro fue [la trampa de Developer Mode](02-trampa-developer-mode.md). Hay que volver a rootear
([paso 1](01-rootear.md)) y desactivar la trampa **antes** del siguiente reinicio.

## Modo a prueba de fallos de Homebrew Channel

Si la TV se reinicia durante el arranque del root, el siguiente arranque entra en *failsafe*: solo abre telnet,
no corre `init.d` y muestra un aviso. Corrige la causa por telnet y reinicia. Homebrew Channel lo explica en
su aviso.
