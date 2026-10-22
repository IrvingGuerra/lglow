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
- **Guías en dos idiomas:** `docs/*.md` (español) y `docs/en/*.md` (inglés, con nombres en inglés). Cada una enlaza
  a la otra bajo el título. Si cambias una guía, cambia también su par; la web en inglés y `README.en.md` enlazan
  a `docs/en/`.

## Flujo de cambios

1. Editar la copia de trabajo en `../lglow-claude/fullhome-custom/mod/qml` (o `home-custom/mod/qml`).
2. Regenerar los parches:
   `python3 tools/regenerar-parches.py ../lglow-claude/fullhome-custom/original ../lglow-claude/fullhome-custom/mod tv/patches/fullhome`.
   Si cambió un componente nuevo, copiarlo a `tv/qml/fullhome/`.
3. Probar en la TV de Irving con `./instalar.sh tv` (alias SSH `tv` en `~/.ssh/config`, root en el puerto 22) y
   comprobar en vivo: capturas con `luna://com.webos.service.tv.capture/executeOneShot` y teclas con
   `node /var/lib/webosbrew/tools/key.js`. Ver `docs/05-como-funciona.md`.
4. **Control total de la TV sin preguntar** (capturas, teclas, relanzar el home, abrir apps, reiniciar), salvo
   que Irving diga que la está usando. Al terminar, cerrar las apps abiertas y dejarla en el home.

## Sitio web

Landing en inglés en `site/` (HTML/CSS/JS sin build). El workflow `.github/workflows/pages.yml` la publica en
https://irvingguerra.github.io/lglow/ en cada push a `main` que toque `site/` o `docs/img/`, copiando las capturas
de `docs/img` a `img/`. Para probarla en local, armar esa misma carpeta (site + `img/`) y servirla con
`python3 -m http.server`.

**Dos idiomas:** la fuente es `site/index.html` (inglés). `site/es/index.html` (español) **no se edita a mano**: se
genera con `python3 tools/sitio-es.py`, que traduce texto por texto y se detiene si algún texto en inglés cambió
(entonces hay que actualizar su traducción en el script). Los navegadores en español se redirigen a `/es/`; el
botón EN/ES guarda la elección en `localStorage`. Las imágenes para compartir (`og.jpg`, `og-es.jpg`) salen de
`python3 tools/og.py`. El prompt para IA vive en la web y en los dos README: si cambia, cambiarlo en los cuatro.

## Logo

"Amanecer en la pantalla": TV oscura con un sol naranja→rosa→morado que sale desde abajo. Archivos en
`docs/img/marca/` (icono, logo horizontal claro/oscuro, ícono de app, `social-preview.png` para
GitHub → Settings → Social preview). Los SVG salen de `python3 tools/logo.py <inter-800.ttf>` (letras convertidas
a trazos, Inter OFL); `site/favicon.svg` también. Los PNG se exportaron con un navegador (WebKit/Playwright).
**No usar el logo de LG**: es marca registrada y LGlow no está afiliado a LG.

## Publicar

Publicado en github.com/IrvingGuerra/lglow (público). Como es público, revisar que ningún cambio meta datos
personales (IP, ciudad, llaves) antes de cada push.
