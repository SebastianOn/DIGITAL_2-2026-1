module div_32(clk , rst , init , A , B , quotient , remainder , done , error);

  input rst;
  input clk;
  input init;
  input [15:0] A;
  input [15:0] B;
  output [15:0] quotient;
  output [15:0] remainder;
  output done;
  output error;

  wire w_load;
  wire w_shift;
  wire w_setq;
  wire w_errset;
  wire w_z0;
  wire w_last;
  wire w_neg;

  wire [15:0] w_diff;
  wire [31:0] w_aq;

  comp_div0 comp0  (.B(B), .z(w_z0));
  sub_div   sub0   (.R(w_aq[31:16]), .B(B), .diff(w_diff), .neg(w_neg));
  count_div count0 (.clk(clk), .load(w_load), .inc(w_setq), .last(w_last));
  reg_aq    aq0    (.clk(clk), .A(A), .load(w_load), .shift(w_shift), .setq(w_setq), .neg(w_neg), .diff(w_diff), .errset(w_errset), .aq(w_aq));
  control_div control0 (.clk(clk), .rst(rst), .init(init), .z0(w_z0), .last(w_last),
    .done(done), .error(error), .load(w_load), .shift(w_shift), .setq(w_setq), .errset(w_errset));

  assign remainder = w_aq[31:16];
  assign quotient  = w_aq[15:0];

endmodule
