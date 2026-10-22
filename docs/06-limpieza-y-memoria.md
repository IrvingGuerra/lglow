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
real o de desconectar la TV. *(No probado en la TV de prueba, que se dejó con Quick Start+ apagado.)*

Siguiente: **[7. Problemas y desinstalar](07-problemas-y-desinstalar.md)**.
