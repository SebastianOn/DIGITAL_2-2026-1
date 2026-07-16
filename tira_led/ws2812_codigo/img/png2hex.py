#!/usr/bin/env python3
"""
png2hex.py - Convierte una imagen 8x8 (PNG/JPG) a image.hex (formato GRB).

Uso:
    python3 png2hex.py imagen.png [salida.hex] [--serpentine]

--serpentine : para matrices cableadas en zig-zag (filas impares invertidas).
"""
import sys
from PIL import Image

def main():
    args = [a for a in sys.argv[1:] if not a.startswith("--")]
    serp = "--serpentine" in sys.argv
    src  = args[0]
    dst  = args[1] if len(args) > 1 else "image.hex"

    img = Image.open(src).convert("RGB").resize((8, 8))
    lines = []
    for y in range(8):
        xs = range(7, -1, -1) if (serp and y % 2 == 1) else range(8)
        for x in xs:
            r, g, b = img.getpixel((x, y))
            lines.append(f"{g:02x}{r:02x}{b:02x}")   # GRB
    with open(dst, "w") as f:
        f.write("\n".join(lines) + "\n")
    print(f"{dst}: 64 pixeles escritos (GRB{' serpentine' if serp else ''})")

if __name__ == "__main__":
    main()
