#!/bin/sh
# compositor: el panel rápido de LGlow en el botón de engranaje del control, y la pantalla de
# carga nueva desde el primer momento.
# El compositor de webOS (surface-manager) guarda en memoria, desde que enciende la TV, el panel
# de ajustes rápidos de LG y la pantalla de carga genérica de las apps. Montar los nuestros
# encima no basta: hay que reiniciar el compositor una vez para que los vuelva a leer. Esto se
# ve como un parpadeo de un par de segundos, así que solo se hace cuando en pantalla está el
# home, una entrada HDMI o la TV en vivo (nunca a media película en una app). Si en media hora
# no hay buen momento, no se reinicia y se queda lo de LG hasta el siguiente encendido.
#
# Corre desde /var/lib/webosbrew/init.d/20-compositor, después de 10-homecustom (que monta la
# pantalla de carga), todo en segundo plano. Con --ahora reinicia sin esperar (lo usa el
# instalador). Para desactivarlo: touch /var/lib/webosbrew/homecustom/SIN_COMPOSITOR
BASE=/var/lib/webosbrew
QS_NUEVO=$BASE/fullhomecustom/quicksettings/QuickSettings.qml
QS=/usr/lib/qt5/qml/QuickSettings/QuickSettings.qml
LOG=/tmp/lglow-compositor.log

[ -e $BASE/homecustom/DESACTIVADO ] && exit 0
[ -e $BASE/homecustom/SIN_COMPOSITOR ] && exit 0

AHORA=0
[ "$1" = "--ahora" ] && AHORA=1

# ¿Se puede reiniciar sin interrumpir? Sí con el home, una entrada o la TV en vivo en pantalla
buen_momento() {
    fg=$(luna-send -n 1 luna://com.webos.applicationManager/getForegroundAppInfo '{}' 2>/dev/null)
    case "$fg" in
        *'"appId":"com.webos.app.fullhome"'*|*'"appId":"com.webos.app.hdmi'*|*'"appId":"com.webos.app.livetv"'*|*'"appId":""'*)
            return 0 ;;
    esac
    return 1
}

(
    echo "inicio: $(cut -d' ' -f1 /proc/uptime) s" > $LOG

    if [ -f "$QS_NUEVO" ] && [ -f "$QS" ]; then
        umount "$QS" 2>/dev/null
        mount --bind "$QS_NUEVO" "$QS" && echo "panel montado" >> $LOG
    fi

    i=0
    while [ $AHORA = 0 ] && ! buen_momento; do
        i=$((i + 1))
        if [ $i -gt 120 ]; then
            echo "sin buen momento en 30 min: no se reinicia" >> $LOG
            exit 0
        fi
        sleep 15
    done

    initctl restart surface-manager >/dev/null 2>&1
    echo "compositor reiniciado: $(cut -d' ' -f1 /proc/uptime) s" >> $LOG
) </dev/null >/dev/null 2>&1 &

exit 0
