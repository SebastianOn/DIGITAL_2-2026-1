module res_addsub (clk, bit_in, load, shift, result);
  input clk;
  input bit_in;
  input load;
  input shift;
  output reg [15:0]result;

initial result = 16'h0000;

always @(negedge clk)
  if(load)
    result = 16'h0000;
  else if(shift)
    result = {bit_in, result[15:1]};
  else
    result = result;

endmodule
