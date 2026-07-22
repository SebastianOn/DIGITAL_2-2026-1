from migen import *
from litex.build.generic_platform import *
from litex.soc.interconnect.csr import *
import os
src_dir = os.path.dirname(os.path.abspath(__file__))

# Panel WS2812 8x8 (calculadora): un solo pin de datos.
# D1 es parte de pmodf (D1 C1 C2 E3 E2 D2 B1 A3, board/colorlight_i5.py),
# grupo que no usa ningun otro periferico -- pmodi ya lo ocupa el teclado
# por completo (D18 G5 F5 E5 D17 D16 E6 F4).
_ws2812_io = [
    ("ws2812", 0,
        Subsignal("dout", Pins("L5")),
        IOStandard("LVCMOS33"),
        Misc("DRIVE=8"),
    ),
]

N_GLYPH_FRAMES   = 12  # 0-9 digitos, 10 operador (blanco), 11 apagado
FRAME_SEL_WIDTH  = 4


class WS2812Panel(Module, AutoCSR):
    def __init__(self, platform, pads, sys_clk_freq):

        self._frame_sel = CSRStorage(FRAME_SEL_WIDTH,
            description="Indice de cuadro: 0-9=digito, 10=operador (blanco), 11=apagado")

        # ws2812_timer.v trae por defecto los tiempos afinados para la
        # Colorlight i9 standalone (25 MHz); aqui se recalculan los ciclos
        # a partir del reloj 'sys' real del SoC para no romper el protocolo.
        def ns_cycles(ns):
            return max(1, round(sys_clk_freq * ns * 1e-9))

        self.specials += Instance("ws2812_matrix8x8",
            p_HEX_FILE        = os.path.join(src_dir, "img", "calc_glyphs.hex"),
            p_N_LEDS          = 64,
            p_N_FRAMES        = N_GLYPH_FRAMES,
            p_FRAME_SEL_WIDTH = FRAME_SEL_WIDTH,
            p_CYCLES_BIT      = ns_cycles(1250),
            p_CYCLES_T0H      = ns_cycles(400),
            p_CYCLES_T1H      = ns_cycles(800),
            p_CYCLES_RESET    = ns_cycles(100_000),

            i_clk       = ClockSignal("sys"),
            i_rst_n     = ~ResetSignal("sys"),  # ws2812_matrix8x8 usa reset activo en bajo
            i_frame_sel = self._frame_sel.storage,
            o_dout      = pads.dout,
            # o_frame_done sin conectar: el timing de permanencia de cada
            # digito lo maneja el firmware con my_busy_wait, no esta senal.
        )

        for f in ["ws2812_timer.v", "ws2812_led.v", "ws2812_matrix8x8.v"]:
            platform.add_source(os.path.join(src_dir, "rtl", f))


'''
Registro CSR generado (ver build/<target>/csr.csv tras compilar):
  ws2812panel0_frame_sel  (rw)  Indice de cuadro: 0-9=digito, 10=operador, 11=apagado

Uso desde firmware:
  ws2812panel0_frame_sel_write(3);   // muestra el digito '3'
  ws2812panel0_frame_sel_write(10);  // flood blanco (operador activo)
  ws2812panel0_frame_sel_write(11);  // apagado
'''
