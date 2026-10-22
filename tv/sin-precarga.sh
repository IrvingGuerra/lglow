#!/bin/sh
# sin-precarga: evita que LG precargue apps al encender (ahorra RAM).
# Se ejecuta desde /var/lib/webosbrew/init.d/60-sinprecarga, después del home
# (10-homecustom). Todo va en segundo plano para no retrasar a nadie: con la TV recién
# encendida, cada luna-send tarda varios segundos. Se conservan las precargas del
# fullhome, HDMI y TV en vivo para que la tecla Home y las entradas sigan rápidas.
# Para desactivarlo: borrar el enlace en init.d y reiniciar.

APPS="netflix youtube.leanback.v4 amazon com.webos.app.browser com.webos.app.tips pooq com.webos.app.home"

(
    for app in $APPS; do
        luna-send -n 1 luna://com.webos.service.preloadmanager/setPreloadPolicy \
            "{\"application\":{\"id\":\"$app\",\"isEnabled\":false}}" >/dev/null 2>&1
    done

    # Red de seguridad: durante los primeros minutos, si Netflix aparece corriendo en
    # segundo plano (precargado, no abierto por el usuario), se cierra.
    i=0
    while [ $i -lt 18 ]; do
        sleep 10
        i=$((i + 1))
        pid=$(pidof netflix.bin)
        [ -z "$pid" ] && continue
        fg=$(luna-send -n 1 luna://com.webos.applicationManager/getForegroundAppInfo '{}' 2>/dev/null)
        case "$fg" in
            *'"appId":"netflix"'*) exit 0 ;;   # el usuario lo abrió: no tocar
        esac
        luna-send -n 1 luna://com.webos.applicationManager/closeByAppId '{"id":"netflix"}' >/dev/null 2>&1
        sleep 3
        pid=$(pidof netflix.bin)
        [ -n "$pid" ] && kill $pid
    done
) </dev/null >/dev/null 2>&1 &

exit 0
