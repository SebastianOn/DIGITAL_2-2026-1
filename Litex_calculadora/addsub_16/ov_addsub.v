module ov_addsub (clk, ov_in, load, upd, overflow);
  input clk;
  input ov_in;
  input load;
  input upd;
  output reg overflow;

initial overflow = 1'b0;

always @(negedge clk)
  if(load)
    overflow = 1'b0;
  else if(upd)
    overflow = ov_in;
  else
    overflow = overflow;

endmodule
