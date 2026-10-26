#!/bin/sh
# Quita el home renovado y deja el de LG tal como venía. Se ejecuta EN LA TV, como root:
#   sh uninstall.sh            → quita todo
#   sh uninstall.sh --conservar → quita los montajes y scripts, pero conserva tu
#                                 config.json, apps-ocultas.txt, fondos y tiles
# Al terminar, reinicia la TV para que todo vuelva a cargarse limpio.

BASE=/var/lib/webosbrew
FULL=$BASE/fullhomecustom
BAR=$BASE/homecustom

[ "$(id -u)" = 0 ] || { echo "ERROR: hay que correrlo como root." >&2; exit 1; }

echo "==> quitando scripts de arranque"
rm -f "$BASE/init.d/10-homecustom" "$BASE/init.d/20-compositor" "$BASE/init.d/60-sinprecarga"

echo "==> quitando montajes"
for app in com.webos.app.fullhome com.webos.app.home; do
    umount "/usr/palm/applications/$app/qml" 2>/dev/null
    umount "/tmp/checkpoint/$app" 2>/dev/null
    umount "/mnt/lg/cmn_data/checkpoint/$app" 2>/dev/null
done
for f in /usr/lib/qt5/qml/SystemUIAssets/images/*/default_app_splash.png \
         /usr/lib/qt5/qml/YSM/images/default_app_splash.png \
         /usr/lib/qt5/qml/QuickSettings/QuickSettings.qml \
         /usr/lib/qt5/qml/KeyFilters/appLaunch.js; do
    umount "$f" 2>/dev/null
done
# Pantallas de carga de las apps (montadas por versiones viejas de splash-apps.sh)
mount | grep " /media/cryptofs/apps/" | grep -i splash | awk '{print $3}' | while read f; do
    umount "$f" 2>/dev/null
done
# Las copiadas por splash-apps.sh: regresar el original guardado
for o in "$FULL"/splash/orig/*.png; do
    [ -f "$o" ] || continue
    id=$(basename "$o" .png)
    info=/media/cryptofs/apps/usr/palm/applications/$id/appinfo.json
    rel=$(sed -n 's/.*"splashBackground" *: *"\([^"]*\)".*/\1/p' "$info" 2>/dev/null | head -1)
    f=${info%/appinfo.json}/$rel
    # Solo si sigue la de LGlow (si la app se actualizó, ya trae la suya)
    [ -n "$rel" ] && [ "$(md5sum "$f" 2>/dev/null | cut -d' ' -f1)" = "$(cat "${o%.png}.md5")" ] && cp "$o" "$f"
done

echo "==> reactivando las precargas de LG"
for app in netflix youtube.leanback.v4 amazon com.webos.app.browser com.webos.app.tips pooq com.webos.app.home; do
    luna-send -n 1 luna://com.webos.service.preloadmanager/setPreloadPolicy \
        "{\"application\":{\"id\":\"$app\",\"isEnabled\":true}}" >/dev/null 2>&1
done

echo "==> borrando archivos instalados"
rm -rf "$FULL/qml" "$BAR/qml" "$BAR/apply.sh" "$BAR/splash"
rm -f "$BASE/tools/sin-precarga.sh" "$BASE/tools/compositor.sh" "$BASE/tools/splash-apps.sh"
if [ "$1" != "--conservar" ]; then
    rm -rf "$FULL" "$BAR"
fi

for app in com.webos.app.fullhome com.webos.app.home; do
    pid=$(pidof $app)
    [ -n "$pid" ] && kill -9 $pid
done

echo "==> listo. Reinicia la TV (reboot) para volver al home original de LG."
