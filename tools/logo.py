#!/usr/bin/env python3
"""Genera el logo de LGlow ("amanecer en la pantalla") en SVG.

Las letras de "LGlow" se convierten a trazos con Inter ExtraBold (OFL), así que el SVG no depende de
la fuente. Inter no viene en el repo: bájala de github.com/google/fonts (ofl/inter) e instancia el
peso 800, o pasa la ruta de un Inter 800 estático.

Uso: python3 tools/logo.py /ruta/a/inter-800.ttf
Salida: docs/img/marca/*.svg y site/favicon.svg. Los PNG se exportan aparte (ver CLAUDE.md).
"""
import os
import sys

from fontTools.pens.svgPathPen import SVGPathPen
from fontTools.pens.transformPen import TransformPen
from fontTools.ttLib import TTFont

RAIZ = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
MARCA = os.path.join(RAIZ, "docs", "img", "marca")
INK, INK_OSCURO, FONDO_APP = "#16161d", "#f3f3f7", "#101016"


def texto(fuente, s, size, track=-0.035):
    """Path SVG de la palabra (línea base en y=0) y su ancho."""
    f = TTFont(fuente)
    gs, cmap, upm = f.getGlyphSet(), f.getBestCmap(), f["head"].unitsPerEm
    k = size / upm
    pen = SVGPathPen(gs)
    cur = 0
    for ch in s:
        g = gs[cmap[ord(ch)]]
        g.draw(TransformPen(pen, (k, 0, 0, -k, cur * k, 0)))
        cur += g.width + track * upm
    return pen.getCommands(), (cur - track * upm) * k


def marca(borde):
    """La TV oscura con el sol que sale desde abajo (viewBox 512). `borde` la separa de fondos oscuros."""
    trazo = ' stroke="#ffffff" stroke-opacity=".16" stroke-width="6"' if borde else ""
    pantalla = "#1d1d27" if borde else INK
    return f'''<defs>
<radialGradient id="lglow-sol" cx=".5" cy=".5" r=".5"><stop offset="0" stop-color="#fff4e2"/><stop offset=".38" stop-color="#ffb35c"/><stop offset=".72" stop-color="#ff4f8b"/><stop offset="1" stop-color="#8b5cf6" stop-opacity="0"/></radialGradient>
<radialGradient id="lglow-halo" cx=".5" cy=".5" r=".5"><stop offset="0" stop-color="#ff4f8b" stop-opacity=".75"/><stop offset="1" stop-color="#8b5cf6" stop-opacity="0"/></radialGradient>
<linearGradient id="lglow-pie" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#ff9a3d"/><stop offset=".5" stop-color="#ff4f8b"/><stop offset="1" stop-color="#8b5cf6"/></linearGradient>
<clipPath id="lglow-pantalla"><rect x="56" y="92" width="400" height="276" rx="46"/></clipPath>
</defs>
<rect x="56" y="92" width="400" height="276" rx="46" fill="{pantalla}"{trazo}/>
<g clip-path="url(#lglow-pantalla)"><circle cx="256" cy="372" r="230" fill="url(#lglow-halo)"/><circle cx="256" cy="372" r="150" fill="url(#lglow-sol)"/></g>
<rect x="196" y="398" width="120" height="20" rx="10" fill="url(#lglow-pie)"/>'''


def svg(w, h, cuerpo, titulo="LGlow"):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {w} {h}" role="img" aria-label="{titulo}">'
            f'<title>{titulo}</title>{cuerpo}</svg>\n')


def guardar(ruta, contenido):
    with open(ruta, "w") as f:
        f.write(contenido)
    print("listo:", os.path.relpath(ruta, RAIZ))


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    os.makedirs(MARCA, exist_ok=True)
    d, w = texto(sys.argv[1], "LGlow", 300)

    guardar(os.path.join(MARCA, "lglow-icono.svg"), svg(512, 512, marca(False)))
    guardar(os.path.join(MARCA, "lglow-icono-oscuro.svg"), svg(512, 512, marca(True)))
    # Horizontal: la marca a la izquierda y la palabra alineada con la pantalla
    ancho = round(512 + 40 + w + 24)
    for sufijo, borde, tinta in (("", False, INK), ("-oscuro", True, INK_OSCURO)):
        guardar(os.path.join(MARCA, f"lglow-logo{sufijo}.svg"),
                svg(ancho, 512, marca(borde) + f'<path transform="translate(552 340)" d="{d}" fill="{tinta}"/>'))
    # Ícono de app (avatar, apple-touch-icon): fondo oscuro cuadrado y redondeado
    guardar(os.path.join(MARCA, "lglow-app.svg"),
            svg(512, 512, f'<rect width="512" height="512" rx="112" fill="{FONDO_APP}"/>'
                          f'<g transform="translate(46 40) scale(.82)">{marca(True)}</g>'))
    # Favicon: la marca con borde, para que se vea en pestañas claras y oscuras
    guardar(os.path.join(RAIZ, "site", "favicon.svg"), svg(512, 512, marca(True)))


if __name__ == "__main__":
    main()
