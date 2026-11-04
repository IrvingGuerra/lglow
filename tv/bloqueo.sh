#!/bin/sh
# bloqueo: anuncios y telemetría de LG fuera, por /etc/hosts.
# Cada dominio de tv/bloqueo-dominios.txt apunta a 127.0.0.1 y ::1, igual que hace Homebrew
# Channel con los servidores de actualización. La TV resuelve nombres leyendo /etc/hosts
# antes que el DNS, así que la conexión falla al instante y sin esperar.
#
# /etc/hosts es de solo lectura; Homebrew lo tapa al arrancar con una copia en /tmp
# (mount --bind), y aquí se escribe en esa copia. Las apps que corren en "jaula"
# (Netflix, Prime…) tienen su propia copia en /var/palm/jail/<app>/etc/hosts, que se
# hace al crear la jaula: también se actualiza. Nada se escribe en la partición de LG y
# todo se pierde al reiniciar (por eso corre en cada encendido desde init.d/15-bloqueo).
#
#   sh bloqueo.sh           → aplica la lista (quita primero lo que había puesto antes)
#   sh bloqueo.sh --quitar  → quita las líneas de LGlow de /etc/hosts y de las jaulas
#
# Para apagarlo sin desinstalar: "bloqueoAnuncios": false en fullhomecustom/config.json.
BASE=/var/lib/webosbrew
LISTA=$BASE/tools/bloqueo-dominios.txt
CFG=$BASE/fullhomecustom/config.json
JAILS=/var/palm/jail
INI="# lglow-bloqueo: inicio"
FIN="# lglow-bloqueo: fin"
NUEVO=/tmp/lglow-bloqueo.hosts
TMP=/tmp/lglow-bloqueo.tmp

quitar_de() {
    [ -f "$1" ] && grep -q "^$INI" "$1" || return 0
    # Sin sed -i: /etc/hosts es un montaje sobre una carpeta de solo lectura y sed -i
    # necesita crear un archivo temporal al lado. Se reescribe el archivo en su lugar.
    sed "/^$INI\$/,/^$FIN\$/d" "$1" > $TMP && cat $TMP > "$1"
}

quitar_todo() {
    quitar_de /etc/hosts
    for f in "$JAILS"/*/etc/hosts; do quitar_de "$f"; done
}

# Asegurar que /etc/hosts sea la copia escribible de Homebrew (startup.sh ya lo hace;
# esto es por si bloqueo.sh corre a mano antes que él)
escribible() {
    if ! touch /etc/hosts 2>/dev/null; then
        cp /etc/hosts /tmp/hosts && mount --bind /tmp/hosts /etc/hosts || return 1
    fi
}

if [ "$1" = "--quitar" ]; then
    quitar_todo
    echo "bloqueo: líneas de LGlow quitadas"
    exit 0
fi

[ -f "$LISTA" ] || { echo "bloqueo: no existe $LISTA" >&2; exit 1; }

# Apagado desde config.json
if [ -f "$CFG" ] && grep -q '"bloqueoAnuncios" *: *false' "$CFG"; then
    quitar_todo
    echo "bloqueo: apagado en config.json"
    exit 0
fi

# País de la TV (dos letras, minúsculas); si no se encuentra, "us"
PAIS=$(grep -ohE '"smartServiceCountryCode2":"[A-Za-z]{2}"' /var/luna/preferences/option 2>/dev/null \
       | head -1 | sed 's/.*:"//; s/"//' | tr 'A-Z' 'a-z')
[ -n "$PAIS" ] || PAIS=us

# Expandir la lista a líneas de hosts
{
    echo "$INI"
    grep -v '^[[:space:]]*#' "$LISTA" | grep -v '^[[:space:]]*$' | sed 's/^[[:space:]]*//; s/[[:space:]]*$//' \
    | while read -r dom; do
        case "$dom" in
            *'{region}'*) for r in aic eic kic; do echo "$dom" | sed "s/{region}/$r/g; s/{pais}/$PAIS/g"; done ;;
            *) echo "$dom" | sed "s/{pais}/$PAIS/g" ;;
        esac
    done | sort -u | while read -r h; do
        echo "127.0.0.1 $h"
        echo "::1 $h"
    done
    echo "$FIN"
} > $NUEVO

escribible || { echo "bloqueo: /etc/hosts no es escribible" >&2; exit 1; }
quitar_de /etc/hosts
cat $NUEVO >> /etc/hosts
for f in "$JAILS"/*/etc/hosts; do
    [ -f "$f" ] || continue
    quitar_de "$f"
    cat $NUEVO >> "$f"
done
echo "bloqueo: $(grep -c '^127.0.0.1' $NUEVO) dominios bloqueados (país $PAIS)"
