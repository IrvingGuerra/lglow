# 6. Limpieza y memoria

[English](en/06-cleanup-and-memory.md)

La TV de prueba tiene **674 MB de RAM**, y el sistema solo ya usa ~490 MB en reposo. Cada megabyte cuenta.

## Lo que hace el home renovado por sí solo

| Qué | Ahorro |
| --- | --- |
| La barra vieja (`com.webos.app.home`) deja de correr | ~47 MB |
| Sin filas de contenido ni banners descargados en el home | menos imágenes en memoria y menos red |
| `60-sinprecarga`: LG ya no precarga Netflix, YouTube, Prime, Navegador ni Tips | Netflix solo ocupaba ~99 MB (RAM + swap) |

El precargador de LG (`com.webos.service.preloadmanager`) lanzaba Netflix ~65 s después de encender, aunque
`getPreloadPolicy` lo marcaba como deshabilitado. `sin-precarga.sh` deshabilita la política de cada app
(`setPreloadPolicy '{"application":{"id":"…","isEnabled":false}}'`: objeto singular, con un arreglo falla) y,
como red de seguridad, durante 3 minutos cierra Netflix si aparece corriendo sin que tú lo hayas abierto. Se
conservan las precargas del home, HDMI y TV en vivo, para que la tecla Home y las entradas sigan rápidas.

El costo: la primera vez que abres Netflix después de prender la TV tarda unos segundos más.

## Apagar publicidad y extras (opcional)

```bash
scp tv/extras/ajustes-sin-publicidad.sh root@<ip-tv>:/tmp/
ssh root@<ip-tv> sh /tmp/ajustes-sin-publicidad.sh
```

| Ajuste | Qué es | De fábrica |
| --- | --- | --- |
| `general.screenSaverAd` | Anuncios en el protector de pantalla | on |
| `general.adCookie` | Cookie publicitaria | on |
| `option.watchedListCollection` | Recolección de lo que ves | on |
| `option.webOSPromotionVideo` | Video promocional de webOS | on |
| `option.animationGuide` | Animaciones de guía | on |
| `option.helpOnSettings` | Ayuda en ajustes | on |
| `option.menuTransparency` | Transparencia de menús (menos trabajo para la GPU) | on |
| `option.channelplus` | LG Channels | on |
| `option.smartSoundDemo` | Demo de sonido | on |

Para revertir un ajuste, vuelve a ponerlo en `"on"` con `setSystemSettings`.

## Anuncios y telemetría de LG fuera (/etc/hosts)

LGlow instala `tools/bloqueo.sh`, que corre en cada encendido desde `init.d/15-bloqueo`. Agrega a `/etc/hosts`
la lista de `tools/bloqueo-dominios.txt` apuntando a `127.0.0.1` y `::1`, igual que hace Homebrew Channel con los
servidores de actualización ([guía 3](03-acceso-y-actualizaciones.md)). La TV lee `/etc/hosts` antes que el DNS,
así que esas conexiones fallan al instante, sin esperas.

- Escribe en la copia de `/etc/hosts` que Homebrew monta en `/tmp` y en las copias de las apps que corren en
  "jaula" (`/var/palm/jail/<app>/etc/hosts`, como Netflix y Prime Video). Nada se escribe en la partición de LG.
- Las líneas van entre `# lglow-bloqueo: inicio` y `# lglow-bloqueo: fin`, para poder quitarlas sin tocar las
  de Homebrew.
- En la lista, `{pais}` es el código de país de la TV (por ejemplo `mx`) y `{region}` se expande a `aic`, `eic` y
  `kic` (los centros de datos de LG). En la TV de prueba quedan 26 dominios.

### Qué bloquea

| Dominios | Para qué sirven |
| --- | --- |
| `lgsmartad.com`, `<pais>.ad.lgsmartad.com`, `<pais>.info.lgsmartad.com` | LG Smart Ad: anuncios del home y del protector de pantalla |
| `ad.lgappstv.com`, `<pais>.ibs.lgappstv.com`, `<pais>.ibsstat.lgappstv.com` | Banners de la tienda y sus estadísticas |
| `<pais>.rdx2.lgtvsdp.com` | Reportes de uso |
| `<region>.cdpbeacon`, `cdpsvc`, `homeprv`, `nudge`, `recommend`, `rdl` `.lgtvcommon.com` | Telemetría: qué ves, recomendaciones, promociones y registros |

### Qué deja pasar, a propósito

`<pais>.lgtvsdp.com`, `ngfts.lge.com` (y `<region>-ngfts.lge.com`) e `<region>.imagesvc.lgtvcommon.com` **no** se
bloquean: la tienda de LG los necesita para cargar sus servicios e imágenes. Probado en la TV de prueba: la LG
Content Store carga con sus imágenes, y Netflix y YouTube abren normal.

### Qué no puede hacer

Los anuncios **dentro** de YouTube o Prime Video llegan por los mismos dominios que el video: bloquearlos por
`/etc/hosts` rompería la app. Para eso están **YouTube AdFree** y **AmazOff**, en Homebrew Channel.

### Apagar, quitar, comprobar y agregar dominios

| Quiero… | Cómo |
| --- | --- |
| Apagarlo sin desinstalar | `"bloqueoAnuncios": false` en `/var/lib/webosbrew/fullhomecustom/config.json` y reiniciar, o correr `sh /var/lib/webosbrew/tools/bloqueo.sh` |
| Quitar las líneas a mano | `sh /var/lib/webosbrew/tools/bloqueo.sh --quitar` (`uninstall.sh` también las quita) |
| Comprobar que funciona | `ping -c1 mx.ad.lgsmartad.com` en la TV debe mostrar `127.0.0.1`; `tail -5 /etc/hosts` muestra el final del bloque |
| Agregar un dominio | Edítalo en `/var/lib/webosbrew/tools/bloqueo-dominios.txt` y reinicia o corre `bloqueo.sh` |

> Ojo: `install.sh` vuelve a copiar `bloqueo-dominios.txt` del repo cada vez que reinstalas. Si agregaste
> dominios en la TV, guárdalos también en `tv/bloqueo-dominios.txt` de tu copia.

### ¿Y en el router?

Si prefieres bloquear en el router (Pi-hole, AdGuard Home, NextDNS), la lista comunitaria para TVs es
[`SmartTV.txt` de Perflyst/PiHoleBlocklist](https://github.com/Perflyst/PiHoleBlocklist). No se estorban: el
`/etc/hosts` de la TV y el router se complementan.

## Resultados medidos

| | Antes | Después |
| --- | --- | --- |
| RAM disponible en reposo | ~106 MB | ~160–250 MB |
| Swap en uso en reposo | ~265 MB | ~12–35 MB |
| Home (`fullhome`, RSS) | ~77 MB + 42 MB de swap | ~76 MB |

## ¿Qué tanto mejora la velocidad?

Hasta que la app queda en primer plano, medido después de reiniciar:

| | Tiempo |
| --- | --- |
| YouTube, en frío | 2.5 s |
| Prime Video, en frío | 3.2 s |
| Cambiar entre las dos, ya abiertas | 2.4 a 3.3 s |

Cambiar entre apps ya abiertas cuesta casi lo mismo que abrirlas en frío. Con dos apps abiertas, el swap sube
a ~140 MB: la TV manda a swap la que no estás viendo o la recarga. **El cuello de botella es la RAM y el chip de
2019.** Lo de este proyecto evita trabas en reposo y libera memoria, pero no hace instantáneo el cambio entre
apps.

### Quick Start+

Con Quick Start+ encendido (*Configuración → General → Quick Start+*), la TV se suspende en vez de apagarse:
prende al instante y conserva el home renovado entre encendidos, sin la ventana de ~45 s con el diseño de LG.
Gasta un poco más en espera. Si lo usas, el root y los scripts solo vuelven a correr después de un reinicio
real o de desconectar la TV. *(Probado: la TV de prueba lo tiene encendido; prende al instante y el home
renovado sigue ahí.)*

Siguiente: **[7. Problemas y desinstalar](07-problemas-y-desinstalar.md)**.
