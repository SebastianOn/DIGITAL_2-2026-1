module carry_addsub (clk, cin_init, cout, load, upd, carry);
  input clk;
  input cin_init;
  input cout;
  input load;
  input upd;
  output reg carry;

initial carry = 1'b0;

always @(negedge clk)
  if(load)
    carry = cin_init;
  else if(upd)
    carry = cout;
  else
    carry = carry;

endmodule
