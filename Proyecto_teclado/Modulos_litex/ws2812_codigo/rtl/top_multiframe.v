// ============================================================
// top_multiframe.v
// Variante de top.v para probar, de forma standalone (sin SoC ni
// firmware), el direccionamiento multi-cuadro de ws2812_matrix8x8
// (N_FRAMES=12, calc_glyphs.hex) con el mismo pin/cableado ya
// confirmado funcionando con top.v.
//
// El glifo mostrado se fija en tiempo de sintesis con la macro
// TEST_FRAME_SEL (ver Makefile: make test-multiframe FRAME_SEL=3).
// ============================================================
`timescale 1ns / 1ps

`ifndef TEST_FRAME_SEL
`define TEST_FRAME_SEL 0
`endif

module top_multiframe (
    input  wire clk_25mhz,
    output wire ws2812_din,
    output wire led_status
);

    reg [7:0] por_cnt = 8'd0;
    wire      rst_n   = &por_cnt;

    always @(posedge clk_25mhz)
        if (!rst_n) por_cnt <= por_cnt + 1'b1;

    wire frame_done;

    ws2812_matrix8x8 #(
        .HEX_FILE("calc_glyphs.hex"),
        .N_FRAMES(12),
        .FRAME_SEL_WIDTH(4)
    ) u_matrix (
        .clk       (clk_25mhz),
        .rst_n     (rst_n),
        .frame_sel (`TEST_FRAME_SEL),
        .dout      (ws2812_din),
        .frame_done(frame_done)
    );

    reg [8:0] frame_cnt = 9'd0;
    always @(posedge clk_25mhz)
        if (frame_done) frame_cnt <= frame_cnt + 1'b1;

    assign led_status = frame_cnt[8];

endmodule
