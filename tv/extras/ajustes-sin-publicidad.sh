#!/bin/sh
# Apaga publicidad, recolección de datos y efectos que gastan recursos, usando los
# mismos ajustes del sistema que el menú de LG (todo reversible).
# Para deshacer: correr de nuevo con "on" en lugar de "off" (ver valores originales abajo).
[ "$(id -u)" = 0 ] || { echo "ERROR: hay que correrlo como root." >&2; exit 1; }
# Valores de fábrica: todos "on"
luna-send -n 1 luna://com.webos.settingsservice/setSystemSettings \
    '{"category":"general","settings":{"screenSaverAd":"off","adCookie":"off"}}'; echo
luna-send -n 1 luna://com.webos.settingsservice/setSystemSettings \
    '{"category":"option","settings":{"watchedListCollection":"off","webOSPromotionVideo":"off","animationGuide":"off","helpOnSettings":"off","menuTransparency":"off","channelplus":"off","smartSoundDemo":"off"}}'; echo
echo "Listo."
