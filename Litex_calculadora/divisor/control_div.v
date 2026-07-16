module control_div( clk , rst , init , z0 , last , done , error , load , shift , setq , errset );

 input clk;
 input rst;
 input init;
 input z0;
 input last;

 output reg done;
 output reg error;
 output reg load;
 output reg shift;
 output reg setq;
 output reg errset;

 parameter START  = 3'b000;
 parameter LOAD   = 3'b001;
 parameter ZCHECK = 3'b010;
 parameter SHIFT  = 3'b011;
 parameter SETQ   = 3'b100;
 parameter END    = 3'b101;
 parameter ERR    = 3'b110;

 reg [2:0] state;

 initial begin
  done   = 0;
  error  = 0;
  load   = 0;
  shift  = 0;
  setq   = 0;
  errset = 0;
  state  = 0;
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
        state = ZCHECK;
     end

     ZCHECK: begin
        if(z0)
          state = ERR;
        else
          state = SHIFT;
     end

     SHIFT: begin
        state = SETQ;
     end

     SETQ: begin
        if(last)
          state = END;
        else
          state = SHIFT;
     end

     END:begin
        if(init)
          state = START;
        else
          state = END;
     end

     ERR:begin
        if(init)
          state = START;
        else
          state = ERR;
     end

     default: state = START;
   endcase
  end
end


always@(*) begin
    case(state)

      START:begin
        done   = 0;
        error  = 0;
        load   = 0;
        shift  = 0;
        setq   = 0;
        errset = 0;
      end

     LOAD: begin
        done   = 0;
        error  = 0;
        load   = 1;
        shift  = 0;
        setq   = 0;
        errset = 0;
     end

     ZCHECK: begin
        done   = 0;
        error  = 0;
        load   = 0;
        shift  = 0;
        setq   = 0;
        errset = 0;
     end

     SHIFT: begin
        done   = 0;
        error  = 0;
        load   = 0;
        shift  = 1;
        setq   = 0;
        errset = 0;
     end

     SETQ: begin
        done   = 0;
        error  = 0;
        load   = 0;
        shift  = 0;
        setq   = 1;
        errset = 0;
     end

     END:begin
        done   = 1;
        error  = 0;
        load   = 0;
        shift  = 0;
        setq   = 0;
        errset = 0;
     end

     ERR:begin
        done   = 1;
        error  = 1;
        load   = 0;
        shift  = 0;
        setq   = 0;
        errset = 1;
     end

     default: begin
        done   = 0;
        error  = 0;
        load   = 1;
        shift  = 0;
        setq   = 0;
        errset = 0;
     end
   endcase
end

`ifdef BENCH
reg [8*40:1] state_name;
always @(*) begin
  case(state)
    START    : state_name = "START";
    LOAD     : state_name = "LOAD";
    ZCHECK   : state_name = "ZCHECK";
    SHIFT    : state_name = "SHIFT";
    SETQ     : state_name = "SETQ";
    END      : state_name = "END";
    ERR      : state_name = "ERR";
  endcase
end
`endif

endmodule
