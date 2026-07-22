// ============================================================
// top.v
// Top-level para la Colorlight i9 (Lattice ECP5, reloj de 25 MHz).
// Conecta el controlador de la matriz 8x8 al pin de salida.
//
// Conexion fisica sugerida:
//   - clk_25mhz : oscilador de 25 MHz de la placa (pin P3)
//   - ws2812_din: cualquier IO libre del header (ver .lpf)
//   - GND comun entre la matriz y la placa.
//   - La matriz se alimenta con 5 V externos; la salida de 3.3 V
//     de la i9 suele bastar para el DIN, pero un level shifter
//     (74HCT125) da mas margen.
// ============================================================
`timescale 1ns / 1ps

module top (
    input  wire clk_25mhz,   // reloj de la placa
    output wire ws2812_din,  // datos hacia la matriz
    output wire led_status   // led de la placa: parpadea por cuadro
);

    // ------------------------------------------------------------
    // Reset por power-on: mantiene rst_n en 0 unos ciclos al inicio
    // ------------------------------------------------------------
    reg [7:0] por_cnt = 8'd0;
    wire      rst_n   = &por_cnt;

    always @(posedge clk_25mhz)
        if (!rst_n) por_cnt <= por_cnt + 1'b1;

    // ------------------------------------------------------------
    // Controlador de la matriz
    // ------------------------------------------------------------
    wire frame_done;

    ws2812_matrix8x8 #(
        .HEX_FILE("image.hex")
    ) u_matrix (
        .clk       (clk_25mhz),
        .rst_n     (rst_n),
        .frame_sel (1'b0),   // unico cuadro (N_FRAMES=1 por defecto)
        .dout      (ws2812_din),
        .frame_done(frame_done)
    );

    // ------------------------------------------------------------
    // LED de estado: cambia cada 256 cuadros (visible a simple vista)
    // ------------------------------------------------------------
    reg [8:0] frame_cnt = 9'd0;
    always @(posedge clk_25mhz)
        if (frame_done) frame_cnt <= frame_cnt + 1'b1;

    assign led_status = frame_cnt[8];

endmodule
