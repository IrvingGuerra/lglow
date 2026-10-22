# 1. Rootear la TV

Este proyecto no rootea la TV por sí mismo: usa el exploit **faultmanager** de
[throwaway96/faultmanager-autoroot](https://github.com/throwaway96/faultmanager-autoroot), que instala
[Homebrew Channel](https://github.com/webosbrew/webos-homebrew-channel). Aquí va el resumen de cómo se hizo
en la TV de prueba. **La fuente oficial es siempre el README de faultmanager-autoroot y
[webosbrew.org](https://www.webosbrew.org).**

## Antes de empezar

1. Revisa que tu firmware sea vulnerable en **[CanI.RootMy.TV](https://cani.rootmy.tv)**. En la TV:
   *Configuración → General → Acerca de esta TV*.
2. **No actualices el firmware** mientras tanto. LG ya parchó casi todo webOS 5 en adelante, y una
   actualización puede cerrar la puerta.
3. Necesitas una computadora en la misma red Wi-Fi que la TV.

## Pasos

1. **Developer Mode de LG:** instala la app *Developer Mode* desde la tienda de LG, entra con una cuenta de
   [LG Developer](https://webostv.developer.lge.com) (gratis), activa **Dev Mode Status** y **Key Server**.
2. **SSH de Developer Mode** (puerto 9922): baja la llave desde `http://<ip-tv>:9991/webos_rsa` y
   conéctate con la passphrase que muestra la app. La guía de *crashd* que enlaza el README de
   faultmanager-autoroot y [Dev Manager](https://github.com/webosbrew/dev-manager-desktop) ayudan con esto.
3. **Correr el exploit** dentro de esa sesión SSH:

   ```bash
   curl -L -o /tmp/autoroot.sh -- 'https://raw.githubusercontent.com/throwaway96/faultmanager-autoroot/refs/heads/main/autoroot.sh'
   sh /tmp/autoroot.sh
   ```

   Espera el mensaje *Payload complete*. El script instala Homebrew Channel.
4. **Antes de reiniciar, desinstala la app Developer Mode de LG.** El README del exploit lo dice claro:
   *no tengas la app Developer Mode instalada mientras la TV está rooteada*. Si por algo la reinstalas
   (a nosotros nos pasó al intentar reparar un problema), **sigue el paso 2 de esta guía antes de reiniciar**.
5. Reinicia la TV y abre **Homebrew Channel**. En su ajustes debe decir *Root status: ok*.

## Qué queda instalado

- `/media/developer/apps/usr/palm/applications/org.webosbrew.hbchannel`: la app Homebrew Channel.
- `/var/lib/webosbrew/startup.sh`: el script de arranque del root. Lo dispara Homebrew Channel ~40 s
  después de encender la TV, mediante el `previewMetadata.targetEndpoint` de su `appinfo.json`.
- `/var/lib/webosbrew/init.d/`: aquí van los scripts propios, como los de este proyecto. Se ejecutan con
  `run-parts` de busybox, que **ignora los archivos con punto en el nombre** (`algo.sh` no corre;
  `10-algo` sí).

Siguiente: **[2. La trampa de Developer Mode](02-trampa-developer-mode.md)**.
