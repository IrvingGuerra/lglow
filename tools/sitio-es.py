#!/usr/bin/env python3
"""Genera site/es/index.html traduciendo site/index.html.

Cada texto se busca tal cual en la página en inglés: si alguno cambió, el script se detiene
para que la traducción no se quede atrás. Uso: python3 tools/sitio-es.py
"""
import os
import sys

RAIZ = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "site")

T = [
    # Cabecera, rutas e idioma
    ('<html lang="en">', '<html lang="es">'),
    ('''    // Spanish browsers get the Spanish page; the EN/ES switch wins.
    (function () {
      var lang;
      try { lang = localStorage.getItem("lang"); } catch (e) {}
      if (!lang && /^es\\b/i.test(navigator.language || "")) location.replace("es/" + location.hash);
    })();
''', ''),
    ('<title>LGlow — your old LG TV needs a glow up</title>', '<title>LGlow — ¿tu vieja LG necesita un glow up?</title>'),
    ('content="A clean, fast, ad-free home screen for 2019 LG TVs on webOS 4.5. Trending picks from your own apps, the weather at a glance, big app tiles and more free memory. Open source, one command to undo."',
     'content="Un home limpio, rápido y sin publicidad para TVs LG de 2019 con webOS 4.5. Tendencias de tus propias apps, el clima a la vista, apps grandes y más memoria libre. Código abierto; se quita con un comando."'),
    ('<link rel="canonical" href="https://irvingguerra.github.io/lglow/">', '<link rel="canonical" href="https://irvingguerra.github.io/lglow/es/">'),
    ('<meta property="og:url" content="https://irvingguerra.github.io/lglow/">', '<meta property="og:url" content="https://irvingguerra.github.io/lglow/es/">\n  <meta property="og:locale" content="es_MX">'),
    ('<meta property="og:title" content="LGlow — your old LG TV needs a glow up">', '<meta property="og:title" content="LGlow — ¿tu vieja LG necesita un glow up?">'),
    ('content="A clean, fast, ad-free home screen for 2019 LG TVs on webOS 4.5. Open source, one command to undo."',
     'content="Un home limpio, rápido y sin publicidad para TVs LG de 2019 con webOS 4.5. Código abierto; se quita con un comando."'),
    ('lglow/og.jpg', 'lglow/og-es.jpg'),
    ('lglow/og.jpg', 'lglow/og-es.jpg'),
    ('href="favicon.svg"', 'href="../favicon.svg"'),
    ('href="apple-touch-icon.png"', 'href="../apple-touch-icon.png"'),
    ('src="favicon.svg"', 'src="../favicon.svg"'),
    ('href="styles.css"', 'href="../styles.css"'),
    ('src="app.js"', 'src="../app.js"'),
    ('aria-label="LGlow, back to top"', 'aria-label="LGlow, volver arriba"'),
    ('aria-label="Sections"', 'aria-label="Secciones"'),
    ('<a href="#compare">Before &amp; after</a>', '<a href="#compare">Antes y después</a>'),
    ('<a href="#features">Features</a>', '<a href="#features">Funciones</a>'),
    ('<a href="#install">Install</a>', '<a href="#install">Instalar</a>'),
    ('<a href="#faq">FAQ</a>', '<a href="#faq">Preguntas</a>'),
    ('<a class="lang" href="es/" hreflang="es" lang="es" data-lang="es" aria-label="Leer en español">ES</a>',
     '<a class="lang" href="../" hreflang="en" lang="en" data-lang="en" aria-label="Read in English">EN</a>'),

    # Portada
    ('Open source · LG webOS 4.5 · 2019 TVs', 'Código abierto · LG webOS 4.5 · TVs de 2019'),
    ('<h1 data-reveal>Your old LG needs a <span class="glow">glow&nbsp;up.</span></h1>',
     '<h1 data-reveal>¿Tu vieja LG necesita un <span class="glow">glow&nbsp;up?</span></h1>'),
    ('A clean, fast, ad-free home screen built on top of the stock one. Trending picks from your own apps, the weather at a glance, big app tiles, and more free memory. One command to undo.',
     'Un home limpio, rápido y sin publicidad, hecho sobre el original. Lo que está en tendencia en tus propias apps, el clima a la vista, apps grandes y más memoria libre. Se quita con un comando.'),
    ('Get it on GitHub <span aria-hidden="true">→</span>', 'Descárgalo en GitHub <span aria-hidden="true">→</span>'),
    ('<a class="btn btn-glass" href="#compare">See before &amp; after</a>', '<a class="btn btn-glass" href="#compare">Ver antes y después</a>'),
    ('src="img/despues-home.jpg" width="1920" height="1080" alt="The LGlow home: a For you row with three trending titles, date, time and weather, and one row of big app tiles"',
     'src="../img/despues-home.jpg" width="1920" height="1080" alt="El home de LGlow: Para ti con tres títulos en tendencia, fecha, hora y clima, y una fila de apps grandes"'),
    ('Real screenshot from a 2019 LG 43LM5770PUA.', 'Captura real de una LG 43LM5770PUA de 2019.'),

    # Cifras
    ('aria-label="Results on the test TV"', 'aria-label="Resultados en la TV de prueba"'),
    ('<span>LG ads on the home screen</span>', '<span>anuncios de LG en el home</span>'),
    ('<span>free RAM at idle<br>', '<span>RAM libre en reposo<br>'),
    ('<span>swap in use<br>', '<span>swap en uso<br>'),
    ('<span>command to undo it all</span>', '<span>comando para quitarlo todo</span>'),

    # Antes y después
    ('<p class="kicker">Before &amp; after</p>', '<p class="kicker">Antes y después</p>'),
    ('<h2>Same TV. A whole new home.</h2>', '<h2>La misma TV. Un home nuevo.</h2>'),
    ("Drag the handle. Out go the LG banner, the sponsored rows and the wall of system apps. In comes what's trending in <em>your</em> apps.",
     'Arrastra el control. Fuera el banner de LG, las filas patrocinadas y el muro de apps del sistema. Llega lo que está en tendencia en <em>tus</em> apps.'),
    ('src="img/despues-home.jpg" width="1920" height="1080" alt="After: the LGlow home"', 'src="../img/despues-home.jpg" width="1920" height="1080" alt="Después: el home de LGlow"'),
    ('src="img/antes-home.jpg" width="1280" height="720" alt="Before: the stock LG home with a banner and sponsored content"',
     'src="../img/antes-home.jpg" width="1280" height="720" alt="Antes: el home original de LG con banner y contenido patrocinado"'),
    ('<span class="ba-tag ba-tag-l">Before</span>', '<span class="ba-tag ba-tag-l">Antes</span>'),
    ('<span class="ba-tag ba-tag-r">After</span>', '<span class="ba-tag ba-tag-r">Después</span>'),
    ('aria-label="Compare before and after"', 'aria-label="Comparar antes y después"'),

    # Funciones
    ('<p class="kicker">What you get</p>', '<p class="kicker">Qué obtienes</p>'),
    ('<h2>Lighter, cleaner, actually yours.</h2>', '<h2>Más ligera, más limpia, de verdad tuya.</h2>'),
    ('<h3>No LG ads</h3>', '<h3>Sin publicidad de LG</h3>'),
    ('No banner, no sponsored content rows, no screensaver ads, no ad cookie.', 'Sin banner, sin filas de contenido patrocinado, sin anuncios en el protector de pantalla y sin cookie publicitaria.'),
    ('<h3>For you</h3>', '<h3>Para ti</h3>'),
    ('Three trending titles every hour, <b>only from apps you have</b>. Explore, Movies and Shows tabs. OK opens the app that has it.',
     'Tres títulos en tendencia cada hora, <b>solo de las apps que tienes</b>. Pestañas Explorar, Películas y Series. OK abre la app donde está.'),
    ('<h3>Weather, date &amp; time</h3>', '<h3>Clima, fecha y hora</h3>'),
    ('For your city, at a glance. Powered by Open-Meteo, no key needed.', 'De tu ciudad, a la vista. Con Open-Meteo, sin llave.'),
    ('<h3>Big app tiles</h3>', '<h3>Apps grandes</h3>'),
    ("One row of your 6 favorite apps in each brand's color. The rest peeks out below: press ↓ and the home scrolls down to all of them.",
     'Una fila con tus 6 apps favoritas, cada una con el color de su marca. Abajo se asoma el resto: presiona ↓ y el home baja hasta todas.'),
    ('<h3>More free memory</h3>', '<h3>Más memoria libre</h3>'),
    ('The old launcher bar stops running and LG stops preloading Netflix, YouTube and Prime behind your back.',
     'La barra vieja deja de correr y LG deja de precargar Netflix, YouTube y Prime a tus espaldas.'),
    ('<h3>Root protection</h3>', '<h3>Root blindado</h3>'),
    ('Disables a Developer Mode trap that <b>wipes Homebrew Channel and root</b> on the next reboot.',
     'Desactiva una trampa de Developer Mode que <b>borra Homebrew Channel y el root</b> en el siguiente reinicio.'),

    # Capturas
    ('<p class="kicker">A closer look</p>', '<p class="kicker">De cerca</p>'),
    ('<h2>Every screen, refreshed.</h2>', '<h2>Cada pantalla, renovada.</h2>'),
    ('src="img/despues-titulo.jpg" width="1920" height="1080" alt="Movies tab with a title selected"', 'src="../img/despues-titulo.jpg" width="1920" height="1080" alt="Pestaña Películas con un título seleccionado"'),
    ('<b>Movies &amp; Shows tabs.</b> Pick a title and it opens in the app that has it.', '<b>Pestañas Películas y Series.</b> Elige un título y se abre en la app donde está.'),
    ('src="img/despues-apps.jpg" width="1920" height="1080" alt="All apps, after scrolling down from the app row"', 'src="../img/despues-apps.jpg" width="1920" height="1080" alt="Todas las apps, después de bajar desde la fila"'),
    ('<b>All your apps, one scroll away.</b> Press ↓ from the app row. Back takes you home.', '<b>Todas tus apps, a un scroll.</b> Presiona ↓ desde la fila de apps. Atrás te regresa al home.'),
    ('src="img/despues-oscuro.jpg" width="1920" height="1080" alt="The LGlow home in dark mode"', 'src="../img/despues-oscuro.jpg" width="1920" height="1080" alt="El home de LGlow en modo oscuro"'),
    ("<b>Light, dark or automatic.</b> Auto follows your city's real sunrise and sunset.", '<b>Claro, oscuro o automático.</b> El automático sigue el amanecer y el atardecer reales de tu ciudad.'),
    ('src="img/despues-panel.jpg" width="1920" height="1080" alt="LGlow\'s quick settings panel over the home"', 'src="../img/despues-panel.jpg" width="1920" height="1080" alt="El panel de ajustes rápidos de LGlow sobre el home"'),
    ("<b>Quick settings, redone.</b> The remote's gear button opens LGlow's panel: picture and sound modes, sleep timer, theme and inputs.",
     '<b>Ajustes rápidos, renovados.</b> El botón de engranaje del control abre el panel de LGlow: modos de imagen y sonido, apagado automático, tema y entradas.'),
    ('src="img/tiles.jpg" width="1320" height="636" alt="Rectangular tiles generated from each app\'s icon"', 'src="../img/tiles.jpg" width="1320" height="636" alt="Tiles rectangulares generados a partir del ícono de cada app"'),
    ("<b>Tiles made from your TV.</b> Generated from each app's own icon and color, in high resolution.", '<b>Tiles hechos con tu TV.</b> Se generan con el ícono y el color de cada app, en alta resolución.'),
    ('src="img/despues-carga.jpg" width="1920" height="1080" alt="Netflix loading screen: its tile over a soft sunrise glow, with three dots"', 'src="../img/despues-carga.jpg" width="1920" height="1080" alt="Pantalla de carga de Netflix: su tile sobre un brillo suave de amanecer, con tres puntos"'),
    ("<b>A loading screen for each app.</b> Netflix, Prime Video and YouTube get their own tile instead of LG's grey cubes.", '<b>Una pantalla de carga para cada app.</b> Netflix, Prime Video y YouTube muestran su propio tile en vez de los cubos grises de LG.'),

    # Comparación
    ('<h2>An app on top, or the TV itself?</h2>', '<h2>¿Una app encima o la TV misma?</h2>'),
    ("inspired LGlow's design, and it's a great pick <b>if you don't want to root</b>. LGlow goes deeper.",
     'inspiró el diseño de LGlow y es una gran opción <b>si no quieres rootear</b>. LGlow va más a fondo.'),
    ('<th>Free My TV on LG</th>', '<th>Free My TV en LG</th>'),
    ('<tr><th>What it is</th><td data-label="Free My TV">Another app (a launcher), installed through Developer Mode</td><td class="hl" data-label="LGlow">Replaces the system\'s own home, the one the Home button opens</td></tr>',
     '<tr><th>Qué es</th><td data-label="Free My TV">Una app más (un launcher) que se instala con Developer Mode</td><td class="hl" data-label="LGlow">Cambia el home del propio sistema: el que abre el botón Home</td></tr>'),
    ("<tr><th>LG's home</th><td data-label=\"Free My TV\">Stays, ads included. Opens with a number key</td><td class=\"hl\" data-label=\"LGlow\">Gone. Home opens the new one directly</td></tr>",
     '<tr><th>El home de LG</th><td data-label="Free My TV">Se queda, con todo y anuncios. Se abre con una tecla numérica</td><td class="hl" data-label="LGlow">Desaparece. Home abre directamente el nuevo</td></tr>'),
    ('<td data-label="Free My TV">Not needed</td><td class="hl" data-label="LGlow">Required</td>', '<td data-label="Free My TV">No hace falta</td><td class="hl" data-label="LGlow">Sí</td>'),
    ('<td data-label="Free My TV">Renew every ~40 days or the app is removed</td><td class="hl" data-label="LGlow">Not used, and its root-wiping trap is disabled</td>',
     '<td data-label="Free My TV">Hay que renovarlo cada ~40 días o la app se borra</td><td class="hl" data-label="LGlow">No se usa, y se desactiva su trampa que borra el root</td>'),
    ('<tr><th>Beyond the home</th><td data-label="Free My TV">—</td><td class="hl" data-label="LGlow">Hides system apps, stops preloads and ads, frees RAM, blocks updates that remove root</td></tr>',
     '<tr><th>Más allá del home</th><td data-label="Free My TV">—</td><td class="hl" data-label="LGlow">Oculta apps del sistema, apaga precargas y publicidad, libera RAM y bloquea las actualizaciones que quitan el root</td></tr>'),
    ('<td data-label="Free My TV">webOS 3+, Google TV, Samsung</td><td class="hl" data-label="LGlow">LG webOS 4.5, 2019 models</td>',
     '<td data-label="Free My TV">webOS 3 o más nuevo, Google TV, Samsung</td><td class="hl" data-label="LGlow">LG webOS 4.5, modelos de 2019</td>'),

    # Instalar
    ('<p class="kicker">Install</p>', '<p class="kicker">Instalar</p>'),
    ('<h2>Five steps. One command for the home.</h2>', '<h2>Cinco pasos. Un comando para el home.</h2>'),
    ('<p>Each step has its own detailed guide in the repo.</p>', '<p>Cada paso tiene su guía detallada en el repo.</p>'),
    ('<h3>Root the TV</h3>', '<h3>Rootear la TV</h3>'),
    ('<h3>Disarm the Developer Mode trap</h3><p>Required if LG\'s Developer Mode app is still installed.</p>',
     '<h3>Desactivar la trampa de Developer Mode</h3><p>Obligatorio si la app Developer Mode de LG sigue instalada.</p>'),
    ("<h3>SSH &amp; block updates</h3><p>So an LG update can't take root away.</p>", '<h3>SSH y bloqueo de actualizaciones</h3><p>Para que una actualización de LG no quite el root.</p>'),
    ('<h3>Install the new home</h3><p>One command from your computer.</p>', '<h3>Instalar el home nuevo</h3><p>Un comando desde tu computadora.</p>'),
    ('<h3>Clean up &amp; free memory</h3><p>Optional. Turns off ads and preloads.</p>', '<h3>Limpieza y memoria</h3><p>Opcional. Apaga publicidad y precargas.</p>'),
    ('Guide →', 'Guía →'),
    ('blob/main/docs/en/01-root.md', 'blob/main/docs/01-rootear.md'),
    ('blob/main/docs/en/02-developer-mode-trap.md', 'blob/main/docs/02-trampa-developer-mode.md'),
    ('blob/main/docs/en/03-access-and-updates.md', 'blob/main/docs/03-acceso-y-actualizaciones.md'),
    ('blob/main/docs/en/04-install-home.md', 'blob/main/docs/04-instalar-home.md'),
    ('blob/main/docs/en/06-cleanup-and-memory.md', 'blob/main/docs/06-limpieza-y-memoria.md'),
    ('<span>Already rooted with SSH?</span><button class="copy" type="button" data-strip>Copy</button>',
     '<span>¿Ya tienes root y SSH?</span><button class="copy" type="button" data-strip data-done="Copiado">Copiar</button>'),
    ("# your TV's IP", '# la IP de tu TV'),
    ('# tiles from your app icons', '# tiles con los íconos de tus apps'),
    ('Undo everything: <code>./instalar.sh 192.168.1.50 --quitar</code> and reboot the TV.', 'Para quitarlo todo: <code>./instalar.sh 192.168.1.50 --quitar</code> y reinicia la TV.'),
    ('<p class="kicker">Prefer a guide?</p>', '<p class="kicker">¿Prefieres que te guíen?</p>'),
    ('<h3>Let your AI walk you through it.</h3>', '<h3>Que tu IA te lleve paso a paso.</h3>'),
    ("<p>Paste this prompt into ChatGPT, Claude, Gemini or any assistant that can read the web. Fill in your TV's details first: it reads the repo, checks if your TV fits and guides you one step at a time.</p>",
     '<p>Pega este prompt en ChatGPT, Claude, Gemini o cualquier asistente que pueda leer la web. Antes llena los datos de tu TV: lee el repo, revisa si tu TV es compatible y te guía un paso a la vez.</p>'),
    ('<span>Prompt for your AI</span><button class="copy" type="button">Copy</button>', '<span>Prompt para tu IA</span><button class="copy" type="button" data-done="Copiado">Copiar</button>'),
    ('''I want to install LGlow (https://github.com/IrvingGuerra/lglow) on my LG TV. Be my step-by-step guide.

My TV:
- Model: [e.g. 43LM5770PUA, on the sticker or in Settings → General → About this TV]
- webOS TV version: [e.g. 4.10.2]
- Software version: [e.g. 05.40.97]
- My computer: [macOS / Windows / Linux]

How to help me:
1. Read the repo's README.en.md and the English guides in docs/en/ first. Use them as the source of truth, not your memory.
2. Check compatibility before anything else. LGlow is made for 2019 LG TVs on webOS 4.5 with the full-screen home (com.webos.app.fullhome, firmware 05.40.09 or newer). Tell me honestly if my TV fits, and have me check root status on https://cani.rootmy.tv.
3. Walk me through the guides in order: 01 root, 02 Developer Mode trap, 03 SSH and update blocking, 04 install, 06 optional cleanup. One step at a time: wait for me to confirm or paste the output before moving on.
4. Explain what each command does before I run it, and warn me clearly before anything risky.
5. Never suggest writing to LG's read-only partitions, never tell me to open, reinstall or update LG's Developer Mode app, and don't update the TV's firmware.
6. If the installer says the files don't match my firmware, don't force it: help me port the patches following docs/en/05-how-it-works.md ("Regenerating the patches for another firmware").
7. If something goes wrong, the way back is ./instalar.sh &lt;TV IP&gt; --quitar and a reboot (docs/en/07-troubleshooting-and-uninstall.md).''',
     '''Quiero instalar LGlow (https://github.com/IrvingGuerra/lglow) en mi TV LG. Sé mi guía paso a paso.

Mi TV:
- Modelo: [p. ej. 43LM5770PUA, viene en la etiqueta o en Configuración → General → Acerca de esta TV]
- Versión de webOS TV: [p. ej. 4.10.2]
- Versión de software: [p. ej. 05.40.97]
- Mi computadora: [macOS / Windows / Linux]

Cómo ayudarme:
1. Primero lee el README del repo y las guías de docs/. Úsalas como fuente de verdad, no tu memoria.
2. Antes que nada, revisa la compatibilidad. LGlow es para TVs LG de 2019 con webOS 4.5 y el home de pantalla completa (com.webos.app.fullhome, firmware 05.40.09 o más nuevo). Dime con honestidad si mi TV entra, y pídeme revisar en https://cani.rootmy.tv si se puede rootear.
3. Llévame por las guías en orden: 01 root, 02 trampa de Developer Mode, 03 SSH y bloqueo de actualizaciones, 04 instalar, 06 limpieza opcional. Un paso a la vez: espera a que confirme o pegue la salida antes de seguir.
4. Explícame qué hace cada comando antes de correrlo y avísame con claridad antes de cualquier cosa riesgosa.
5. Nunca sugieras escribir en las particiones de solo lectura de LG, nunca me digas que abra, reinstale o actualice la app Developer Mode de LG, y no actualices el firmware de la TV.
6. Si el instalador dice que los archivos no coinciden con mi firmware, no lo fuerces: ayúdame a portar los parches con docs/05-como-funciona.md ("Regenerar los parches para otro firmware").
7. Si algo sale mal, para regresar todo está ./instalar.sh &lt;IP de la TV&gt; --quitar y reiniciar (docs/07-problemas-y-desinstalar.md).'''),

    # Compatibilidad
    ('<p class="kicker">Compatibility</p>', '<p class="kicker">Compatibilidad</p>'),
    ('<h2>Made for the 2019 LGs.</h2>', '<h2>Hecho para las LG de 2019.</h2>'),
    ("<p>What matters isn't the year on the box but how the TV's home is built. LGlow patches the QML home of webOS 4.5, so it fits the whole 2019 lineup with the full-screen home.</p>",
     '<p>Lo que importa no es el año de la caja, sino cómo está hecho el home de la TV. LGlow parcha el home en QML de webOS 4.5, así que sirve para toda la línea 2019 con el home de pantalla completa.</p>'),
    ('<span class="badge no">Not supported</span><h3>2018</h3>', '<span class="badge no">No compatible</span><h3>2018</h3>'),
    ('<p>Rootable, but it never got the full-screen home LGlow is built on.</p>', '<p>Se puede rootear, pero nunca recibió el home de pantalla completa sobre el que está hecho LGlow.</p>'),
    ('<span class="badge ok">Supported</span>', '<span class="badge ok">Compatible</span>'),
    ('<p>With the full-screen home LG rolled out in December 2023 (firmware 05.40.09+): B9 and UM/SM/LM LCDs first, then C9 and E9.</p>',
     '<p>Con el home de pantalla completa que LG mandó en diciembre de 2023 (firmware 05.40.09+): primero B9 y las LCD UM/SM/LM, luego C9 y E9.</p>'),
    ('<span class="badge port">Portable</span>', '<span class="badge port">Portable</span>'),
    ('<p class="os">webOS 5 to 9</p><p>Also a QML home, so the technique carries over with new patches. But the latest firmware blocks the root exploit.</p>',
     '<p class="os">webOS 5 a 9</p><p>El home también es QML: la técnica sirve con parches nuevos. Pero el firmware más reciente bloquea el exploit de root.</p>'),
    ('<span class="badge no">Not supported</span><h3>2025</h3>', '<span class="badge no">No compatible</span><h3>2025</h3>'),
    ('<p>The home was rewritten in Flutter. See', '<p>El home se reescribió en Flutter. Ve'),
    ('<dt>Tested on</dt><dd>LG 43LM5770PUA (2019, "webOS TV Lite"), webOS 4.10.2, firmware 05.40.97. Higher-end 2019 models may ship slightly different files: the installer checks every file it patches and changes nothing if yours differ, and the patches can be regenerated.</dd>',
     '<dt>Probado en</dt><dd>LG 43LM5770PUA (2019, "webOS TV Lite"), webOS 4.10.2, firmware 05.40.97. Los modelos de gama alta de 2019 pueden traer archivos un poco distintos: el instalador revisa cada archivo que parcha y no toca nada si no coinciden, y los parches se pueden regenerar.</dd>'),
    ('<dt>Requires</dt><dd>Root (', '<dt>Requiere</dt><dd>Root ('),
    ('), SSH and a free <a href="https://www.themoviedb.org/settings/api" rel="noopener">TMDB</a> key for "For you". Check your firmware on',
     '), SSH y una llave gratis de <a href="https://www.themoviedb.org/settings/api" rel="noopener">TMDB</a> para "Para ti". Revisa tu firmware en'),

    # Preguntas
    ('<p class="kicker">FAQ</p>', '<p class="kicker">Preguntas</p>'),
    ('<h2>Good questions.</h2>', '<h2>Buenas preguntas.</h2>'),
    ('<summary>Can this brick my TV?</summary>', '<summary>¿Puede dejar inservible mi TV?</summary>'),
    ("<p>LGlow never writes to LG's read-only partitions: the new home is mounted on top of the stock one at boot. Rooting is a separate step with its own risks, so read the guide first. Use at your own risk.</p>",
     '<p>LGlow nunca escribe en las particiones de solo lectura de LG: el home nuevo se monta encima del original al arrancar. Rootear es un paso aparte con sus propios riesgos, así que lee la guía primero. Bajo tu propio riesgo.</p>'),
    ('<summary>How do I undo it?</summary>', '<summary>¿Cómo lo quito?</summary>'),
    ('<p>Run <code>./instalar.sh &lt;TV IP&gt; --quitar</code> and reboot. The stock home comes back exactly as it was.</p>',
     '<p>Corre <code>./instalar.sh &lt;IP de la TV&gt; --quitar</code> y reinicia. El home de LG regresa tal como estaba.</p>'),
    ("<summary>Why do I see LG's home for the first ~45 seconds?</summary>", '<summary>¿Por qué veo el home de LG los primeros ~45 segundos?</summary>'),
    ('<p>On webOS 4 nothing can run before root starts, about 42 seconds after a full power-on. With Quick Start+ on, the TV suspends instead of shutting down, so the new home stays between uses.</p>',
     '<p>En webOS 4 nada puede correr antes de que arranque el root, unos 42 segundos después de un encendido completo. Con Quick Start+ activado, la TV se suspende en vez de apagarse, y el home nuevo se conserva entre usos.</p>'),
    ('<summary>Is the TV interface in English?</summary>', '<summary>¿En qué idioma está la interfaz de la TV?</summary>'),
    ('<p>Not yet: the on-screen text is in Spanish and "For you" ships with Mexico\'s streaming providers. You can change the provider ids for your country in <code>config.json</code>.</p>',
     '<p>En español. "Para ti" viene con los proveedores de streaming de México; para otro país, cambia sus ids en <code>config.json</code>.</p>'),
    ("<summary>Does it include LG's code?</summary>", '<summary>¿Incluye código de LG?</summary>'),
    ('<p>No. The repo only ships patches and new components. The installer copies the stock home from your own TV and patches it there.</p>',
     '<p>No. El repo solo trae parches y componentes nuevos. El instalador copia el home original de tu propia TV y lo parcha ahí.</p>'),
    ('<summary>Is there a dark mode?</summary>', '<summary>¿Tiene modo oscuro?</summary>'),
    ("<p>Yes: light, dark or automatic (light by day, dark by night, following your city's sunrise and sunset). Pick it from the theme button at the top of the home.</p>",
     '<p>Sí: claro, oscuro o automático (claro de día y oscuro de noche, según el amanecer y el atardecer de tu ciudad). Se elige con el botón de tema de arriba del home.</p>'),
    ('<summary>Will it make apps open faster?</summary>', '<summary>¿Las apps abren más rápido?</summary>'),
    ('<p>A little. You get more free memory and less swapping, but streaming apps are heavy web apps and the TV has 674 MB of RAM.</p>',
     '<p>Un poco. Hay más memoria libre y menos swap, pero las apps de streaming son web apps pesadas y la TV tiene 674 MB de RAM.</p>'),

    # Cierre y pie
    ('<h2>Give it a <span class="glow">glow up.</span></h2>', '<h2>Dale un <span class="glow">glow up.</span></h2>'),
    ('<p>Free and open source, MIT licensed.</p>', '<p>Gratis y de código abierto, con licencia MIT.</p>'),
    ('Get LGlow on GitHub <span aria-hidden="true">→</span>', 'Descarga LGlow en GitHub <span aria-hidden="true">→</span>'),
    ('<p>Built on the work of', '<p>Hecho sobre el trabajo de'),
    ('</a> and <a href="https://github.com/simbasjungles/free-my-tv" rel="noopener">Free My TV</a>. Data from',
     '</a> y <a href="https://github.com/simbasjungles/free-my-tv" rel="noopener">Free My TV</a>. Datos de'),
    ('(not endorsed or certified by TMDB) and', '(sin respaldo ni certificación de TMDB) y'),
    ("<p>Not affiliated with LG. LG, webOS and app names and logos belong to their owners. Made by",
     '<p>Sin afiliación con LG. LG, webOS y los nombres y logos de las apps son de sus dueños. Hecho por'),
]

with open(os.path.join(RAIZ, "index.html"), encoding="utf-8") as f:
    html = f.read()

faltan = []
for en, es in T:
    if en not in html:
        faltan.append(en[:80])
        continue
    html = html.replace(en, es, -1 if en == "Guide →" else 1)

if faltan:
    print("Estos textos ya no están en site/index.html; actualiza la traducción:", file=sys.stderr)
    for t in faltan:
        print("  -", t, file=sys.stderr)
    sys.exit(1)

os.makedirs(os.path.join(RAIZ, "es"), exist_ok=True)
with open(os.path.join(RAIZ, "es", "index.html"), "w", encoding="utf-8") as f:
    f.write(html)
print("listo: site/es/index.html")
