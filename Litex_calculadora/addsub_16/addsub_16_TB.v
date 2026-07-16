`timescale 1ns / 1ps
`define SIMULATION
module addsub_16_TB;
   reg  clk;
   reg  rst;
   reg  init;
   reg  sub;
   reg  [15:0]A;
   reg  [15:0]B;
   wire [15:0] result;
   wire carry;
   wire overflow;
   wire done;

   integer errors;

   addsub_16 uut (.clk(clk) , .rst(rst) , .init(init) , .A(A) , .B(B) , .sub(sub) ,
                  .result(result) , .carry(carry) , .overflow(overflow) , .done(done));

   parameter PERIOD          = 20;
   parameter real DUTY_CYCLE = 0.5;

   initial begin
     clk = 0;
     forever
       begin
         clk = 1'b0;
         #(PERIOD-(PERIOD*DUTY_CYCLE)) clk = 1'b1;
         #(PERIOD*DUTY_CYCLE);
       end
   end

   task run_case;
     input [15:0] t_A;
     input [15:0] t_B;
     input        t_sub;
     input [15:0] t_result;
     input        t_carry;
     input        t_overflow;
     begin
       @(negedge clk);
       A = t_A; B = t_B; sub = t_sub;
       init = 1;
       @(negedge clk);
       @(negedge clk);
       init = 0;
       wait(done == 1'b1);
       @(negedge clk);
       if (result != t_result || carry != t_carry || overflow != t_overflow) begin
         errors = errors + 1;
         $display("FAIL: A=%h B=%h sub=%b -> result=%h carry=%b overflow=%b (expected result=%h carry=%b overflow=%b)",
                    t_A, t_B, t_sub, result, carry, overflow, t_result, t_carry, t_overflow);
       end else begin
         $display("PASS: A=%h B=%h sub=%b -> result=%h carry=%b overflow=%b",
                    t_A, t_B, t_sub, result, carry, overflow);
       end
     end
   endtask

   initial begin
     errors = 0;
     rst = 1; init = 0; sub = 0; A = 0; B = 0;
     @(negedge clk);
     @(negedge clk);
     rst = 0;

     // A + B, no carry/overflow
     run_case(16'h00F7, 16'h007F, 1'b0, 16'h0176, 1'b0, 1'b0);
     // A - B, A > B: no borrow (carry=1)
     run_case(16'h0064, 16'h0032, 1'b1, 16'h0032, 1'b1, 1'b0);
     // A - B, A < B: borrow (carry=0), result wraps in two's complement
     run_case(16'h0032, 16'h0064, 1'b1, 16'hFFCE, 1'b0, 1'b0);
     // unsigned add overflow (carry out), no signed overflow (-1 + 1 = 0)
     run_case(16'hFFFF, 16'h0001, 1'b0, 16'h0000, 1'b1, 1'b0);
     // signed add overflow: 32767 + 1 -> -32768
     run_case(16'h7FFF, 16'h0001, 1'b0, 16'h8000, 1'b0, 1'b1);
     // signed subtract overflow: -32768 - 1 -> 32767
     run_case(16'h8000, 16'h0001, 1'b1, 16'h7FFF, 1'b1, 1'b1);

     if (errors == 0)
       $display("ALL TESTS PASSED");
     else
       $display("%0d TEST(S) FAILED", errors);

     $finish;
   end

   initial begin: TEST_CASE
     $dumpfile("addsub_16_TB.vcd");
     $dumpvars(-1, uut);
   end
endmodule
