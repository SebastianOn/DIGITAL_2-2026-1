`timescale 1ns / 1ps
`define SIMULATION
module Teclado_TB;
   reg  clk;
   reg  reset;
   reg  init;
   reg  C0;
   reg  C1;
   reg  C2;
   reg  C3;
   wire R0;
   wire R1;
   wire R2;
   wire R3;
   wire [5:0]tecla;
   wire done;

    Teclado Tcl0(
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


   parameter PERIOD = 20;
   initial begin  // Initialize Inputs
      clk = 0; reset = 0; init = 0;
      C0 = 0;C1 = 0;C2 = 0;C3 = 0;
   end
   // clk generation
   initial         clk <= 0;
   always #(PERIOD/2) clk <= ~clk;

   initial begin // Reset the system, Start the image capture process
        // Reset 
        @ (negedge clk);
	     reset = 1;
	     @ (negedge clk);
	     reset = 0;
        @ (posedge clk);
        init = 1;
        #(PERIOD*2)
        init = 0;
        #(PERIOD*4)        
        C0 = 1;
        #(PERIOD*2)
        C0 = 0;
        #(PERIOD)
        C1 = 1;
        #(PERIOD)
        C2 = 1;
        #(PERIOD*2)
        C1 = 0;
        C2 = 0;
        #(PERIOD*6)
        C0 = 1;
        #(PERIOD*40)
        wait(done)
        #(PERIOD)
        init = 1;
        #(PERIOD*2)
        init = 0;

        
   end
	 

   initial begin: TEST_CASE
     $dumpfile("Teclado_TB.vcd");
     $dumpvars(-1, Teclado_TB);
     #(PERIOD*200) $finish;
   end

endmodule


