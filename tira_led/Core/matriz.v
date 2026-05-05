module controlador_led (

    input wire CLK,         // Reloj 25MHz (1 ciclo = 40ns)
    input wire RESET,       
    input wire INIT,        
    input wire [23:0] DATA, 
    output reg LED_OUT,     
    output reg DONE         
);

    // Tiempos en ciclos de reloj
    localparam T0H = 10;
    localparam T0L = 21;
    localparam T1H = 20;
    localparam T1L = 11;

    // Definicion de estados
    localparam ST_INIT  = 3'd0;
    localparam ST_LOAD  = 3'd1;
    localparam ST_HIGH  = 3'd2;
    localparam ST_LOW   = 3'd3;
    localparam ST_NEXT  = 3'd4;
    localparam ST_DONE  = 3'd5;

    reg [2:0] state;
    reg [23:0] shift_reg;
    reg [4:0] N;  // Contador de bits (N=23 hasta 0)
    reg [5:0] q;  // Contador de ciclos de reloj

    always @(posedge CLK or posedge RESET) begin
        if (RESET) begin
            state     <= ST_INIT;
            LED_OUT   <= 0;
            DONE      <= 0;
            N         <= 23;
            q         <= 0;
            shift_reg <= 24'b0;
        end else begin
            case (state)
                ST_INIT: begin
                    DONE    <= 0;
                    LED_OUT <= 0;
                    if (INIT) begin
                        state <= ST_LOAD;
                    end
                end

                // Cargar datos del LED, N = 23 (MSB primero)
                ST_LOAD: begin
                    shift_reg <= DATA;
                    N         <= 5'd23; 
                    q         <= 0;
                    state     <= ST_HIGH;
                end

                // Estado de tiempo en ALTO (T0H o T1H)
                ST_HIGH: begin
                    LED_OUT <= 1;
                    q       <= q + 1;
                    
                    // N=1? (Verifica si el bit actual es 1 o 0)
                    if (shift_reg[N] == 1'b1) begin
                        if (q == T1H - 1) begin
                            q     <= 0;
                            state <= ST_LOW;
                        end
                    end else begin
                        if (q == T0H - 1) begin
                            q     <= 0;
                            state <= ST_LOW;
                        end
                    end
                end

                // Estado de tiempo en BAJO (T0L o T1L)
                ST_LOW: begin
                    LED_OUT <= 0;
                    q       <= q + 1;
                    
                    if (shift_reg[N] == 1'b1) begin
                        if (q == T1L - 1) begin
                            q     <= 0;
                            state <= ST_NEXT;
                        end
                    end else begin
                        if (q == T0L - 1) begin
                            q     <= 0;
                            state <= ST_NEXT;
                        end
                    end
                end

                // N = N - 1 y validacion N < 0
                ST_NEXT: begin
                    if (N == 0) begin 
                        // Equivalente a N < 0 tras el ultimo bit
                        state <= ST_DONE;
                    end else begin
                        N     <= N - 1;         // Decrementar bit
                        state <= ST_HIGH;
                    end
                end

                // DONE / finish
                ST_DONE: begin
                    DONE  <= 1;
                    state <= ST_INIT; 
                end

                default: state <= ST_INIT;
            endcase
        end
    end

endmodule
