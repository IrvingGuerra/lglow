#!/usr/bin/env python3
"""Genera tiles rectangulares (5:3, estilo Free My TV) para el home de una LG webOS.

Lee la lista de apps de la TV, baja el ícono grande de cada una (o, si la app trae el
mismo logo más grande, ese), detecta el color de marca en el borde del ícono y compone
un tile con el logo centrado sobre ese color y esquinas redondeadas. Los PNG quedan en
tools/tiles/<appId>.png y se suben a /var/lib/webosbrew/fullhomecustom/tiles/ en la TV.

Uso:  python3 tools/make-tiles.py <ip-de-la-tv>     (o un alias de ~/.ssh/config)
Requiere: Python 3 con Pillow (pip install pillow) y SSH root a la TV.
Vuelve a correrlo cada vez que instales una app nueva.
"""
import json
import os
import shutil
import subprocess
import sys
import tempfile
from collections import Counter

from PIL import Image, ImageChops, ImageDraw, ImageStat

if len(sys.argv) < 2:
    sys.exit("Uso: python3 tools/make-tiles.py <ip-de-la-tv>")
HOST = sys.argv[1] if "@" in sys.argv[1] else "root@" + sys.argv[1]
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "tiles")
# 5:3. El home lo decodifica a 300x180 (sourceSize) y lo dibuja más chico; el tamaño
# completo es para la pantalla de carga (make-splash.py), que lo pone tal cual en 1080p
W, H = 450, 270
RADIUS = 40              # proporcional al radio del tile en el QML
LOGO_SCALE = 0.92        # alto del ícono respecto al alto del tile
MISMO_LOGO = 3           # diferencia máxima (0-255) entre miniaturas para tomarlo como el mismo logo


def ssh(cmd):
    # luna-send no imprime nada si no tiene una terminal: forzamos TTY con -tt
    out = subprocess.run(["ssh", "-tt", HOST, cmd], capture_output=True, text=True, check=True).stdout
    return out.replace("\r", "")


def launch_points():
    out = ssh("luna-send -n 1 luna://com.webos.applicationManager/listLaunchPoints '{}'")
    return json.loads(out)["launchPoints"]


def edge_color(img):
    """Color más frecuente en el borde del ícono (ignorando transparencias)."""
    px = img.load()
    w, h = img.size
    edge = []
    for x in range(w):
        edge += [px[x, 0], px[x, h - 1]]
    for y in range(h):
        edge += [px[0, y], px[w - 1, y]]
    opaque = [p[:3] for p in edge if p[3] > 200]
    if len(opaque) < len(edge) * 0.5:
        return None   # ícono con fondo transparente: usar el color declarado por la app
    # Vota con colores cuantizados (para que el antialias no gane) y devuelve el
    # promedio exacto de ese grupo: un #fcfcfc en vez de #ffffff se nota como costura
    key = lambda p: (p[0] // 8, p[1] // 8, p[2] // 8)
    best = Counter(key(p) for p in opaque).most_common(1)[0][0]
    group = [p for p in opaque if key(p) == best]
    if len(group) < len(edge) * 0.6:
        return None   # borde no uniforme (degradado, esquinas redondeadas): no hay un solo color
    return tuple(round(sum(c[i] for c in group) / len(group)) for i in range(3))


def side_gradient(img):
    """Para íconos con esquinas transparentes: colores dentro del ícono a izquierda y derecha."""
    w, h = img.size
    alpha = img.getchannel("A").getdata()
    if sum(1 for a in alpha if a > 200) < w * h * 0.5:
        return None   # logo suelto sin fondo (AmazOff): lo de los lados son sus letras
    px = img.load()
    left, right = px[int(w * 0.15), h // 2], px[int(w * 0.85), h // 2]
    if left[3] < 200 or right[3] < 200:
        return None
    return left[:3], right[:3]


def app_dir(src):
    """Carpeta de la app a partir de la ruta de su ícono."""
    head, sep, tail = src.partition("/applications/")
    return head + sep + tail.split("/")[0] if sep else os.path.dirname(src)


def thumb(img):
    """Miniatura sobre gris, para comparar logos sin que estorbe la transparencia."""
    bg = Image.new("RGBA", img.size, (128, 128, 128, 255))
    bg.alpha_composite(img)
    return bg.convert("RGB").resize((32, 32), Image.LANCZOS)


def sharpest_icon(icon, src, tmp):
    """El ícono que declaran Netflix, YouTube, ViX, Disney+… mide 80 px y en el tile se ve
    pixeleado, pero las apps de la tienda traen el mismo logo en 115 y 192 px. Busca en la
    carpeta de la app (y un nivel abajo) imágenes cuadradas más grandes que sean el mismo
    logo y devuelve la mayor."""
    local = os.path.join(tmp, "app")
    shutil.rmtree(local, ignore_errors=True)
    os.makedirs(local)
    tar = subprocess.run(["ssh", HOST, f"cd '{app_dir(src)}' && "
                          "find . -maxdepth 2 -iname '*.png' -size -60k | tar cf - -T -"],
                         capture_output=True).stdout
    subprocess.run(["tar", "xf", "-", "-C", local], input=tar, capture_output=True)
    base, best = thumb(icon), icon
    for root, _, files in os.walk(local):
        for f in files:
            try:
                img = Image.open(os.path.join(root, f)).convert("RGBA")
            except OSError:
                continue
            if img.width != img.height or img.width <= best.width:
                continue
            if sum(ImageStat.Stat(ImageChops.difference(base, thumb(img))).mean) / 3 < MISMO_LOGO:
                best = img
    return best


def hex_to_rgb(s):
    s = (s or "").lstrip("#")
    return tuple(int(s[i:i + 2], 16) for i in (0, 2, 4)) if len(s) == 6 else None


def make_tile(icon, color, gradient=None):
    tile = Image.new("RGBA", (W, H), color + (255,))
    if gradient:
        (r1, g1, b1), (r2, g2, b2) = gradient
        draw = ImageDraw.Draw(tile)
        for x in range(W):
            t = x / (W - 1)
            draw.line([(x, 0), (x, H)], fill=(round(r1 + (r2 - r1) * t),
                                              round(g1 + (g2 - g1) * t),
                                              round(b1 + (b2 - b1) * t), 255))
    side = int(H * LOGO_SCALE)
    logo = icon.resize((side, side), Image.LANCZOS)
    tile.alpha_composite(logo, ((W - side) // 2, (H - side) // 2))
    mask = Image.new("L", (W, H), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, W - 1, H - 1), RADIUS, fill=255)
    tile.putalpha(mask)
    return tile


def main():
    os.makedirs(OUT, exist_ok=True)
    with tempfile.TemporaryDirectory() as tmp:
        for lp in launch_points():
            src = lp.get("largeIcon") or lp.get("mediumLargeIcon") or lp.get("icon")
            if not src:
                continue
            local = os.path.join(tmp, "icon.png")
            if subprocess.run(["scp", "-q", f"{HOST}:{src}", local]).returncode != 0:
                print(f"  sin ícono: {lp['id']}")
                continue
            icon = Image.open(local).convert("RGBA")
            small = icon.width
            icon = sharpest_icon(icon, src, tmp)
            color = edge_color(icon)
            gradient = None if color else side_gradient(icon)
            color = color or hex_to_rgb(lp.get("bgColor")) \
                or hex_to_rgb(lp.get("iconColor")) or (40, 40, 44)
            make_tile(icon, color, gradient).save(os.path.join(OUT, lp["id"] + ".png"), optimize=True)
            size = f"{small} → {icon.width} px" if icon.width > small else f"{small} px"
            print(f"  {lp['id']:32s} #{color[0]:02x}{color[1]:02x}{color[2]:02x}  {size}")
    print("Subiendo a la TV…")
    subprocess.run(["ssh", HOST, "mkdir -p /var/lib/webosbrew/fullhomecustom/tiles"], check=True)
    pngs = [os.path.join(OUT, f) for f in os.listdir(OUT) if f.endswith(".png")]
    subprocess.run(["scp", "-q"] + pngs + [f"{HOST}:/var/lib/webosbrew/fullhomecustom/tiles/"], check=True)
    print(f"Listo: {len(pngs)} tiles. Presiona Home dos veces (o reinicia) para verlos.")


if __name__ == "__main__":
    main()
