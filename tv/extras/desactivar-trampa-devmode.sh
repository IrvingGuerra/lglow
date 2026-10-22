#!/bin/sh
# IMPORTANTE para TVs rooteadas con faultmanager-autoroot que tienen instalada la app
# "Developer Mode" de LG (por ejemplo, porque se reinstaló después de rootear).
#
# En cada encendido, /etc/init/devmode.conf ejecuta el start-devmode.sh de esa app. Ese
# script valida un token contra developer.lge.com y, si la respuesta es "fail", borra
# /var/luna/preferences/devmode_enabled. Entonces devmode.conf hace rm -rf /media/developer,
# y con eso se pierden Homebrew Channel, todas las apps homebrew y el root.
#
# Este script NO borra nada: renombra start-devmode.sh (y su firma) para que no se ejecute.
# Es lo mismo que hace autoroot.sh. El acceso queda por el SSH/telnet de Homebrew Channel
# (el SSH de Developer Mode en el puerto 9922 deja de existir).
# Para deshacerlo: renombrar los archivos .DESACTIVADO a su nombre original y reiniciar.
D=/media/cryptofs/apps/usr/palm/services/com.palmdts.devmode.service

[ "$(id -u)" = 0 ] || { echo "ERROR: hay que correrlo como root." >&2; exit 1; }

if [ ! -f $D/start-devmode.sh ]; then
    echo "No hay start-devmode.sh activo: nada que hacer."
    exit 0
fi

t=$(cat /var/luna/preferences/devmode_enabled 2>/dev/null)
echo "Respuesta de LG al validar la sesión actual:"
curl --max-time 8 -s "https://developer.lge.com/secure/CheckDevModeSession.dev?sessionToken=$t"; echo

mv $D/start-devmode.sh $D/start-devmode.sh.DESACTIVADO
[ -f $D/start-devmode.sig ] && mv $D/start-devmode.sig $D/start-devmode.sig.DESACTIVADO
echo "Listo: start-devmode.sh renombrado. Ya no se validará el token al encender."
echo "No abras la app Developer Mode de LG ni la actualices."
