// ============================================================
// ws2812_timer.v
// Base de tiempos para el protocolo WS2812 (NRZ de un solo hilo)
// Pensado para la Colorlight i9 (reloj de 25 MHz -> 40 ns/ciclo)
//
// Tiempos del WS2812B:
//   Bit '0':  T0H = 0.40 us  |  T0L = 0.85 us
//   Bit '1':  T1H = 0.80 us  |  T1L = 0.45 us
//   Periodo de bit ~= 1.25 us
//   RESET (latch): linea en bajo > 50 us
//
// A 25 MHz:
//   1.25 us = 31.25 ciclos -> usamos 31 (1.24 us, dentro de tolerancia)
//   0.40 us = 10 ciclos
//   0.80 us = 20 ciclos
//   RESET   = 2500 ciclos (100 us, con margen de sobra)
//
// Funcionamiento:
//   - 'run' habilita el conteo del periodo de bit.
//   - 'bit_in' indica que bit se esta transmitiendo (0/1).
//   - 'dout_level' entrega el nivel que debe tener la linea de datos.
//   - 'bit_done' se pulsa 1 ciclo al terminar cada periodo de bit.
//   - 'rst_req' pide generar el tiempo de RESET/latch; 'rst_done'
//     se pulsa 1 ciclo cuando el tiempo de latch termino.
// ============================================================
`timescale 1ns / 1ps

module ws2812_timer #(
    parameter CLK_HZ       = 25_000_000,
    parameter CYCLES_BIT   = 31,    // ~1.25 us
    parameter CYCLES_T0H   = 10,    // ~0.40 us
    parameter CYCLES_T1H   = 20,    // ~0.80 us
    parameter CYCLES_RESET = 2500   // ~100 us
)(
    input  wire clk,
    input  wire rst_n,      // reset asincrono activo en bajo

    input  wire run,        // habilita el conteo de bits
    input  wire bit_in,     // valor del bit a serializar
    input  wire rst_req,    // solicitar periodo de latch (linea en bajo)

    output wire dout_level, // nivel de la linea de datos WS2812
    output wire bit_done,   // pulso: ultimo ciclo de un periodo de bit
    output wire rst_done    // pulso: ultimo ciclo del periodo de latch
);

    // Ancho suficiente para el contador mas grande
    localparam CW = $clog2(CYCLES_RESET + 1);

    reg [CW-1:0] cnt;

    // 'bit_done' y 'rst_done' son COMBINACIONALES: se activan durante
    // el ultimo ciclo del periodo, de modo que la FSM que consume
    // estas senales cambie de estado en el MISMO flanco en que 'cnt'
    // da la vuelta. Asi no aparecen pulsos espurios en la linea al
    // pasar de un pixel al siguiente.
    assign bit_done = run     && (cnt == CYCLES_BIT   - 1);
    assign rst_done = rst_req && (cnt == CYCLES_RESET - 1);

    // ------------------------------------------------------------
    // Contador de periodo de bit / latch
    // ------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cnt <= {CW{1'b0}};
        end else begin
            if (run) begin
                if (bit_done) cnt <= {CW{1'b0}};
                else          cnt <= cnt + 1'b1;
            end else if (rst_req) begin
                if (rst_done) cnt <= {CW{1'b0}};
                else          cnt <= cnt + 1'b1;
            end else begin
                cnt <= {CW{1'b0}};
            end
        end
    end

    // ------------------------------------------------------------
    // Nivel de salida: alto durante T0H o T1H segun el bit,
    // bajo el resto del periodo. En latch siempre bajo.
    // ------------------------------------------------------------
    wire [CW-1:0] t_high = bit_in ? CYCLES_T1H[CW-1:0] : CYCLES_T0H[CW-1:0];

    assign dout_level = run ? (cnt < t_high) : 1'b0;

endmodule
