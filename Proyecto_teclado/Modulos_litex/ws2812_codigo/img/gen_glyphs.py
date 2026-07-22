#!/usr/bin/env python3
"""
gen_glyphs.py — Genera calc_glyphs.hex: 12 cuadros de 64 pixeles GRB
(uno por LED, formato $readmemh) para la calculadora en el panel 8x8:

    cuadros 0-9  : digitos '0'-'9' (fuente de bloques hecha a mano)
    cuadro  10   : blanco pleno (64x "ffffff") -- operador activo (*, /, #)
    cuadro  11   : apagado (64x "000000")      -- estado inicial / parpadeo
                    entre digitos al mostrar el resultado

Mismo cableado en serpentin que ws2812/images/ws2812_convert_8x8.py:
    fila par  (0,2,4,6): LED avanza izquierda->derecha (col 0..7)
    fila impar(1,3,5,7): LED avanza derecha->izquierda (col 7..0)
    indice_led = fila*8 + posicion_dentro_de_la_fila

Si el panel real esta cableado distinto, basta con invertir la logica
de 'pixel_for_led' abajo y volver a correr este script -- no hace falta
tocar el RTL, el .hex se recarga en la siguiente sintesis.
"""
from pathlib import Path

COLS = ROWS = 8
N_LEDS = COLS * ROWS  # 64

DIGIT_COLOR_RGB = (255, 0, 0)  # rojo; cambiar aqui para otro color de acento
OFF_RGB         = (0, 0, 0)

# Fuente de bloques 8x8 a mano, una fila de 8 caracteres '0'/'1' por linea
# (fila 0 = arriba). '1' = pixel encendido.
FONT = {
    0: ["01111110", "01100110", "01100110", "01100110",
        "01100110", "01100110", "01100110", "01111110"],
    1: ["00011000", "00111000", "01111000", "00011000",
        "00011000", "00011000", "00011000", "01111110"],
    2: ["01111110", "11000011", "00000011", "00000110",
        "00011000", "01100000", "11000000", "11111111"],
    3: ["01111110", "11000011", "00000011", "00111110",
        "00000011", "00000011", "11000011", "01111110"],
    4: ["00000110", "00001110", "00011110", "00110110",
        "01100110", "11111111", "00000110", "00000110"],
    5: ["11111111", "11000000", "11000000", "11111110",
        "00000011", "00000011", "11000011", "01111110"],
    6: ["00111110", "01100000", "11000000", "11111110",
        "11000011", "11000011", "11000011", "01111110"],
    7: ["11111111", "00000011", "00000110", "00001100",
        "00011000", "00110000", "00110000", "00110000"],
    8: ["01111110", "11000011", "11000011", "01111110",
        "11000011", "11000011", "11000011", "01111110"],
    9: ["01111110", "11000011", "11000011", "01111111",
        "00000011", "00000011", "00000110", "01111100"],
}

FRAME_OPERATOR = 10
FRAME_BLANK    = 11
N_FRAMES       = 12


def pixel_for_led(led_idx: int):
    row = led_idx // COLS
    pos = led_idx % COLS
    col = pos if row % 2 == 0 else (COLS - 1 - pos)
    return row, col


def grb_hex(rgb) -> str:
    r, g, b = rgb
    return f"{g:02x}{r:02x}{b:02x}"


def frame_from_bitmap(bitmap_rows, on_rgb, off_rgb=OFF_RGB):
    assert len(bitmap_rows) == ROWS
    for r in bitmap_rows:
        assert len(r) == COLS, f"fila con {len(r)} caracteres, se esperaban {COLS}"
    lines = []
    for led_idx in range(N_LEDS):
        row, col = pixel_for_led(led_idx)
        bit = bitmap_rows[row][col]
        lines.append(grb_hex(on_rgb if bit == "1" else off_rgb))
    return lines


def frame_flood(rgb):
    return [grb_hex(rgb)] * N_LEDS


def build_frames():
    frames = []
    for d in range(10):
        frames.append(frame_from_bitmap(FONT[d], DIGIT_COLOR_RGB))
    frames.append(frame_flood((255, 255, 255)))  # FRAME_OPERATOR
    frames.append(frame_flood((0, 0, 0)))         # FRAME_BLANK
    assert len(frames) == N_FRAMES
    return frames


FRAME_NAMES = [str(d) for d in range(10)] + ["operator", "blank"]


def main():
    frames = build_frames()
    all_lines = [line for frame in frames for line in frame]
    assert len(all_lines) == N_FRAMES * N_LEDS

    out_dir = Path(__file__).parent
    out_path = out_dir / "calc_glyphs.hex"
    out_path.write_text("\n".join(all_lines) + "\n", encoding="utf-8")
    print(f"{out_path}: {len(all_lines)} lineas ({N_FRAMES} cuadros x {N_LEDS} leds)")

    # Un .hex individual (64 lineas, N_FRAMES=1) por cada glifo, para poder
    # probarlos uno por uno con el flujo standalone (rtl/top.v + Makefile,
    # el mismo que ya se confirmo funcionando en hardware real), sin pasar
    # por el SoC LiteX ni el firmware.
    for name, frame in zip(FRAME_NAMES, frames):
        digit_path = out_dir / f"digit_{name}.hex"
        digit_path.write_text("\n".join(frame) + "\n", encoding="utf-8")
        print(f"{digit_path}: {len(frame)} lineas (1 cuadro x {N_LEDS} leds)")


if __name__ == "__main__":
    main()
