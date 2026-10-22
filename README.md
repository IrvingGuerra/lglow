<div align="center">

# LGlow

**Tu vieja LG, como nueva.** Un home limpio, rápido y sin publicidad para TVs LG de 2019 con webOS 4.x,
hecho sobre el home original.

Tendencias de tus propias apps, el clima, tiles grandes y nada de banners de LG.
Sin tocar las particiones del sistema: todo se monta encima y se quita con un comando.

[Antes y después](#antes-y-después) · [vs Free My TV](#y-free-my-tv) · [Compatibilidad](#compatibilidad) · [Guía paso a paso](#guía-paso-a-paso) · [Cómo funciona](docs/05-como-funciona.md) · [Problemas](docs/07-problemas-y-desinstalar.md) · [English](README.en.md)

</div>

> [!WARNING]
> Esto requiere **rootear la TV**. Hazlo bajo tu propio riesgo. Todo lo de este repo es reversible y
> **nunca escribe en las particiones de solo lectura de LG**, pero un error en otros pasos del root (no
> en este proyecto) puede dejar la TV inservible. Lee la guía completa antes de empezar.

## Antes y después

| Antes (home de LG) | Después |
| --- | --- |
| ![Home original de LG con banner y recomendaciones patrocinadas](docs/img/antes-home.jpg) | ![Home renovado: Para ti, clima y una fila de apps](docs/img/despues-home.jpg) |
| Banner de LG, "Ir a Apps", fila de contenido promocionado, íconos chicos y todas las apps de sistema. | "Para ti" con lo que está en tendencia **en tus apps**, fecha, hora y clima, y tus 5 apps fijadas. |

| Películas / Series | Todas las apps |
| --- | --- |
| ![Pestaña Películas con un título seleccionado](docs/img/despues-titulo.jpg) | ![Pantalla Apps con todas las apps](docs/img/despues-apps.jpg) |
| Pestañas **Explorar · Películas · Series**. OK en un título abre la app donde está. | El tile **Apps** (o ↓) abre una segunda pantalla con todas tus apps. Atrás regresa. |

<details>
<summary>Más capturas: la barra vieja, los tiles y la pantalla de carga</summary>

| La barra vieja de webOS 4.5 (también se limpia) | Tiles generados desde los íconos de tu TV |
| --- | --- |
| ![Barra de apps original](docs/img/antes-barra.jpg) | ![Tiles rectangulares por app](docs/img/tiles.jpg) |

| Pantalla de carga genérica de LG | La nueva |
| --- | --- |
| ![Pantalla de carga gris con cubos](docs/img/antes-carga.jpg) | ![Pantalla de carga clara con tres puntos](docs/img/despues-carga.jpg) |

</details>

## Qué obtienes

- **Sin publicidad de LG en el home:** fuera el banner, la fila de recomendaciones patrocinadas, los anuncios
  del protector de pantalla y la cookie publicitaria.
- **"Para ti":** cada hora, tres títulos en tendencia de esta semana, **solo de las apps que tienes** (datos de
  [TMDB](https://www.themoviedb.org)). Pestañas de Explorar, Películas y Series. OK en uno abre su app.
- **Clima, fecha y hora** de tu ciudad ([Open-Meteo](https://open-meteo.com), sin llave).
- **Apps grandes y rectangulares** con el color de cada marca, en **una sola fila** con tus 5 favoritas. El
  resto, en una segunda pantalla.
- **Oculta las apps que no usas** (navegador, tienda, música…) sin desinstalarlas.
- **Más memoria libre:** la barra vieja deja de ocupar RAM y LG ya no precarga Netflix, YouTube ni Prime en
  segundo plano. En la TV de prueba, la RAM disponible en reposo pasó de **~106 MB a ~160–250 MB** y el swap
  en uso, de **~265 MB a ~30 MB**.
- **Root blindado:** se desactiva una trampa de la app Developer Mode que **borra el root** (y Homebrew
  Channel) en un reinicio. [Ver por qué](docs/02-trampa-developer-mode.md).

## ¿Y Free My TV?

[Free My TV](https://github.com/simbasjungles/free-my-tv) inspiró el diseño de LGlow, y en LG es una gran opción
**si no quieres rootear**. Pero funciona distinto:

| | Free My TV en LG | LGlow |
| --- | --- | --- |
| Qué es | **Una app más** (launcher) que se instala con Developer Mode | **Cambia el home del propio sistema**: el que abre el botón Home |
| El home de LG | Se queda igual, con su publicidad. Free My TV se abre con una tecla numérica | **Desaparece**: el botón Home abre directamente el nuevo |
| Root | No hace falta | Sí (faultmanager + Homebrew Channel) |
| Developer Mode | Hay que renovarlo cada ~40 días, o la app se borra | No se usa. Además desactiva la trampa que borra el root |
| Más allá del home | — | Oculta apps de sistema, apaga precargas y publicidad, libera RAM y bloquea las actualizaciones que quitan el root |
| TVs | webOS 3 o más nuevo, Google TV, Samsung | LG webOS 4.x (probado en un modelo de 2019) |

En corto: **Free My TV es una app que abres encima de la TV; LGlow cambia la TV desde la raíz.** Si tu TV ya está
rooteada (o estás dispuesto a rootearla), LGlow te quita el home de LG de verdad.

## Compatibilidad

| | |
| --- | --- |
| **Probado en** | LG **43LM5770PUA** (2019), webOS **4.10.2** (Rockhopper `4.10.2-29`), firmware **05.40.97** |
| **Debería funcionar en** | Otros LG 2019 con webOS 4.5 y el home nuevo de 2025 (`com.webos.app.fullhome`). El instalador **revisa la versión de cada archivo** y no toca nada si no coincide. |
| **Requiere** | Root con [faultmanager-autoroot](https://github.com/throwaway96/faultmanager-autoroot) + [Homebrew Channel](https://github.com/webosbrew/webos-homebrew-channel), y una computadora con `ssh` en la misma red. Para "Para ti": una llave gratis de [TMDB](https://www.themoviedb.org/settings/api). |
| **No sirve para** | webOS 5 o más nuevos (el home es distinto). Para webOS 10, ve [mareklarek/webos10-homescreen-customization](https://github.com/mareklarek/webos10-homescreen-customization). |

¿Tu modelo es otro con webOS 4.x? Si el instalador dice que los archivos no coinciden, abre un issue con la
salida de `md5sum` y tu versión de firmware. Los parches se pueden regenerar
(ver [docs/05-como-funciona.md](docs/05-como-funciona.md#regenerar-los-parches-para-otro-firmware)).

## Guía paso a paso

1. **[Rootear la TV](docs/01-rootear.md):** faultmanager-autoroot + Homebrew Channel.
2. **[Desactivar la trampa de Developer Mode](docs/02-trampa-developer-mode.md):** obligatorio si la app
   Developer Mode de LG sigue instalada. Sin esto, un reinicio puede borrar el root.
3. **[Acceso por SSH y bloqueo de actualizaciones](docs/03-acceso-y-actualizaciones.md):** para que LG no
   quite el root con una actualización.
4. **[Instalar el home renovado](docs/04-instalar-home.md):** un comando desde tu computadora.
5. **[Limpieza y memoria](docs/06-limpieza-y-memoria.md):** opcional. Apaga publicidad y precargas.

Resumen para quien ya tiene root y SSH:

```bash
git clone https://github.com/IrvingGuerra/lglow && cd lglow
./instalar.sh 192.168.1.50                 # la IP de tu TV
ssh root@192.168.1.50 vi /var/lib/webosbrew/fullhomecustom/config.json   # llave TMDB y ciudad
python3 tools/make-tiles.py 192.168.1.50   # tiles rectangulares de tus apps
```

Para quitarlo todo: `./instalar.sh 192.168.1.50 --quitar` y reiniciar la TV.

## Uso

| En el home | |
| --- | --- |
| **← →** | Moverse entre apps, títulos o pestañas |
| **↑ ↓** | Íconos de arriba ↔ pestañas ↔ títulos ↔ apps. **↓ desde las apps** abre la pantalla Apps |
| **OK** | Abrir la app o el título (abre la app donde está) |
| **Atrás** | En la pantalla Apps, regresa al home |
| **Lápiz (✎)** en la pantalla Apps | Modo edición de LG: las **5 primeras** son las fijadas del home |

## Limitaciones conocidas

- **Los primeros ~45 s después de prender la TV** se ve el diseño de LG. En webOS 4 no hay forma de correr
  código antes de que arranque el root. Si presionas Home en ese lapso, el home cambia solo al nuevo en cuanto
  el script corre. Con **Quick Start+** encendido la TV se suspende en vez de apagarse, y el diseño se conserva
  entre encendidos.
- **La pantalla de carga genérica** a veces sigue siendo la de LG. El compositor de webOS vuelve desde un
  snapshot de fábrica en cada arranque, con esa imagen ya en caché. Cambiarla de verdad requeriría modificar el
  compositor, y no vale el riesgo. Las apps con splash propio (Netflix, Disney+, Max…) muestran el suyo.
- **La velocidad al abrir o cambiar de app** mejora poco: la TV tiene 674 MB de RAM y las apps de streaming
  son web apps pesadas. Ver [mediciones](docs/06-limpieza-y-memoria.md#qué-tanto-mejora-la-velocidad).
- Textos en español. Los ids de proveedores de "Para ti" vienen para México; para otro país,
  [cámbialos en config.json](docs/04-instalar-home.md#otros-países).

## Créditos

- [faultmanager-autoroot](https://github.com/throwaway96/faultmanager-autoroot) (throwaway96, buglloc) y
  [Homebrew Channel](https://github.com/webosbrew/webos-homebrew-channel) / [webosbrew.org](https://www.webosbrew.org):
  el root y el arranque de scripts.
- [mareklarek/webos10-homescreen-customization](https://github.com/mareklarek/webos10-homescreen-customization):
  la idea de montar una copia modificada del home encima del original.
- [Free My TV](https://github.com/simbasjungles/free-my-tv): el diseño de la pantalla de inicio.
- Datos: [TMDB](https://www.themoviedb.org) (este producto usa la API de TMDB, pero TMDB no lo respalda ni
  certifica) y [Open-Meteo](https://open-meteo.com).

## Licencia

El código de este repo (scripts, parches, componentes QML nuevos y herramientas) está bajo [MIT](LICENSE).
**El código del home de LG no está incluido:** el instalador lo copia de tu propia TV y le aplica los parches.
LG, webOS y los nombres y logos de las apps son marcas de sus dueños. Este proyecto no está afiliado con LG.
