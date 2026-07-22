# ============================================================
# Makefile - Proyecto WS2812 8x8 para Colorlight i9
#
#   make sim          -> corre los 3 testbenches
#   make sim_timer    -> solo el timer
#   make sim_led      -> solo el serializador
#   make sim_matrix   -> solo el arreglo 8x8 (imagen unica, N_FRAMES=1)
#   make sim_matrix_multiframe -> los 12 glifos de la calculadora + frame_sel
#   make waves        -> abre gtkwave con el VCD de la matriz
#   make bit          -> sintesis + PnR + bitstream (yosys/nextpnr), imagen
#                        por defecto img/image.hex (corazon de ejemplo)
#   make flash        -> cargar a la placa con openFPGALoader
#   make test-digit HEX_FILE=img/digit_3.hex
#                     -> limpia, sintetiza y flashea UN solo glifo (para
#                        probar cada digito/operador por separado con el
#                        flujo standalone, sin SoC ni firmware de por medio;
#                        ver img/gen_glyphs.py para la lista de digit_*.hex)
#   make test-multiframe FRAME_SEL=3
#                     -> limpia, sintetiza y flashea calc_glyphs.hex completo
#                        (los 12 cuadros) con frame_sel fijo en 3 al compilar,
#                        para probar el direccionamiento multi-cuadro en
#                        hardware real sin SoC ni firmware de por medio.
#   make clean
# ============================================================

RTL = rtl/ws2812_timer.v rtl/ws2812_led.v rtl/ws2812_matrix8x8.v
TOP = rtl/top.v
TOP_MF = rtl/top_multiframe.v
HEX_FILE ?= img/image.hex
FRAME_SEL ?= 0

sim: sim_timer sim_led sim_matrix

sim_timer:
	cd sim && iverilog -g2012 -o tb_timer ../rtl/ws2812_timer.v ../tb/tb_ws2812_timer.v && vvp tb_timer

sim_led:
	cd sim && iverilog -g2012 -o tb_led ../rtl/ws2812_timer.v ../rtl/ws2812_led.v ../tb/tb_ws2812_led.v && vvp tb_led

sim_matrix:
	cd sim && iverilog -g2012 -o tb_matrix $(addprefix ../,$(RTL)) ../tb/tb_ws2812_matrix8x8.v && vvp tb_matrix

sim_matrix_multiframe:
	cd sim && iverilog -g2012 -o tb_matrix_mf $(addprefix ../,$(RTL)) ../tb/tb_ws2812_matrix8x8_multiframe.v && vvp tb_matrix_mf

waves:
	gtkwave sim/tb_ws2812_matrix8x8.vcd &

# --- Flujo open-source para el ECP5 de la Colorlight i9 ---
# El .hex debe estar visible desde donde corre yosys ($readmemh)
bit: top.bit

top.json: $(RTL) $(TOP) $(HEX_FILE)
	cp $(HEX_FILE) image.hex
	yosys -p "read_verilog $(RTL) $(TOP); synth_ecp5 -top top -json top.json"

top_out.config: top.json colorlight_i9.lpf
	nextpnr-ecp5 --45k --package CABGA381 --speed 6 \
	  --json top.json --lpf colorlight_i9.lpf --textcfg top_out.config

top.bit: top_out.config
	ecppack top_out.config top.bit

flash: top.bit
	openFPGALoader -b colorlight-i9 top.bit

# Limpia siempre antes de sintetizar: como top.json/top.bit no cambian de
# nombre entre glifos, sin este 'clean' make podria pensar (por fecha)
# que ya estan al dia y no volver a copiar el .hex nuevo.
test-digit:
	$(MAKE) clean
	$(MAKE) bit HEX_FILE=$(HEX_FILE)
	$(MAKE) flash

# --- Variante multi-cuadro (frame_sel fijo, ver top_multiframe.v) ---
top_mf.json: $(RTL) $(TOP_MF) img/calc_glyphs.hex
	cp img/calc_glyphs.hex .
	yosys -p "read_verilog -D TEST_FRAME_SEL=$(FRAME_SEL) $(RTL) $(TOP_MF); synth_ecp5 -top top_multiframe -json top_mf.json"

top_mf_out.config: top_mf.json colorlight_i9.lpf
	nextpnr-ecp5 --45k --package CABGA381 --speed 6 \
	  --json top_mf.json --lpf colorlight_i9.lpf --textcfg top_mf_out.config

top_mf.bit: top_mf_out.config
	ecppack top_mf_out.config top_mf.bit

test-multiframe:
	rm -f top_mf.json top_mf_out.config top_mf.bit calc_glyphs.hex
	$(MAKE) top_mf.bit FRAME_SEL=$(FRAME_SEL)
	openFPGALoader -b colorlight-i9 top_mf.bit

clean:
	rm -f sim/tb_timer sim/tb_led sim/tb_matrix sim/tb_matrix_mf sim/*.vcd
	rm -f top.json top_out.config top.bit image.hex
	rm -f top_mf.json top_mf_out.config top_mf.bit calc_glyphs.hex
