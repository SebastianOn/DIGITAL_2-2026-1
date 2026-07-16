module control_addsub( clk , rst , init , last , done , load , calc );

 input clk;
 input rst;
 input init;
 input last;

 output reg done;
 output reg load;
 output reg calc;

 parameter START   = 2'b00;
 parameter LOAD    = 2'b01;
 parameter COMPUTE = 2'b10;
 parameter END     = 2'b11;

 reg [1:0] state;

 initial begin
  done  = 0;
  load  = 0;
  calc  = 0;
  state = 0;
 end

always @(posedge clk) begin
    if (rst) begin
      state = START;
    end else begin
    case(state)

      START:begin
        if(init)
          state = LOAD;
        else
          state = START;
      end

     LOAD: begin
        state = COMPUTE;
     end

     COMPUTE: begin
        if(last)
          state = END;
        else
          state = COMPUTE;
     end

     END:begin
        if(init)
          state = START;
        else
          state = END;
     end

     default: state = START;
   endcase
  end
end


always@(*) begin
    case(state)

      START:begin
        done  = 0;
        load  = 0;
        calc  = 0;
      end

     LOAD: begin
        done  = 0;
        load  = 1;
        calc  = 0;
     end

     COMPUTE: begin
        done  = 0;
        load  = 0;
        calc  = 1;
     end

     END:begin
        done  = 1;
        load  = 0;
        calc  = 0;
     end

     default: begin
        done  = 0;
        load  = 1;
        calc  = 0;
     end
   endcase
end

`ifdef BENCH
reg [8*40:1] state_name;
always @(*) begin
  case(state)
    START    : state_name = "START";
    LOAD     : state_name = "LOAD";
    COMPUTE  : state_name = "COMPUTE";
    END      : state_name = "END";
  endcase
end
`endif

endmodule
