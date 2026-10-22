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
IMAGES=/media/cryptofs/apps/usr/palm/data/images
# Netflix (cubos), Prime Video (cubos) y YouTube (gris liso), firmware 05.40.97
GENERICOS="f29e4726373c5b4c0569024120948baa 7d4ccc5583b13e6066e060b36d9a1bf1 78edfd48e7d7673778cb20dd5b812330"

# Netflix, Prime Video y YouTube son apps "squashfs": su código vive en una imagen que SAM monta
# como overlay sobre su carpeta la primera vez que se abren después de encender, y ese overlay
# tapa la pantalla de carga montada antes (salía la gris en la primera apertura). Se monta aquí
# igual que SAM; al abrir la app, SAM lo ve en /proc/mounts y no lo repite.
montar_squashfs() {
    id=$1
    dir=$2
    img=$IMAGES/$id/data.img
    sq=/media/squashfs/apps/$id
    [ -f "$img" ] || return 0
    grep -q " $dir overlay " /proc/mounts && return 0
    mkdir -p "$sq" "/media/squashfs/work/$id"
    nuevo=0
    if ! grep -q " $sq squashfs " /proc/mounts; then
        mount -t squashfs -o ro "$img" "$sq" || return 1
        nuevo=1
    fi
    if ! mount -t overlay overlay -o "lowerdir=$sq/usr/palm/applications/$id,upperdir=$dir,workdir=/media/squashfs/work/$id" "$dir"; then
        # Que SAM lo intente como siempre al abrir la app
        [ $nuevo = 1 ] && umount "$sq"
        return 1
    fi
}

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
        *" $sum "*)
            montar_squashfs "$id" "$dir" || echo "splash: $id sin overlay (puede salir la gris la primera vez)"
            mount --bind "$SPLASH/$id.png" "$orig" && echo "splash: $id" ;;
    esac
done
exit 0
