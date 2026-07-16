# ============================================================
# Makefile - Proyecto WS2812 8x8 para Colorlight i9
#
#   make sim          -> corre los 3 testbenches
#   make sim_timer    -> solo el timer
#   make sim_led      -> solo el serializador
#   make sim_matrix   -> solo el arreglo 8x8
#   make waves        -> abre gtkwave con el VCD de la matriz
#   make bit          -> sintesis + PnR + bitstream (yosys/nextpnr)
#   make flash        -> cargar a la placa con openFPGALoader
#   make clean
# ============================================================

RTL = rtl/ws2812_timer.v rtl/ws2812_led.v rtl/ws2812_matrix8x8.v
TOP = rtl/top.v

sim: sim_timer sim_led sim_matrix

sim_timer:
	cd sim && iverilog -g2012 -o tb_timer ../rtl/ws2812_timer.v ../tb/tb_ws2812_timer.v && vvp tb_timer

sim_led:
	cd sim && iverilog -g2012 -o tb_led ../rtl/ws2812_timer.v ../rtl/ws2812_led.v ../tb/tb_ws2812_led.v && vvp tb_led

sim_matrix:
	cd sim && iverilog -g2012 -o tb_matrix $(addprefix ../,$(RTL)) ../tb/tb_ws2812_matrix8x8.v && vvp tb_matrix

waves:
	gtkwave sim/tb_ws2812_matrix8x8.vcd &

# --- Flujo open-source para el ECP5 de la Colorlight i9 ---
# El .hex debe estar visible desde donde corre yosys ($readmemh)
bit: top.bit

top.json: $(RTL) $(TOP) img/image.hex
	cp img/image.hex .
	yosys -p "read_verilog $(RTL) $(TOP); synth_ecp5 -top top -json top.json"

top_out.config: top.json colorlight_i9.lpf
	nextpnr-ecp5 --45k --package CABGA381 --speed 6 \
	  --json top.json --lpf colorlight_i9.lpf --textcfg top_out.config

top.bit: top_out.config
	ecppack top_out.config top.bit

flash: top.bit
	openFPGALoader -b colorlight-i9 top.bit

clean:
	rm -f sim/tb_timer sim/tb_led sim/tb_matrix sim/*.vcd
	rm -f top.json top_out.config top.bit image.hex
