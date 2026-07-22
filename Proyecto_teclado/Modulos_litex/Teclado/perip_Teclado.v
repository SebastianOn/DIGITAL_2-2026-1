module peripheral_Teclado(
    input  clk,
    input reset,
	input [31:0]d_in,
	input rd,
    input wr,
	input cs,
	input [6:0]addr,
	output reg [31:0]d_out,

    input C0,
    input C1,
    input C2,
    input C3,
    
    output R0,
    output R1,
    output R2,
    output R3
);

//------------------------------------ regs and wires-------------------------------
reg [2:0] s; 	     //selector mux_4  and demux_4
reg init;
wire [5:0]tecla;
wire done;

//------------------------------------ regs and wires-------------------------------

//----address_decoder (one selection bit for register) ------------------
always @(*) begin
	case (addr)
		8'h04:begin s = (cs) ? 3'b001 : 3'b000 ;end //init
		8'h08:begin s = (cs) ? 3'b010 : 3'b000 ;end //tecla
        8'h0C:begin s = (cs) ? 3'b100 : 3'b000 ;end //done
		default:begin s=3'b000 ; end
	endcase
end

//Input Registers
always @(posedge clk) begin
	init = (s[0] & wr) ? d_in[0] : init;
end

//Output registers
always @(posedge clk) begin
	case (s)
		3'b010: d_out= {26'b0,tecla};
		3'b100: d_out= {31'b0,done};
		default: d_out=0;	
	endcase
end
Teclado Tcl(
      .clk(clk), 
      .reset(reset), 
      .init(init), 
      .C0(C0), 
	  .C1(C1),
      .C2(C2), 
      .C3(C3), 
      .R0(R0), 
      .R1(R1), 
      .R2(R2), 
      .R3(R3), 
      .tecla(tecla), 
      .done(done)
);   
endmodule