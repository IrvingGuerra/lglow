# LGlow

**LGlow** ("¿Tu vieja LG necesita un glow up?" / "Your old LG TV needs a glow up"): home renovado para TVs LG con webOS 4.x rooteadas. Es el repo público que salió del proyecto local
`../lglow-claude` (bitácora completa en `../lglow-claude/STATUS.md`).

## Reglas de este repo

- **Nunca subir código de LG.** `tv/patches/` solo lleva diffs, y `tv/qml/` solo componentes nuestros. Los
  árboles completos del QML de LG viven fuera del repo (en `../lglow-claude/*/original` y `*/mod`) y están en
  `.gitignore` por si acaso.
- **Nada personal:** ni la IP de la TV de Irving, ni su ciudad, ni su llave de TMDB, ni llaves SSH.
  `config.json` y `tools/tiles/` están en `.gitignore`.
- Textos, comentarios y commits en español.

## Flujo de cambios

1. Editar la copia de trabajo en `../lglow-claude/fullhome-custom/mod/qml` (o `home-custom/mod/qml`).
2. Regenerar los parches:
   `python3 tools/regenerar-parches.py ../lglow-claude/fullhome-custom/original ../lglow-claude/fullhome-custom/mod tv/patches/fullhome`.
   Si cambió un componente nuevo, copiarlo a `tv/qml/fullhome/`.
3. Probar en la TV de Irving con `./instalar.sh tv` (alias SSH `tv` en `~/.ssh/config`, root en el puerto 22) y
   comprobar en vivo: capturas con `luna://com.webos.service.tv.capture/executeOneShot` y teclas con
   `node /var/lib/webosbrew/tools/key.js`. Ver `docs/05-como-funciona.md`.
4. **No tocar la TV mientras Irving la está viendo.** Las capturas y teclas simuladas se ven en pantalla.
   Preguntar antes.

## Sitio web

Landing en inglés en `site/` (HTML/CSS/JS sin build). El workflow `.github/workflows/pages.yml` la publica en
https://irvingguerra.github.io/lglow/ en cada push a `main` que toque `site/` o `docs/img/`, copiando las capturas
de `docs/img` a `img/`. Para probarla en local, armar esa misma carpeta (site + `img/`) y servirla con
`python3 -m http.server`.

## Publicar

Publicado en github.com/IrvingGuerra/lglow (público). Como es público, revisar que ningún cambio meta datos
personales (IP, ciudad, llaves) antes de cada push.
