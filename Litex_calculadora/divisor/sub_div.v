module sub_div (R, B, diff, neg);
  input  [15:0]R;
  input  [15:0]B;
  output [15:0]diff;
  output neg;

  wire [16:0] result;

  assign result = {1'b0, R} - {1'b0, B};
  assign diff   = result[15:0];
  assign neg    = result[16];

endmodule
