#!/bin/sh
# Activa el SSH root de Homebrew Channel (dropbear, puerto 22) con tu llave pública.
# Uso, en la TV:  sh ssh-con-llave.sh "ssh-ed25519 AAAA... tu@pc"
# Con una llave en /home/root/.ssh/authorized_keys, Homebrew deja de usar la contraseña
# genérica "alpine" (después del siguiente reinicio).
[ "$(id -u)" = 0 ] || { echo "ERROR: hay que correrlo como root." >&2; exit 1; }
[ -n "$1" ] || { echo "Uso: sh ssh-con-llave.sh \"<tu llave pública>\"" >&2; exit 1; }
mkdir -p /home/root/.ssh && chmod 700 /home/root/.ssh
grep -qxF "$1" /home/root/.ssh/authorized_keys 2>/dev/null || echo "$1" >> /home/root/.ssh/authorized_keys
chmod 600 /home/root/.ssh/authorized_keys
touch /var/luna/preferences/webosbrew_sshd_enabled
mkdir -p /var/lib/webosbrew/sshd
pidof dropbear >/dev/null || /media/developer/apps/usr/palm/services/org.webosbrew.hbchannel.service/bin/dropbear -R
echo "Listo: ssh root@<ip-de-la-tv>"
