module count_div (clk, load, inc, last);
  input clk;
  input load;
  input inc;
  output last;
  reg [4:0]cnt;

  initial cnt = 5'h0;

  always @(negedge clk)
    if(load) cnt = 5'h0;
    else if(inc) cnt = cnt + 5'h1;
    else cnt = cnt;

  // 16 shift/subtract iterations are needed for a 16-bit division; `last`
  // is sampled by control_div *after* the counter's post-iteration
  // increment, so the threshold is 16 (not 15) to avoid stopping one
  // iteration early.
  assign last = (cnt == 5'd16);

endmodule
