#!/usr/bin/env python3
"""Genera la pantalla de carga de LGlow para cada app y la sube a la TV.

Algunas apps (Netflix, Prime Video, YouTube…) traen como pantalla de carga la imagen gris genérica
de LG (la de los cubos). Este script compone, para cada app que ya tiene tile (tools/make-tiles.py),
una pantalla de carga con fondo oscuro, el brillo de LGlow y el tile de la app al centro, y la sube a
/var/lib/webosbrew/fullhomecustom/splash/<appId>.png. Al encender, tv/splash-apps.sh la monta encima
del original **solo** si el de la app es uno de los genéricos de LG; las que traen su propia pantalla
con su marca (ViX, Disney+, Max…) se quedan con la suya.

Uso:  python3 tools/make-splash.py <ip-de-la-tv>     (después de make-tiles.py)
Requiere: Python 3 con Pillow y SSH root a la TV.
"""
import os
import subprocess
import sys
import tempfile

from PIL import Image, ImageDraw, ImageFilter

if len(sys.argv) < 2:
    sys.exit("Uso: python3 tools/make-splash.py <ip-de-la-tv>")
HOST = sys.argv[1] if "@" in sys.argv[1] else "root@" + sys.argv[1]
TILES = "/var/lib/webosbrew/fullhomecustom/tiles"
DESTINO = "/var/lib/webosbrew/fullhomecustom/splash"
W, H = 1280, 720                 # el tamaño de los splash de las apps
FONDO = (16, 16, 22)
TILE_W = 384                     # el tile de 300x180 escalado al centro


def fondo():
    """Fondo oscuro con un amanecer suave abajo, como el logo."""
    img = Image.new("RGB", (W, H), FONDO)
    luz = Image.new("RGB", (W, H), FONDO)
    d = ImageDraw.Draw(luz)
    for r, c in [(520, (139, 92, 246)), (380, (255, 79, 139)), (240, (255, 154, 61))]:
        d.ellipse((W // 2 - r, H + 120 - r, W // 2 + r, H + 120 + r), fill=c)
    return Image.blend(img, luz.filter(ImageFilter.GaussianBlur(140)), 0.45)


def splash(tile):
    img = fondo().convert("RGBA")
    t = tile.convert("RGBA").resize((TILE_W, round(TILE_W * tile.height / tile.width)), Image.LANCZOS)
    x, y = (W - t.width) // 2, (H - t.height) // 2 - 30
    sombra = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(sombra).rounded_rectangle((x, y + 18, x + t.width, y + t.height + 18), 34, fill=(0, 0, 0, 150))
    img = Image.alpha_composite(img, sombra.filter(ImageFilter.GaussianBlur(26)))
    img.paste(t, (x, y), t)
    # Tres puntos de "cargando"
    d = ImageDraw.Draw(img)
    cy = y + t.height + 70
    for i, a in enumerate((230, 150, 90)):
        cx = W // 2 + (i - 1) * 28
        d.ellipse((cx - 6, cy - 6, cx + 6, cy + 6), fill=(255, 255, 255, a))
    return img.convert("RGB")


def main():
    lista = subprocess.run(["ssh", HOST, f"ls {TILES}"], capture_output=True, text=True, check=True).stdout.split()
    with tempfile.TemporaryDirectory() as tmp:
        hechos = []
        for nombre in lista:
            if not nombre.endswith(".png"):
                continue
            local = os.path.join(tmp, "tile-" + nombre)
            if subprocess.run(["scp", "-q", f"{HOST}:{TILES}/{nombre}", local]).returncode != 0:
                continue
            salida = os.path.join(tmp, nombre)
            splash(Image.open(local)).save(salida, optimize=True)
            hechos.append(salida)
            print("listo:", nombre[:-4])
        if not hechos:
            sys.exit("No hay tiles en la TV: corre antes tools/make-tiles.py")
        subprocess.run(["ssh", HOST, f"mkdir -p {DESTINO}"], check=True)
        subprocess.run(["scp", "-q"] + hechos + [f"{HOST}:{DESTINO}/"], check=True)
    # Montar ya los que aplican; el compositor las lee después de reiniciarse
    subprocess.run(["ssh", HOST, "sh /var/lib/webosbrew/tools/splash-apps.sh && "
                    "sh /var/lib/webosbrew/tools/compositor.sh --ahora"], check=True)
    print("Subidos a", DESTINO, "y aplicados (la pantalla parpadea un momento).")


if __name__ == "__main__":
    main()
