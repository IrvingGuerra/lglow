# lg-webos4-home

Home renovado para TVs LG con webOS 4.x rooteadas. Es el repo público que salió del proyecto local
`../lg-tv-cleanup` (bitácora completa en `../lg-tv-cleanup/STATUS.md`).

## Reglas de este repo

- **Nunca subir código de LG.** `tv/patches/` solo lleva diffs, y `tv/qml/` solo componentes nuestros. Los
  árboles completos del QML de LG viven fuera del repo (en `../lg-tv-cleanup/*/original` y `*/mod`) y están en
  `.gitignore` por si acaso.
- **Nada personal:** ni la IP de la TV de Irving, ni su ciudad, ni su llave de TMDB, ni llaves SSH.
  `config.json` y `tools/tiles/` están en `.gitignore`.
- Textos, comentarios y commits en español.

## Flujo de cambios

1. Editar la copia de trabajo en `../lg-tv-cleanup/fullhome-custom/mod/qml` (o `home-custom/mod/qml`).
2. Regenerar los parches:
   `python3 tools/regenerar-parches.py ../lg-tv-cleanup/fullhome-custom/original ../lg-tv-cleanup/fullhome-custom/mod tv/patches/fullhome`.
   Si cambió un componente nuevo, copiarlo a `tv/qml/fullhome/`.
3. Probar en la TV de Irving con `./instalar.sh tv` (alias SSH `tv` en `~/.ssh/config`, root en el puerto 22) y
   comprobar en vivo: capturas con `luna://com.webos.service.tv.capture/executeOneShot` y teclas con
   `node /var/lib/webosbrew/tools/key.js`. Ver `docs/05-como-funciona.md`.
4. **No tocar la TV mientras Irving la está viendo.** Las capturas y teclas simuladas se ven en pantalla.
   Preguntar antes.

## Publicar

El repo es para GitHub (`irvingguerra/lg-webos4-home`). **No crearlo ni hacer push sin el OK explícito de
Irving.** Es la única excepción a su regla de "commit + push + deploy sin preguntar": publicarlo es público.
