#!/bin/sh
# Bloquea las actualizaciones de firmware de LG (que podrían quitar el root) con el
# mecanismo oficial de Homebrew Channel: en cada arranque, su startup.sh agrega
# snu/su/su-ssl/su-dev.lge.com → 127.0.0.1 a un /etc/hosts montado en /tmp.
# Es lo mismo que el interruptor "Block system updates" de la app Homebrew Channel.
# Para deshacerlo: rm /var/luna/preferences/webosbrew_block_updates y reiniciar.
[ "$(id -u)" = 0 ] || { echo "ERROR: hay que correrlo como root." >&2; exit 1; }
touch /var/luna/preferences/webosbrew_block_updates
echo "Listo. Se aplica en el próximo reinicio. Para comprobar: tail -3 /etc/hosts"
