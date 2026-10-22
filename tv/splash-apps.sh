#!/bin/sh
# splash-apps: pantallas de carga de LGlow para las apps que traen la gris genérica de LG.
# Netflix, Prime Video y YouTube vienen con la imagen gris de cubos (o gris lisa) como su propia
# pantalla de carga. Si existe /var/lib/webosbrew/fullhomecustom/splash/<appId>.png (lo genera
# tools/make-splash.py), se monta encima del original, pero solo si el original es uno de esos
# genéricos (por md5): si la app se actualiza y trae su propia pantalla con su marca, se respeta.
# No escribe en las apps: son montajes que se pierden al reiniciar.
#
# Lo llama apply.sh al encender (antes de que 20-compositor reinicie el compositor, que es
# cuando lee las imágenes) y tools/make-splash.py al generar nuevas.
SPLASH=/var/lib/webosbrew/fullhomecustom/splash
APPS=/media/cryptofs/apps/usr/palm/applications
# Netflix (cubos), Prime Video (cubos) y YouTube (gris liso), firmware 05.40.97
GENERICOS="f29e4726373c5b4c0569024120948baa 7d4ccc5583b13e6066e060b36d9a1bf1 78edfd48e7d7673778cb20dd5b812330"

[ -d "$SPLASH" ] || exit 0

for info in $APPS/*/appinfo.json; do
    dir=${info%/appinfo.json}
    id=${dir##*/}
    [ -f "$SPLASH/$id.png" ] || continue
    rel=$(sed -n 's/.*"splashBackground" *: *"\([^"]*\)".*/\1/p' "$info" | head -1)
    [ -n "$rel" ] || continue
    orig="$dir/$rel"
    [ -f "$orig" ] || continue
    umount "$orig" 2>/dev/null
    sum=$(md5sum "$orig" | cut -d' ' -f1)
    case " $GENERICOS " in
        *" $sum "*) mount --bind "$SPLASH/$id.png" "$orig" && echo "splash: $id" ;;
    esac
done
exit 0
