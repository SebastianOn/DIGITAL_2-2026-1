from migen import *
from litex.build.generic_platform import *
from litex.soc.interconnect.csr import *
import os
src_dir = os.path.dirname(os.path.abspath(__file__))

# Teclado matricial 4x4: R0-R3 filas (salidas), C0-C3 columnas (entradas).
# Pull-down en las columnas porque quedan en 0 mientras ninguna fila activa
# esta conectada a traves de una tecla presionada.
#
# El grupo de 8 pines fisicos (E5 F4 F5 E6 G5 D18 D16 D17) resulto tener
# filas y columnas intercambiadas (y reordenadas) respecto al teclado real:
# se determino empiricamente presionando teclas conocidas y viendo que
# codigo devolvia keypad0_tecla. Filas reales (linea comun de 1/2/3,
# 4/5/6, 7/8/9, */0/#//) -> G5 D16 D18 D17. Columnas reales (linea comun
# de 1/4/7/*, 2/5/8/0, 3/6/9/#, columna sin decodificar) -> F4 E6 E5 F5.
_keypad_io = [
    ("keypad", 0,
        Subsignal("r0", Pins("G5")),
        Subsignal("r1", Pins("D16")),
        Subsignal("r2", Pins("D18")),
        Subsignal("r3", Pins("D17")),
        Subsignal("c0", Pins("F4"), Misc("PULLMODE=DOWN")),
        Subsignal("c1", Pins("E6"), Misc("PULLMODE=DOWN")),
        Subsignal("c2", Pins("E5"), Misc("PULLMODE=DOWN")),
        Subsignal("c3", Pins("F5"), Misc("PULLMODE=DOWN")),
        IOStandard("LVCMOS33"),
    ),
]

class Keypad4x4(Module, AutoCSR):
    def __init__(self, platform, pads):

        self._init  = CSRStorage(1, description="Pulso de inicio de escaneo (escribir 1 y luego 0)")
        self._tecla = CSRStatus(6, description="Codigo ASCII de la ultima tecla leida")
        self._done  = CSRStatus(1, description="0 mientras escanea, 1 cuando la tecla quedo capturada")

        self.specials += Instance("Teclado",
            i_clk   = ClockSignal("sys"),
            i_reset = ResetSignal("sys"),
            i_init  = self._init.storage,
            i_C0    = pads.c0,
            i_C1    = pads.c1,
            i_C2    = pads.c2,
            i_C3    = pads.c3,
            o_R0    = pads.r0,
            o_R1    = pads.r1,
            o_R2    = pads.r2,
            o_R3    = pads.r3,
            o_tecla = self._tecla.status,
            o_done  = self._done.status,
        )

        platform.add_source(os.path.join(src_dir, "Teclado.v"))


'''
Registros CSR generados (ver build/<target>/csr.csv tras compilar):
  keypad0_init    (rw)  Pulso de inicio de escaneo (escribir 1 y luego 0)
  keypad0_tecla   (ro)  Codigo ASCII de la ultima tecla leida
  keypad0_done    (ro)  0 mientras escanea, 1 cuando la tecla quedo capturada

Uso desde firmware (bare polling, igual que mult0/div0):
  keypad0_init_write(1);
  keypad0_init_write(0);
  while (keypad0_done_read());   // espera a que salga del estado START (empieza a escanear)
  while (!keypad0_done_read());  // espera a que la tecla quede capturada
  char c = (char) keypad0_tecla_read();
'''
