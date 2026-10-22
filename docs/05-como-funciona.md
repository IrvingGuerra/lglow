# 5. Cómo funciona (por dentro)

[English](en/05-how-it-works.md)

Para quien quiera entenderlo, adaptarlo a otro modelo o contribuir.

## Dos homes en webOS 4.10

| App | Qué es |
| --- | --- |
| `com.webos.app.fullhome` | El home de pantalla completa que sale con la tecla Home desde la actualización de diciembre de 2023 (firmware 05.40.09): banner, filas y apps cuadradas. `defaultApps.home` apunta a esta. |
| `com.webos.app.home` | La barra clásica de webOS 4.5 con mosaicos inclinados. Sigue cargada en memoria aunque casi no se usa. |

Los dos están hechos en **QML** (texto plano), en `/usr/palm/applications/<app>/qml`, dentro de una partición
de solo lectura y firmada. En webOS 10 el home es Flutter; aquí no.

## Montar encima, sin tocar el original

Igual que en [webos10-homescreen-customization](https://github.com/mareklarek/webos10-homescreen-customization):

```sh
mount --bind /var/lib/webosbrew/fullhomecustom/qml /usr/palm/applications/com.webos.app.fullhome/qml
```

El montaje vive en memoria. Al reiniciar desaparece, y `init.d/10-homecustom` lo vuelve a hacer. Si algo
sale mal, basta con no montarlo.

## El truco de CRIU (clave en webOS 4)

Montar el QML **no basta**: el home no se carga desde los archivos, se **restaura con CRIU** (checkpoint/restore)
desde una imagen de fábrica que ya trae el QML original en memoria:

- `/etc/palm/sam-conf-tv.json` → `CRIUSupportApps` incluye `com.webos.app.home` y `com.webos.app.fullhome`.
- Las imágenes viven en `/tmp/checkpoint/<app>` y en `/mnt/lg/cmn_data/checkpoint/<app>`. Si borras la de
  `/tmp`, el servicio `criu` la vuelve a copiar desde `cmn_data`. Marcarla como `invalid_img` tampoco sirve.

Lo que sí funciona: **tapar las dos carpetas con una carpeta vacía** (otro `mount --bind`) y matar el proceso.
SAM no encuentra imagen, lanza el home en limpio y lee el QML montado. Tampoco esto borra nada.

## El orden y el momento del arranque

- Con Quick Start+ apagado, cada encendido es un arranque completo que regresa del snapshot de fábrica
  (`/sys/power/mode = resume`).
- El `startup.sh` de Homebrew Channel lo dispara el sistema hacia el **segundo ~42**, y entonces corre
  `run-parts /var/lib/webosbrew/init.d`.
- `10-homecustom` va primero y tarda menos de un segundo: el home queda listo hacia el **segundo ~45**.
- Si en ese momento el home ya estaba en pantalla, se relanza al instante con el diseño nuevo. El script lo
  sabe por el último `NL_VSC … "visible":true` del fullhome en `/var/log/messages`.
- `60-sinprecarga` corre después y todo en segundo plano: con la TV recién encendida, cada `luna-send` tarda
  varios segundos.

## Los cambios al home (tv/patches y tv/qml)

| Archivo | Cambio |
| --- | --- |
| `Configurations/SystemServiceResponseProcessors.js` | Filtra `listLaunchPoints` con `HIDDEN_IDS` (apps ocultas), incluidos los cambios incrementales. |
| `Interfaces/AppInterfaces/AppInterfaces.qml` | `isDefaultShelf: true`: el modo sin conexión de LG, sin filas de contenido del servidor. |
| `Model/ShelfList.js` | Deja solo `HOME_SH_TOP` y `HOME_SH_APPS`. |
| `Containers/Main/Hero.qml`, `TopShelf.qml`, `AppInitializer/SystemProperties.qml` | Sin banners publicitarios, sin "Comience una nueva experiencia / Ir a Apps". |
| `Containers/MainView.qml` | Fondo propio; fila de apps abajo (`appListHomeY`); "Para ti"; pantalla Apps; cadena de foco. |
| `GlobalStyle.qml`, `LaunchPoint.qml`, `AppTile.qml`, `TopGlobalAction.qml` | Tiles 5:3 sin borde, íconos de arriba oscuros. |
| **Nuevos:** `AppGrid.qml`, `ParaTi.qml`, `AllAppsPage.qml` | La fila de apps (modos `pinned` y `all`), el encabezado con tendencias y la segunda pantalla. |

La fila original de LG (`MainRibbon`) sigue cargada, invisible, porque mucho código del home depende de ella.
En el modo edición (lápiz) se muestra la de LG.

### Detalles que costaron trabajo

- **Foco al volver de una app.** `MainView` tiene `visible: isAppForeground`: al abrir una app, todo el home se
  vuelve invisible y pierde el foco. `AppGrid.claimFocus()` lo recupera cuando vuelve a ser visible, y también
  cuando el preloadmanager precarga el home en segundo plano.
- **Atrás.** El compositor solo le pasa la tecla al home si su ventana tiene
  `_WEBOS_ACCESS_POLICY_KEYS_BACK = "true"`. Además, LG cierra el home al **soltar** Atrás
  (`UIController.Keys.onReleased → goBack`). Por eso la pantalla Apps cierra al soltar: si cerrara al
  presionar, el soltar le llegaría a LG y haría un segundo "atrás".
- **Navegación en `GridView`.** Con `interactive: false`, en Qt 5.6 el `GridView` ignora las flechas; se
  manejan a mano.
- **Tecla Home del control** = `Qt.Key_Super_L` (evdev `KEY_LEFTMETA`, 125). El compositor hace
  `applicationManager.launch(defaultApp, {"launchType": "homeKey"})`.

## Herramientas para depurar

- `tv/key.js` (en la TV, `/var/lib/webosbrew/tools/key.js`): simula el control escribiendo eventos en
  `/dev/input/event1` (LGE RCU). Ejemplo: `node /var/lib/webosbrew/tools/key.js HOME DOWN ENTER`.
  Home = 125, OK = 28, flechas 103/108/105/106. Atrás = 14, que llega como `Key_Backspace` (el Atrás físico
  llega como `Key_webOS_Back`).
- Captura de pantalla:
  `luna-send -n 1 luna://com.webos.service.tv.capture/executeOneShot '{"path":"/tmp/cap.png","method":"DISPLAY","format":"PNG","width":1920,"height":1080}'`
- Log del home: `/var/log/fullhome`. Eventos del compositor: `grep NL_ /var/log/messages`.

## Regenerar los parches para otro firmware

Si tu TV tiene otra versión del home, los md5 no van a coincidir. Para portarlo:

1. Copia el QML original de tu TV: `ssh tv "tar cf - -C /usr/palm/applications/com.webos.app.fullhome qml" | tar xf - -C original/`
2. Copia ese árbol a `mod/` y aplica a mano los cambios de `tv/patches/fullhome` (aplicarán casi todos con
   `patch -p1 --fuzz=3`; los que no, se ajustan viendo el contexto).
3. Copia los tres QML nuevos de `tv/qml/fullhome` a `mod/qml/UserInterfaceLayer/Containers/Main/`.
4. `python3 tools/regenerar-parches.py original mod tv/patches/fullhome` genera los `.patch` y los md5.

Haz lo mismo con `com.webos.app.home` → `tv/patches/home`. Manda un PR con tu modelo y firmware.
