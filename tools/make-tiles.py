#!/usr/bin/env python3
"""Genera tiles rectangulares (5:3, estilo Free My TV) para el home de una LG webOS.

Lee la lista de apps de la TV, baja el ícono grande de cada una, detecta el color
de marca en el borde del ícono y compone un tile con el logo centrado sobre ese
color y esquinas redondeadas. Los PNG quedan en tools/tiles/<appId>.png y se suben a
/var/lib/webosbrew/fullhomecustom/tiles/ en la TV.

Uso:  python3 tools/make-tiles.py <ip-de-la-tv>     (o un alias de ~/.ssh/config)
Requiere: Python 3 con Pillow (pip install pillow) y SSH root a la TV.
Vuelve a correrlo cada vez que instales una app nueva.
"""
import json
import os
import subprocess
import sys
import tempfile
from collections import Counter

from PIL import Image, ImageDraw

if len(sys.argv) < 2:
    sys.exit("Uso: python3 tools/make-tiles.py <ip-de-la-tv>")
HOST = sys.argv[1] if "@" in sys.argv[1] else "root@" + sys.argv[1]
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "tiles")
W, H = 300, 180          # 5:3; en pantalla se dibuja a 200x120 (240x144 con foco)
RADIUS = 27              # proporcional al radio del tile en el QML
LOGO_SCALE = 0.92        # alto del ícono respecto al alto del tile


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
    px = img.load()
    left, right = px[int(w * 0.15), h // 2], px[int(w * 0.85), h // 2]
    if left[3] < 200 or right[3] < 200:
        return None
    return left[:3], right[:3]


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
            color = edge_color(icon)
            gradient = None if color else side_gradient(icon)
            color = color or hex_to_rgb(lp.get("bgColor")) \
                or hex_to_rgb(lp.get("iconColor")) or (40, 40, 44)
            make_tile(icon, color, gradient).save(os.path.join(OUT, lp["id"] + ".png"), optimize=True)
            print(f"  {lp['id']:32s} #{color[0]:02x}{color[1]:02x}{color[2]:02x}")
    print("Subiendo a la TV…")
    subprocess.run(["ssh", HOST, "mkdir -p /var/lib/webosbrew/fullhomecustom/tiles"], check=True)
    pngs = [os.path.join(OUT, f) for f in os.listdir(OUT) if f.endswith(".png")]
    subprocess.run(["scp", "-q"] + pngs + [f"{HOST}:/var/lib/webosbrew/fullhomecustom/tiles/"], check=True)
    print(f"Listo: {len(pngs)} tiles. Presiona Home dos veces (o reinicia) para verlos.")


if __name__ == "__main__":
    main()
