# 2. La trampa de Developer Mode (lo que borra el root)

[English](en/02-developer-mode-trap.md)

**Si tu TV rooteada todavía tiene la app Developer Mode de LG instalada, lee esto antes de reiniciarla.**

Nos pasó varias veces: tras un reinicio, el SSH del puerto 9922 daba *Connection refused*, y Homebrew Channel
y todas las apps homebrew habían **desaparecido**. Primero culpamos a un cambio en `/etc/hosts`, pero no era
eso. Esta es la causa real.

## Qué pasa en cada encendido

1. `/etc/init/devmode.conf` (de LG, solo lectura) corre al arrancar. Si existe
   `/var/luna/preferences/devmode_enabled` y el script `start-devmode.sh` de la app Developer Mode tiene firma
   válida, lo ejecuta.
2. `start-devmode.sh` lee el token de sesión de `devmode_enabled` y lo valida en internet:

   ```text
   https://developer.lge.com/secure/CheckDevModeSession.dev?sessionToken=<token>
   ```

3. Si LG responde `"result":"fail"`, el script **borra** `devmode_enabled`.
4. Al final de `devmode.conf`, como ya no existe `devmode_enabled`, LG ejecuta:

   ```sh
   rm -rf /media/developer
   ```

   Ahí viven Homebrew Channel y todas las apps homebrew. **El root se pierde.**

En una TV rooteada con faultmanager, `devmode_enabled` suele quedar como **carpeta vacía**. El token se lee
vacío y LG responde `{"result":"fail","errorCode":"ERR_006","errorMsg":"Check sessionToken"}`. Así que **el
borrado está garantizado en el siguiente reinicio** si la app Developer Mode está instalada.

## La solución

Desinstalar la app Developer Mode de LG, o, si prefieres no borrar nada, **renombrar su `start-devmode.sh`**
para que `devmode.conf` no lo ejecute. Es lo mismo que hace `autoroot.sh`. Así `devmode_enabled` se queda y
`/media/developer` no se toca.

Este repo trae un script que hace lo segundo, después de mostrarte qué responde LG con tu token actual:

```bash
scp tv/extras/desactivar-trampa-devmode.sh root@<ip-tv>:/tmp/
ssh root@<ip-tv> sh /tmp/desactivar-trampa-devmode.sh
```

> Hazlo desde el SSH de **Homebrew Channel** (puerto 22 o telnet 23, ver el
> [paso 3](03-acceso-y-actualizaciones.md)), no desde el de Developer Mode: ese deja de existir después de
> esto, a propósito.

Después de esto:

- **No abras ni actualices la app Developer Mode.** El home renovado la oculta por defecto.
- El acceso queda por el SSH/telnet de Homebrew Channel, que no caduca.
- Ya no hace falta "extender" la sesión de Developer Mode (dura ~40 días).

## Cómo comprobarlo

```bash
ls /media/cryptofs/apps/usr/palm/services/com.palmdts.devmode.service/ | grep start-devmode
# start-devmode.sh.DESACTIVADO
# start-devmode.sig.DESACTIVADO
```

Reinicia la TV y revisa que Homebrew Channel siga ahí. En la TV de prueba se reinició más de 10 veces después
del cambio sin perder el root.

Siguiente: **[3. Acceso y bloqueo de actualizaciones](03-acceso-y-actualizaciones.md)**.
