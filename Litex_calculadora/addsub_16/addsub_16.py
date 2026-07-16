from migen import *
from litex.soc.interconnect.csr import *
import os
src_dir = os.path.dirname(os.path.abspath(__file__))

class AddSub16(Module, AutoCSR):
    def __init__(self, platform):

        self._A    = CSRStorage(16, description="Operando A (16 bits)")
        self._B    = CSRStorage(16, description="Operando B (16 bits)")
        self._sub  = CSRStorage( 1, description="0 = A+B, 1 = A-B (complemento a 2)")
        self._init = CSRStorage( 1, description="Pulso de inicio")

        self._result   = CSRStatus(16, description="Resultado A+B o A-B (16 bits)")
        self._carry    = CSRStatus( 1, description="Suma: acarreo de salida. Resta: 1 si NO hubo préstamo (A>=B)")
        self._overflow = CSRStatus( 1, description="1 si hubo overflow con signo (complemento a 2)")
        self._done     = CSRStatus( 1, description="1 cuando terminó")

        self.specials += Instance("addsub_16",
            i_clk      = ClockSignal("sys"),
            i_rst      = ResetSignal("sys"),
            i_init     = self._init.storage,
            i_A        = self._A.storage,
            i_B        = self._B.storage,
            i_sub      = self._sub.storage,
            o_result   = self._result.status,
            o_carry    = self._carry.status,
            o_overflow = self._overflow.status,
            o_done     = self._done.status,
        )

        for src in ["fa_addsub.v", "sra_addsub.v", "srb_addsub.v", "carry_addsub.v",
                    "ov_addsub.v", "res_addsub.v", "count_addsub.v", "control_addsub.v",
                    "addsub_16.v"]:
            platform.add_source(os.path.join(src_dir, src))


'''
Registros CSR generados (ver build/<target>/csr.csv tras compilar):
  addsub0__A        (rw)  Operando A
  addsub0__B        (rw)  Operando B
  addsub0_sub       (rw)  0 = suma, 1 = resta
  addsub0_init      (rw)  Pulso de inicio (escribir 1 y luego 0)
  addsub0_result    (ro)  Resultado A+B o A-B
  addsub0_carry     (ro)  Acarreo (suma) / no-préstamo (resta)
  addsub0_overflow  (ro)  1 si hubo overflow con signo
  addsub0_done      (ro)  1 cuando terminó
'''
