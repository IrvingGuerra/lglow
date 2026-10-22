# 4. Instalar el home renovado

Requisitos: TV rooteada (pasos 1 a 3), SSH root a la TV y, en tu computadora, `git`, `ssh` y Python 3 con
Pillow (`pip install pillow`, solo para generar los tiles).

## Instalar

```bash
git clone https://github.com/IrvingGuerra/lglow && cd lglow
./instalar.sh 192.168.1.50        # la IP de tu TV (o un alias de ~/.ssh/config)
```

`instalar.sh` copia la carpeta `tv/` a la TV y corre allá `install.sh`, que:

1. **Revisa la versión** de cada archivo del home que se va a parchar (md5 en `tv/patches/*/originales.md5`).
   Si tu firmware es distinto, se detiene sin tocar nada.
2. Copia el QML original del home a `/var/lib/webosbrew/fullhomecustom/qml` (y el de la barra vieja a
   `/var/lib/webosbrew/homecustom/qml`), le aplica los parches y le agrega los componentes nuevos.
3. Instala los scripts de arranque en `/var/lib/webosbrew/init.d/`: `10-homecustom` (monta el home) y
   `60-sinprecarga` (apaga precargas de apps).
4. Lo aplica de inmediato. Presiona Home y listo.

Salida esperada:

```text
==> com.webos.app.fullhome: revisando versión de los archivos originales
==> com.webos.app.fullhome: copiando el QML original y aplicando parches
==> com.webos.app.home: revisando versión de los archivos originales
==> com.webos.app.home: copiando el QML original y aplicando parches
==> copiando configuración, fondos y pantalla de carga
==> creado /var/lib/webosbrew/fullhomecustom/config.json: edítalo con tu ciudad y tu llave de TMDB
==> instalando scripts de arranque
==> aplicando ahora
==> listo. La pantalla de carga nueva se ve después del próximo reinicio.
```

## Configurar "Para ti" y el clima

Edita en la TV `/var/lib/webosbrew/fullhomecustom/config.json`:

```json
{
    "tmdbKey": "tu llave de TMDB (API Key v3)",
    "region": "MX",
    "language": "es-MX",
    "latitude": 19.4326,
    "longitude": -99.1332,
    "city": "Ciudad de México"
}
```

- **tmdbKey:** gratis en [themoviedb.org/settings/api](https://www.themoviedb.org/settings/api). Sin llave, el
  home funciona igual, pero solo muestra fecha, hora y clima.
- **region:** tu país en dos letras. Decide en qué apps está cada título.
- **latitude / longitude / city:** para el clima. Busca tus coordenadas en cualquier mapa.

Para que tome los cambios, presiona Home dos veces o reinicia la TV.

### Otros países

Los proveedores de TMDB cambian según el país. Los que vienen en el código son los de México. Si estás en otro
país, agrega `"providers"` a `config.json` con los ids de tu región y el id de la app en tu TV:

```json
"providers": {
    "8":   ["Netflix", "netflix"],
    "337": ["Disney+", "com.disney.disneyplus-prod"],
    "119": ["Prime Video", "amazon"]
}
```

- Ids de proveedores: `https://api.themoviedb.org/3/watch/providers/tv?watch_region=XX&api_key=TU_LLAVE`.
- Ids de apps en tu TV: `ssh -tt tv "luna-send -n 1 luna://com.webos.applicationManager/listLaunchPoints '{}'"`.

## Tiles rectangulares de tus apps

Los tiles grandes con el color de cada marca se generan desde los íconos que ya tiene tu TV:

```bash
python3 tools/make-tiles.py 192.168.1.50
```

El script baja el ícono de cada app, detecta su color de fondo, compone un PNG de 300×180 con esquinas
redondeadas y lo sube a `/var/lib/webosbrew/fullhomecustom/tiles/`. **Vuelve a correrlo cuando instales una
app nueva.** Sin tile, la app se ve con su ícono sobre su color.

## Apps ocultas

En la TV, `/var/lib/webosbrew/fullhomecustom/apps-ocultas.txt` tiene una app por línea. Por defecto oculta el
navegador, LG Content Store, Foto y Video, Música, Panel del hogar y Developer Mode. **No se desinstalan**:
solo no aparecen en el home. Después de editarlo, vuelve a correr `./instalar.sh <ip-tv>`.

> Si ocultas LG Content Store y quieres instalar una app, quítala de la lista un momento o ábrela con
> `ssh -tt tv "luna-send -n 1 luna://com.webos.applicationManager/launch '{\"id\":\"com.webos.app.discovery\"}'"`.

## Fijar apps y reordenarlas

El home muestra las **5 primeras apps** según el orden de LG. Para cambiarlas: ↓ (o el tile **Apps**) →
lápiz **✎** al final → se abre el modo edición de LG: selecciona una app con OK, muévela y confirma con OK.

## Fondo

Vienen dos fondos: `fondo-perla.jpg` (claro, el de las capturas) y `fondo-aurora.jpg` (oscuro). El home usa
`fondo.jpg`. Para cambiarlo:

```bash
ssh tv "cp /var/lib/webosbrew/fullhomecustom/fondo-aurora.jpg /var/lib/webosbrew/fullhomecustom/fondo.jpg"
```

Puedes poner cualquier JPG de 1920×1080. Ten en cuenta que los textos y los íconos de arriba son oscuros,
pensados para un fondo claro.

## Actualizar o desinstalar

- **Actualizar:** `git pull && ./instalar.sh <ip-tv>`. Conserva tu `config.json`, tus apps ocultas, el fondo y
  los tiles.
- **Desactivar sin borrar:** `ssh tv touch /var/lib/webosbrew/homecustom/DESACTIVADO` y reinicia.
- **Desinstalar:** `./instalar.sh <ip-tv> --quitar` y reinicia. Así vuelve el home original de LG.

Siguiente: **[5. Cómo funciona](05-como-funciona.md)** o **[6. Limpieza y memoria](06-limpieza-y-memoria.md)**.
