#!/bin/sh
# home-custom: monta QML modificado encima de los homes de LG.
#   - com.webos.app.fullhome (el home que sale con la tecla Home)
#   - com.webos.app.home (la barra vieja; se deja apagada para ahorrar RAM)
# y cambia la pantalla de carga genérica de las apps.
# No toca la partición de solo lectura ni borra nada: todo son montajes que se
# pierden al reiniciar. Para desactivarlo: touch /var/lib/webosbrew/homecustom/DESACTIVADO
# y reiniciar la TV.
#
# Corre desde /var/lib/webosbrew/init.d/10-homecustom, PRIMERO que los demás scripts:
# el root arranca ~45 s después de encender y todo lo que se abra antes de que esto
# termine sale con el diseño original de LG.
BASE=/var/lib/webosbrew
EMPTY=/tmp/homecustom-empty
LOG=/tmp/homecustom.log

[ -e $BASE/homecustom/DESACTIVADO ] && exit 0
echo "inicio: $(cut -d' ' -f1 /proc/uptime) s" > $LOG
mkdir -p "$EMPTY"

# 1) Pantalla de carga genérica del compositor (gris con cubos) → la del diseño nuevo.
#    La usan las apps sin splash propio. Va primero porque el compositor guarda la
#    imagen en caché la primera vez que la usa: si una app se abre antes de este
#    montaje, la vieja se queda hasta el siguiente reinicio.
NEW_SPLASH=$BASE/homecustom/splash/default_app_splash.png
if [ -f $NEW_SPLASH ]; then
    for f in /usr/lib/qt5/qml/SystemUIAssets/images/*/default_app_splash.png \
             /usr/lib/qt5/qml/YSM/images/default_app_splash.png; do
        [ -f "$f" ] || continue
        umount "$f" 2>/dev/null
        mount --bind $NEW_SPLASH "$f"
    done
fi
# Y las apps que traen como propia la gris de LG (Netflix, Prime, YouTube)
[ -f $BASE/tools/splash-apps.sh ] && sh $BASE/tools/splash-apps.sh >> $LOG 2>&1

# ¿El home está en pantalla ahora? (el compositor lo anota en el log del sistema)
home_visible() {
    grep -h "NL_VSC" /var/log/messages 2>/dev/null | grep "\"app_id\":\"$1\"" | tail -1 | grep -q '"visible":true'
}

# custom <appId> <carpeta con qml/>
custom() {
    app=$1; mod=$2/qml; orig=/usr/palm/applications/$app/qml
    [ -f "$mod/main.qml" ] || return 0
    umount "$orig" 2>/dev/null
    mount --bind "$mod" "$orig" || return 1

    # La app se restaura con CRIU desde una imagen de fábrica que ya trae el QML
    # original en memoria. Tapamos esas imágenes con una carpeta vacía para que
    # SAM la lance en limpio y lea el QML montado.
    for d in /tmp/checkpoint/$app /mnt/lg/cmn_data/checkpoint/$app; do
        [ -d "$d" ] || continue
        umount "$d" 2>/dev/null
        mount --bind "$EMPTY" "$d"
    done

    pid=$(pidof $app)
    [ -z "$pid" ] && return 0
    visible=0
    home_visible $app && visible=1
    kill -9 $pid
    # Si estaba en pantalla, se vuelve a abrir ya con el diseño nuevo (en vez de desaparecer)
    if [ $visible = 1 ]; then
        sleep 1
        luna-send -n 1 luna://com.webos.applicationManager/launch "{\"id\":\"$app\"}" >/dev/null 2>&1
    fi
    return 0
}

custom com.webos.app.fullhome $BASE/fullhomecustom
custom com.webos.app.home $BASE/homecustom

echo "fin: $(cut -d' ' -f1 /proc/uptime) s" >> $LOG
exit 0
