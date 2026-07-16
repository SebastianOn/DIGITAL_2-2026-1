from migen import *
from litex.soc.interconnect.csr import *
import os
src_dir = os.path.dirname(os.path.abspath(__file__))

class Div32(Module, AutoCSR):
    def __init__(self, platform):

        self._A    = CSRStorage(16, description="Dividendo A (16 bits)")
        self._B    = CSRStorage(16, description="Divisor B (16 bits)")
        self._init = CSRStorage( 1, description="Pulso de inicio")

        self._quotient  = CSRStatus(16, description="Cociente A/B (16 bits)")
        self._remainder = CSRStatus(16, description="Residuo A%B (16 bits)")
        self._done       = CSRStatus( 1, description="1 cuando terminó")
        self._error       = CSRStatus( 1, description="1 si B=0 (división por cero)")

        self.specials += Instance("div_32",
            i_clk       = ClockSignal("sys"),
            i_rst       = ResetSignal("sys"),
            i_init      = self._init.storage,
            i_A         = self._A.storage,
            i_B         = self._B.storage,
            o_quotient  = self._quotient.status,
            o_remainder = self._remainder.status,
            o_done      = self._done.status,
            o_error     = self._error.status,
        )

        for src in ["comp_div0.v", "sub_div.v", "count_div.v", "reg_aq.v", "control_div.v", "div_32.v"]:
            platform.add_source(os.path.join(src_dir, src))


'''
Registros CSR generados (ver build/<target>/csr.csv tras compilar):
  div0__A         (rw)  Dividendo A
  div0__B         (rw)  Divisor B
  div0_init       (rw)  Pulso de inicio (escribir 1 y luego 0)
  div0_quotient   (ro)  Cociente A/B
  div0_remainder  (ro)  Residuo A%B
  div0_done       (ro)  1 cuando terminó
  div0_error      (ro)  1 si B=0 (división por cero)
'''
