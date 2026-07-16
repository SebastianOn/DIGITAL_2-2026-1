// ============================================================
// tb_ws2812_matrix8x8.v
// Prueba de integracion del arreglo completo:
//   1. Carga la MISMA imagen .hex que el DUT en una memoria
//      de referencia.
//   2. Decodifica la trama serial de 'dout' (64 pixeles x 24 bits)
//      midiendo el ancho de cada pulso.
//   3. Compara pixel por pixel contra la referencia.
//   4. Verifica que despues del pixel 63 llegue el latch (>50 us
//      en bajo) y el pulso frame_done, y que el cuadro se repita.
// ============================================================
`timescale 1ns / 1ps

module tb_ws2812_matrix8x8;

    localparam CLK_PERIOD = 40;   // 25 MHz
    localparam N_LEDS     = 64;

    reg  clk = 0;
    reg  rst_n = 0;
    wire dout;
    wire frame_done;

    integer errors = 0;

    // DUT: usa la ruta del hex relativa a la carpeta de simulacion
    ws2812_matrix8x8 #(
        .HEX_FILE("../img/image.hex")
    ) dut (
        .clk(clk), .rst_n(rst_n),
        .dout(dout), .frame_done(frame_done)
    );

    always #(CLK_PERIOD/2) clk = ~clk;

    // ------------------------------------------------------------
    // Memoria de referencia (misma imagen)
    // ------------------------------------------------------------
    reg [23:0] ref_img [0:N_LEDS-1];
    initial $readmemh("../img/image.hex", ref_img);

    // ------------------------------------------------------------
    // Decodificador de un pixel (24 pulsos)
    // ------------------------------------------------------------
    task decode_pixel(output [23:0] rx);
        integer  i, width;
        realtime t_rise, t_fall;
        begin
            rx = 24'd0;
            for (i = 0; i < 24; i = i + 1) begin
                @(posedge dout);  t_rise = $realtime;
                @(negedge dout);  t_fall = $realtime;
                width = t_fall - t_rise;
                rx = {rx[22:0], (width > 600) ? 1'b1 : 1'b0};
            end
        end
    endtask

    // ------------------------------------------------------------
    // Verificar un cuadro completo
    // ------------------------------------------------------------
    task check_frame(input integer frame_id);
        integer    n, fails;
        reg [23:0] rx;
        begin
            fails = 0;
            for (n = 0; n < N_LEDS; n = n + 1) begin
                decode_pixel(rx);
                if (rx !== ref_img[n]) begin
                    $display("  Pixel %0d: esperado %06h, recibido %06h [ERROR]",
                             n, ref_img[n], rx);
                    fails = fails + 1;
                end
            end
            if (fails == 0)
                $display("Cuadro %0d: 64/64 pixeles correctos [OK]", frame_id);
            errors = errors + fails;
        end
    endtask

    // ------------------------------------------------------------
    // Estimulo principal
    // ------------------------------------------------------------
    realtime t_last_edge, t_gap;
    initial begin
        $dumpfile("tb_ws2812_matrix8x8.vcd");
        $dumpvars(0, tb_ws2812_matrix8x8);

        repeat (4) @(posedge clk);
        rst_n = 1;

        // --- Cuadro 1
        check_frame(1);
        t_last_edge = $realtime;

        // --- Debe llegar frame_done tras el latch
        @(posedge frame_done);
        t_gap = $realtime - t_last_edge;
        $display("Latch entre cuadros: %0d ns (minimo 50000)", t_gap);
        if (t_gap < 50000) begin
            $display("  ERROR: latch demasiado corto");
            errors = errors + 1;
        end

        // --- Cuadro 2 (refresco automatico)
        check_frame(2);

        if (errors == 0) $display("\n== TB_MATRIX: TODAS LAS PRUEBAS PASARON ==");
        else             $display("\n== TB_MATRIX: %0d ERRORES ==", errors);
        $finish;
    end

    // Timeout de seguridad (2 cuadros ~ 2*(64*30us + 100us) < 6 ms)
    initial begin
        #10_000_000;
        $display("ERROR: timeout de simulacion");
        $finish;
    end

endmodule
