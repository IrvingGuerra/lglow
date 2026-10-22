#!/usr/bin/env python3
"""Genera los parches de tv/patches/<app> comparando el QML original de una TV con una
copia modificada. Útil para portar el proyecto a otro firmware.

Uso:  python3 tools/regenerar-parches.py <original> <mod> <carpeta-de-parches>
      (<original> y <mod> contienen cada uno una carpeta qml/)

- Archivos que cambian → un .patch (diff -u) por archivo, más su md5 original en
  originales.md5 (el instalador lo usa para verificar el firmware).
- Archivos que solo existen en <mod> se ignoran aquí: los componentes nuevos viven en
  tv/qml/ y el instalador los copia aparte.
"""
import hashlib
import os
import subprocess
import sys

if len(sys.argv) != 4:
    sys.exit(__doc__)
orig, mod, out = sys.argv[1:]
os.makedirs(out, exist_ok=True)
for f in os.listdir(out):
    if f.endswith(".patch"):
        os.remove(os.path.join(out, f))

listing = subprocess.run(["diff", "-rq", os.path.join(orig, "qml"), os.path.join(mod, "qml")],
                         capture_output=True, text=True).stdout
changed = []
for line in listing.splitlines():
    if line.startswith("Files "):
        changed.append(line.split(" ")[1][len(orig) + 1:])

sums = []
for rel in sorted(changed):
    diff = subprocess.run(["diff", "-u", "--label", "a/" + rel, "--label", "b/" + rel,
                           os.path.join(orig, rel), os.path.join(mod, rel)],
                          capture_output=True, text=True).stdout
    name = rel.replace("qml/", "", 1).replace("/", "__").rsplit(".", 1)[0] + ".patch"
    with open(os.path.join(out, name), "w") as fh:
        fh.write(diff)
    with open(os.path.join(orig, rel), "rb") as fh:
        sums.append(hashlib.md5(fh.read()).hexdigest() + "  " + rel)
    print("  " + name)

with open(os.path.join(out, "originales.md5"), "w") as fh:
    fh.write("\n".join(sums) + "\n")
print(f"{len(changed)} parches en {out}")
