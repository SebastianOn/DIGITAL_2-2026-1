// ============================================================
// ws2812_matrix8x8.v
// Controlador del arreglo de 8x8 (64 leds WS2812 en cadena).
//
// - La imagen se carga desde un archivo .hex con $readmemh:
//   64 lineas, cada una un valor de 24 bits en formato GRB
//   (GGRRBB en hexadecimal). La direccion 0 es el primer led
//   de la cadena (esquina segun el cableado de la matriz).
// - El modulo recorre las 64 posiciones, envia cada pixel al
//   serializador ws2812_led y al final genera el latch (>50us).
// - Luego refresca la imagen de forma continua ('frame_done'
//   pulsa 1 ciclo al final de cada cuadro).
// ============================================================
`timescale 1ns / 1ps

module ws2812_matrix8x8 #(
    parameter HEX_FILE     = "image.hex",
    parameter N_LEDS       = 64,
    parameter CYCLES_BIT   = 31,
    parameter CYCLES_T0H   = 10,
    parameter CYCLES_T1H   = 20,
    parameter CYCLES_RESET = 2500
)(
    input  wire clk,
    input  wire rst_n,

    output wire dout,       // hacia el pin DIN de la matriz
    output reg  frame_done  // pulso: cuadro completo enviado
);

    localparam AW = $clog2(N_LEDS);

    // ------------------------------------------------------------
    // Memoria de imagen (se infiere como BRAM en el ECP5)
    // ------------------------------------------------------------
    reg [23:0] framebuf [0:N_LEDS-1];

    initial begin
        $readmemh(HEX_FILE, framebuf);
    end

    // ------------------------------------------------------------
    // Serializador de un led
    // ------------------------------------------------------------
    reg  [23:0] px_data;
    reg         px_valid;
    reg         do_latch;
    wire        drv_ready;
    wire        latch_done;

    ws2812_led #(
        .CYCLES_BIT  (CYCLES_BIT),
        .CYCLES_T0H  (CYCLES_T0H),
        .CYCLES_T1H  (CYCLES_T1H),
        .CYCLES_RESET(CYCLES_RESET)
    ) u_led (
        .clk       (clk),
        .rst_n     (rst_n),
        .data      (px_data),
        .valid     (px_valid),
        .latch     (do_latch),
        .ready     (drv_ready),
        .latch_done(latch_done),
        .dout      (dout)
    );

    // ------------------------------------------------------------
    // FSM de barrido del arreglo
    // ------------------------------------------------------------
    localparam [1:0] S_READ  = 2'd0,  // leer pixel de memoria
                     S_SEND  = 2'd1,  // entregar pixel al driver
                     S_WAIT  = 2'd2,  // esperar fin del pixel
                     S_LATCH = 2'd3;  // esperar fin del latch

    reg [1:0]    state;
    reg [AW-1:0] addr;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state      <= S_READ;
            addr       <= {AW{1'b0}};
            px_data    <= 24'd0;
            px_valid   <= 1'b0;
            do_latch   <= 1'b0;
            frame_done <= 1'b0;
        end else begin
            px_valid   <= 1'b0;
            do_latch   <= 1'b0;
            frame_done <= 1'b0;

            case (state)
                // Lectura sincrona de la BRAM
                S_READ: begin
                    px_data <= framebuf[addr];
                    state   <= S_SEND;
                end

                // Pulso de valid cuando el driver este listo
                S_SEND: begin
                    if (drv_ready) begin
                        px_valid <= 1'b1;
                        state    <= S_WAIT;
                    end
                end

                // Esperar a que el driver termine los 24 bits.
                // (un ciclo despues de valid, ready baja; cuando
                //  vuelve a subir el pixel ya salio completo)
                S_WAIT: begin
                    if (!px_valid && drv_ready) begin
                        if (addr == N_LEDS-1) begin
                            addr     <= {AW{1'b0}};
                            do_latch <= 1'b1;
                            state    <= S_LATCH;
                        end else begin
                            addr  <= addr + 1'b1;
                            state <= S_READ;
                        end
                    end
                end

                // Fin del latch -> cuadro completo, refrescar
                S_LATCH: begin
                    if (latch_done) begin
                        frame_done <= 1'b1;
                        state      <= S_READ;
                    end
                end
            endcase
        end
    end

endmodule
