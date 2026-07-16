TARGET=div_32
TOP=div_32

ICE40_SIM_CELLS=../mult/lattice_sim/cells_sim_ecp5.v

OBJS     = div_32.v comp_div0.v sub_div.v count_div.v reg_aq.v control_div.v

BUILD_DIR = build

all: sim

sim:
	rm -f a.out *.vcd
	iverilog -DBENCH -DSIM -DPASSTHROUGH_PLL -DBOARD_FREQ=27 -DCPU_FREQ=27  $(TARGET)_TB.v $(OBJS)
	vvp a.out
	gtkwave $(TARGET)_TB.vcd

$(TOP).json:
	yosys -v3 -l synth.log -p 'synth_ecp5 -top $(TARGET) -json $(TARGET).json; write_verilog -attr2comment $(TARGET)_synth.v' $(OBJS)

## ---------------------
## post-synth simulation
## ---------------------
sim_post_syn: $(TOP).json $(OBJS)
	iverilog -I ../mult/lattice_sim -o $@_PS.vpp -s $(TOP)_TB $(TARGET)_TB.v $(TOP)_synth.v $(ICE40_SIM_CELLS)
	vvp $@_PS.vpp
	gtkwave $(TOP)_TB.vcd &

## ---------------------
## post-route simulation
## ---------------------
$(TOP).config: $(TOP).json
	nextpnr-ecp5 --json $< --lpf $(TOP).lpf --textcfg $@ --25k --package CABGA381 --speed 6  --timing-allow-fail --seed 1 --lpf-allow-unconstrained

$(TOP).bit: $(TOP).config
	ecppack --bootaddr 0 --compress $< --svf ${TOP}.svf --bit $@

svg: $(OBJS)
	yosys -p "prep -top ${TARGET}; write_json ${TARGET}.json" ${OBJS}
	netlistsvg ${TARGET}.json -o ${TARGET}.svg  #--skin default.svg
	yosys -p "prep -top ${TARGET} -flatten; write_json ${TARGET}_flat.json" ${OBJS}
	netlistsvg ${TARGET}_flat.json -o ${TARGET}_flat.svg  #--skin default.svg

clean:
	rm -rf *.out *.vcd *.svg *.json $(TOP)_synth.v *.vpp *.asc $(TOP)_route.v synth.log *.bit *lpf *pcf *scf \
	*svf *tcf *.config
