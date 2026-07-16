module addsub_16(clk , rst , init , A , B , sub , result , carry , overflow , done);

  input rst;
  input clk;
  input init;
  input [15:0] A;
  input [15:0] B;
  input sub;
  output [15:0] result;
  output carry;
  output overflow;
  output done;

  wire w_load;
  wire w_calc;
  wire w_last;

  wire [15:0] w_Beff;
  wire [15:0] w_sA;
  wire [15:0] w_sB;

  wire w_sum;
  wire w_cout;
  wire w_ov_in;

  // sub=1 selects A-B: invert B and inject the "+1" of two's complement as
  // the initial carry-in (cin_init below), turning the adder into a subtractor.
  assign w_Beff = B ^ {16{sub}};

  sra_addsub sra0 (.clk(clk), .in_A(A)     , .shift(w_calc) , .load(w_load) , .s_A(w_sA));
  srb_addsub srb0 (.clk(clk), .in_B(w_Beff), .shift(w_calc) , .load(w_load) , .s_B(w_sB));

  fa_addsub  fa0  (.a(w_sA[0]), .b(w_sB[0]), .cin(carry), .sum(w_sum), .cout(w_cout));

  carry_addsub carry0 (.clk(clk), .cin_init(sub), .cout(w_cout), .load(w_load), .upd(w_calc), .carry(carry));

  // overflow = carry-in to the MSB stage XOR carry-out of the MSB stage,
  // continuously recomputed and only its value after the final iteration matters.
  assign w_ov_in = carry ^ w_cout;
  ov_addsub ov0 (.clk(clk), .ov_in(w_ov_in), .load(w_load), .upd(w_calc), .overflow(overflow));

  res_addsub res0 (.clk(clk), .bit_in(w_sum), .load(w_load), .shift(w_calc), .result(result));

  count_addsub count0 (.clk(clk), .load(w_load), .inc(w_calc), .last(w_last));

  control_addsub control0 (.clk(clk), .rst(rst), .init(init), .last(w_last), .done(done), .load(w_load), .calc(w_calc));

endmodule
