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

## La pantalla de carga o el panel del engranaje siguen siendo los de LG

El compositor de webOS (`surface-manager`) guarda en memoria, desde que enciende la TV, la imagen de carga y el
panel de ajustes rápidos de LG. `init.d/20-compositor` monta los de LGlow y lo reinicia una vez, en cuanto en
pantalla está el home, una entrada HDMI o la TV en vivo. Revisa `/tmp/lglow-compositor.log`:

- `panel montado` y `compositor reiniciado`: todo bien.
- `sin buen momento en 30 min`: estuviste en una app todo ese tiempo; se aplica en el siguiente encendido, o al
  momento con `sh /var/lib/webosbrew/tools/compositor.sh --ahora`.
- Si no quieres el reinicio (es un parpadeo de un par de segundos): `touch /var/lib/webosbrew/homecustom/SIN_COMPOSITOR`.

Si alguna vez la pantalla se queda en negro después del reinicio del compositor, reinicia la TV: los montajes
viven en memoria y todo vuelve a cargarse. Netflix, Prime Video y YouTube traen la gris de LG como pantalla de carga propia: corre `python3 tools/make-splash.py <ip-tv>`
para que muestren la de LGlow (`tv/splash-apps.sh` la monta solo si el original es el genérico de LG).

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
