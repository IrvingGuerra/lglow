#!/bin/sh
# Instala el home renovado en una TV LG con webOS 4.x rooteada (Homebrew Channel).
# Se ejecuta EN LA TV, como root:   sh install.sh
#
# Qué hace (nada se escribe en las particiones de solo lectura de LG):
#   1. Revisa que los archivos originales del home sean los esperados (misma versión
#      de firmware con la que se probó). Si no coinciden, se detiene sin tocar nada.
#   2. Copia el QML original del home a /var/lib/webosbrew, le aplica los parches de
#      tv/patches y le agrega los componentes nuevos de tv/qml.
#   3. Instala apply.sh como script de arranque (init.d/10-homecustom), que monta la
#      copia modificada encima del original en cada encendido.
#   4. Lo aplica de inmediato.
set -e

HERE=$(cd "$(dirname "$0")" && pwd)
BASE=/var/lib/webosbrew
FULL=$BASE/fullhomecustom
BAR=$BASE/homecustom
MAIN=UserInterfaceLayer/Containers/Main

say() { echo "==> $*"; }
die() { echo "ERROR: $*" >&2; exit 1; }

[ "$(id -u)" = 0 ] || die "hay que correrlo como root (por SSH/telnet de Homebrew Channel)."
[ -d $BASE ] || die "no existe $BASE: ¿la TV está rooteada con Homebrew Channel?"
command -v patch >/dev/null || die "falta el comando 'patch' en la TV."

# La lista de apps ocultas: la del usuario si ya existía, si no la de ejemplo
HIDDEN_FILE=$FULL/apps-ocultas.txt
[ -f $HIDDEN_FILE ] || HIDDEN_FILE=$HERE/apps-ocultas.txt
HIDDEN=$(grep -v '^[[:space:]]*#' "$HIDDEN_FILE" | grep -v '^[[:space:]]*$' \
         | sed 's/^[[:space:]]*//; s/[[:space:]]*$//; s/.*/"&"/' | tr '\n' ',' | sed 's/,$//; s/,/, /g')

# prepare <appId> <destino> <carpeta de parches>
prepare() {
    app=$1; dest=$2; patches=$3
    orig=/usr/palm/applications/$app/qml

    # Si ya estaba instalado, quitar el montaje para leer el QML original de LG
    umount "$orig" 2>/dev/null || true

    say "$app: revisando versión de los archivos originales"
    if ! (cd /usr/palm/applications/$app && md5sum -c "$patches/originales.md5" >/dev/null 2>&1); then
        (cd /usr/palm/applications/$app && md5sum -c "$patches/originales.md5" 2>&1 | grep -v ': OK$') || true
        die "$app no coincide con el firmware probado (webOS 4.10.2, firmware 05.40.97). No se tocó nada."
    fi

    say "$app: copiando el QML original y aplicando parches"
    rm -rf "$dest/staging"
    mkdir -p "$dest/staging"
    cp -a "$orig" "$dest/staging/qml"
    for p in "$patches"/*.patch; do
        # patch de busybox: sin -d ni -s
        (cd "$dest/staging" && patch -p1 -i "$p" >/dev/null) || die "no se pudo aplicar $(basename "$p")"
    done
}

# --- Home principal (com.webos.app.fullhome) ---
prepare com.webos.app.fullhome $FULL "$HERE/patches/fullhome"
cp "$HERE"/qml/fullhome/*.qml "$FULL/staging/qml/$MAIN/"
sed -i "s|^var HIDDEN_IDS = .*|var HIDDEN_IDS = [$HIDDEN];|" \
    "$FULL/staging/qml/Configurations/SystemServiceResponseProcessors.js"
rm -rf "$FULL/qml"
mv "$FULL/staging/qml" "$FULL/qml"
rm -rf "$FULL/staging"

# --- Barra vieja (com.webos.app.home): mismas apps ocultas, sin previews ---
prepare com.webos.app.home $BAR "$HERE/patches/home"
sed -i "s|^    property var hiddenAppIds: .*|    property var hiddenAppIds: [$HIDDEN]|" \
    "$BAR/staging/qml/AppInitializer/SystemProperties.qml"
rm -rf "$BAR/qml"
mv "$BAR/staging/qml" "$BAR/qml"
rm -rf "$BAR/staging"

say "copiando configuración, fondos y pantalla de carga"
mkdir -p "$FULL/tiles" "$BAR/splash" "$BASE/tools" "$BASE/init.d"
[ -f "$FULL/apps-ocultas.txt" ] || cp "$HERE/apps-ocultas.txt" "$FULL/apps-ocultas.txt"
if [ ! -f "$FULL/config.json" ]; then
    cp "$HERE/config.example.json" "$FULL/config.json"
    say "creado $FULL/config.json: edítalo con tu ciudad y tu llave de TMDB"
fi
chmod 600 "$FULL/config.json"
[ -f "$FULL/fondo.jpg" ] || cp "$HERE/fondos/perla.jpg" "$FULL/fondo.jpg"
cp "$HERE/fondos/perla.jpg" "$FULL/fondo-perla.jpg"
cp "$HERE/fondos/aurora.jpg" "$FULL/fondo-aurora.jpg"
cp "$HERE/splash/default_app_splash.png" "$BAR/splash/default_app_splash.png"
mkdir -p "$FULL/quicksettings"
cp "$HERE/quicksettings/QuickSettings.qml" "$FULL/quicksettings/QuickSettings.qml"

# Teclas del compositor: el botón Movies puede abrir una app ("botonMovies" en config.json). Solo con
# el appLaunch.js del firmware probado; con otro, el botón se queda como lo dejó LG
KF=/usr/lib/qt5/qml/KeyFilters
umount "$KF/appLaunch.js" 2>/dev/null || true
mkdir -p "$FULL/keyfilters"
if (cd $KF && md5sum -c "$HERE/patches/keyfilters/originales.md5" >/dev/null 2>&1); then
    cp "$KF/appLaunch.js" "$FULL/keyfilters/appLaunch.js"
    (cd "$FULL/keyfilters" && patch -p1 -i "$HERE/patches/keyfilters/appLaunch.patch" >/dev/null) \
        || die "no se pudo aplicar appLaunch.patch"
    # El id de la app va escrito en el archivo (el compositor no puede leer config.json); solo letras,
    # números, punto, guion y guion bajo
    MOVIES=$(sed -n 's/.*"botonMovies" *: *"\([A-Za-z0-9._-]*\)".*/\1/p' "$FULL/config.json" | head -1)
    sed -i "s|^var lglowBotonMovies = \"\";|var lglowBotonMovies = \"$MOVIES\";|" "$FULL/keyfilters/appLaunch.js"
    [ -n "$MOVIES" ] && say "botón Movies → $MOVIES"
else
    say "las teclas del compositor son de otro firmware: el botón Movies se queda como lo dejó LG"
    rm -f "$FULL/keyfilters/appLaunch.js"
fi

say "instalando scripts de arranque"
cp "$HERE/apply.sh" "$BAR/apply.sh"
cp "$HERE/sin-precarga.sh" "$BASE/tools/sin-precarga.sh"
cp "$HERE/key.js" "$BASE/tools/key.js"
cp "$HERE/compositor.sh" "$BASE/tools/compositor.sh"
cp "$HERE/splash-apps.sh" "$BASE/tools/splash-apps.sh"
chmod +x "$BAR/apply.sh" "$BASE/tools/sin-precarga.sh" "$BASE/tools/compositor.sh"
rm -f "$BAR/DESACTIVADO"
# Sin punto en el nombre: busybox run-parts ignora los archivos con "."
ln -sf "$BAR/apply.sh" "$BASE/init.d/10-homecustom"
ln -sf "$BASE/tools/compositor.sh" "$BASE/init.d/20-compositor"
ln -sf "$BASE/tools/sin-precarga.sh" "$BASE/init.d/60-sinprecarga"
chown -R 0:0 "$FULL" "$BAR" "$BASE/tools"

say "aplicando ahora"
sh "$BAR/apply.sh"
# Si el home no estaba en pantalla, se abre en limpio la próxima vez que se presione Home

# El panel rápido y la pantalla de carga nuevos necesitan reiniciar el compositor: la pantalla
# parpadea un par de segundos (si existe homecustom/SIN_COMPOSITOR, no se hace)
say "reiniciando el compositor para el panel rápido y la pantalla de carga (parpadea un momento)"
sh "$BASE/tools/compositor.sh" --ahora

say "listo."
