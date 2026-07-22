// ============================================================
// ws2812_led.v
// Serializador de 24 bits (formato GRB, MSB primero) para UN led
// WS2812. Usa ws2812_timer como base de tiempos.
//
// Protocolo de handshake:
//   - Cuando 'ready' = 1, el modulo puede aceptar un nuevo pixel.
//   - El usuario pone 'data' (24 bits GRB) y pulsa 'valid' 1 ciclo.
//   - El modulo serializa los 24 bits por 'dout'.
//   - Al terminar los 24 bits vuelve a 'ready' = 1 SIN soltar la
//     linea: si se encadenan pixeles seguidos, los bits salen
//     back-to-back (asi se cargan los 64 leds de la matriz).
//   - Si se pulsa 'latch' cuando ready=1, genera el periodo de
//     reset (>50us en bajo) y pulsa 'latch_done'.
//
// Nota de formato: el WS2812 recibe primero G7..G0, luego R7..R0
// y por ultimo B7..B0. Aqui 'data' ya se asume en orden GRB:
//   data[23:16] = G, data[15:8] = R, data[7:0] = B
// ============================================================
`timescale 1ns / 1ps

module ws2812_led #(
    parameter CYCLES_BIT   = 31,
    parameter CYCLES_T0H   = 10,
    parameter CYCLES_T1H   = 20,
    parameter CYCLES_RESET = 2500
)(
    input  wire        clk,
    input  wire        rst_n,

    input  wire [23:0] data,       // pixel GRB
    input  wire        valid,      // pulso: cargar y transmitir 'data'
    input  wire        latch,      // pulso: generar tiempo de reset
    output wire        ready,      // 1 = listo para nuevo pixel/latch
    output reg         latch_done, // pulso: latch terminado

    output wire        dout        // linea de datos hacia la tira/matriz
);

    // ------------------- FSM -------------------
    localparam [1:0] S_IDLE  = 2'd0,
                     S_SHIFT = 2'd1,
                     S_LATCH = 2'd2;

    reg [1:0]  state;
    reg [23:0] shreg;    // registro de desplazamiento (MSB primero)
    reg [4:0]  bit_cnt;  // 0..23

    wire bit_done, rst_done;

    assign ready = (state == S_IDLE);

    // Bit actual = MSB del registro de desplazamiento
    wire cur_bit = shreg[23];

    // ------------------- Timer -------------------
    ws2812_timer #(
        .CYCLES_BIT  (CYCLES_BIT),
        .CYCLES_T0H  (CYCLES_T0H),
        .CYCLES_T1H  (CYCLES_T1H),
        .CYCLES_RESET(CYCLES_RESET)
    ) u_timer (
        .clk       (clk),
        .rst_n     (rst_n),
        .run       (state == S_SHIFT),
        .bit_in    (cur_bit),
        .rst_req   (state == S_LATCH),
        .dout_level(dout),
        .bit_done  (bit_done),
        .rst_done  (rst_done)
    );

    // ------------------- Control -------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state      <= S_IDLE;
            shreg      <= 24'd0;
            bit_cnt    <= 5'd0;
            latch_done <= 1'b0;
        end else begin
            latch_done <= 1'b0;

            case (state)
                S_IDLE: begin
                    if (valid) begin
                        shreg   <= data;
                        bit_cnt <= 5'd0;
                        state   <= S_SHIFT;
                    end else if (latch) begin
                        state <= S_LATCH;
                    end
                end

                S_SHIFT: begin
                    if (bit_done) begin
                        if (bit_cnt == 5'd23) begin
                            state <= S_IDLE;   // pixel completo
                        end else begin
                            shreg   <= {shreg[22:0], 1'b0};
                            bit_cnt <= bit_cnt + 1'b1;
                        end
                    end
                end

                S_LATCH: begin
                    if (rst_done) begin
                        latch_done <= 1'b1;
                        state      <= S_IDLE;
                    end
                end

                default: state <= S_IDLE;
            endcase
        end
    end

endmodule
