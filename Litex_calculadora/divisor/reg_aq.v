module reg_aq (clk, A, load, shift, setq, neg, diff, errset, aq);
  input clk;
  input [15:0]A;
  input load;
  input shift;
  input setq;
  input neg;
  input [15:0]diff;
  input errset;
  output reg [31:0]aq;

  initial aq = 32'h0;

  always @(negedge clk)
    if(errset)
      aq = {A, 16'hFFFF};
    else if(load)
      aq = {16'h0000, A};
    else if(shift)
      aq = aq << 1;
    else if(setq) begin
      if(neg)
        aq[0] = 1'b0;
      else begin
        aq[31:16] = diff;
        aq[0]     = 1'b1;
      end
    end
    else
      aq = aq;

endmodule
