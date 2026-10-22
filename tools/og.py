#!/usr/bin/env python3
"""Genera las imágenes para compartir de la web: site/og.jpg (inglés) y site/og-es.jpg (español).

Uso: python3 tools/og.py   (necesita Pillow y la fuente Helvetica Neue de macOS)
"""
import os
from PIL import Image, ImageDraw, ImageFont, ImageFilter

RAIZ = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..")
FUENTE = "/System/Library/Fonts/HelveticaNeue.ttc"
TEXTOS = {
    "og.jpg": ("Your old LG TV", "needs a glow up.", "Ad-free home for webOS 4.5", "Open source · one command to undo"),
    "og-es.jpg": ("¿Tu vieja LG", "necesita un glow up?", "Home sin publicidad para webOS 4.5", "Código abierto · se quita con un comando"),
}


def fuente(tam, i):
    return ImageFont.truetype(FUENTE, tam, index=i)


def generar(nombre, l1, l2, l3, l4):
    W, H = 1200, 630
    fondo = Image.new("RGB", (W, H), (244, 245, 248))
    luz = Image.new("RGB", (W, H), (244, 245, 248))
    d = ImageDraw.Draw(luz)
    for x, y, r, c in [(150, 80, 260, (255, 179, 122)), (1050, 180, 260, (255, 143, 191)), (700, 600, 300, (185, 162, 255))]:
        d.ellipse((x - r, y - r, x + r, y + r), fill=c)
    fondo = Image.blend(fondo, luz.filter(ImageFilter.GaussianBlur(120)), 0.6)

    d = ImageDraw.Draw(fondo)
    d.text((70, 140), "LGlow", font=fuente(120, 1), fill=(22, 22, 29))
    d.text((74, 290), l1, font=fuente(46, 0), fill=(58, 58, 68))
    d.text((74, 346), l2, font=fuente(46, 0), fill=(58, 58, 68))
    d.text((74, 450), l3, font=fuente(26, 0), fill=(107, 107, 120))
    d.text((74, 486), l4, font=fuente(26, 0), fill=(107, 107, 120))

    # La captura del home dentro de un marco de TV, con un brillo rosa detrás
    captura = Image.open(os.path.join(RAIZ, "docs/img/despues-home.jpg")).convert("RGB").resize((560, 315), Image.LANCZOS)
    marco = Image.new("RGB", (580, 335), (17, 17, 22))
    marco.paste(captura, (10, 10))
    brillo = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(brillo).rounded_rectangle((590, 160, 1170, 495), 24, fill=(255, 79, 139, 150))
    fondo = Image.alpha_composite(fondo.convert("RGBA"), brillo.filter(ImageFilter.GaussianBlur(40))).convert("RGB")
    mascara = Image.new("L", marco.size, 0)
    ImageDraw.Draw(mascara).rounded_rectangle((0, 0, 579, 334), 18, fill=255)
    fondo.paste(marco, (590, 150), mascara)
    fondo.save(os.path.join(RAIZ, "site", nombre), quality=86)
    print("listo: site/" + nombre)


for nombre, textos in TEXTOS.items():
    generar(nombre, *textos)
