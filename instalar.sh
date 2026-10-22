#!/bin/sh
# Copia la carpeta tv/ a la TV y corre el instalador allá.
# Uso (desde tu computadora, en la carpeta del repo):
#   ./instalar.sh 192.168.1.50          → instala
#   ./instalar.sh 192.168.1.50 --quitar → desinstala
# Requiere SSH root a la TV (Homebrew Channel → Settings → SSH Server, o tv/extras/ssh-con-llave.sh).
set -e
HOST=$1
[ -n "$HOST" ] || { echo "Uso: ./instalar.sh <ip-de-la-tv> [--quitar]"; exit 1; }
case "$HOST" in *@*) ;; *) HOST="root@$HOST" ;; esac
cd "$(dirname "$0")"

echo "==> copiando archivos a la TV"
ssh "$HOST" 'rm -rf /tmp/lglow && mkdir -p /tmp/lglow'
COPYFILE_DISABLE=1 tar cf - -C tv . | ssh "$HOST" 'tar xf - -C /tmp/lglow 2>/dev/null'

if [ "$2" = "--quitar" ]; then
    ssh "$HOST" 'sh /tmp/lglow/uninstall.sh'
else
    ssh "$HOST" 'sh /tmp/lglow/install.sh'
fi
