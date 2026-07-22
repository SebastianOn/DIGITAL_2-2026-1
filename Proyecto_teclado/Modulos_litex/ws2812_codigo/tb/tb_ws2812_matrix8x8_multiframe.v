// ============================================================
// tb_ws2812_matrix8x8_multiframe.v
// Prueba de los 12 cuadros de calc_glyphs.hex (digitos 0-9,
// operador blanco, apagado) y de la garantia de "sin corte a
// medias" al cambiar frame_sel durante un barrido:
//   1. Recorre los 12 cuadros en orden y compara cada uno contra
//      la referencia leida del mismo .hex.
//   2. Cambia frame_sel A MITAD de un barrido y verifica que los
//      pixeles restantes de ESE cuadro sigan saliendo con el
//      glifo VIEJO, y que recien el cuadro siguiente (tras su
//      propio latch) refleje el glifo NUEVO.
//
// Nota sobre el momento en que se cambia 'frame_sel' en este TB:
// el DUT solo muestrea frame_sel en el flanco donde 'latch_done'
// esta en alto (una vez por cuadro, ver ws2812_matrix8x8.v). Para
// no depender del orden de eventos dentro del mismo delta-ciclo
// (una carrera clasica de testbench), este TB siempre deja el
// nuevo valor de frame_sel escrito con mucho margen (decenas de
// microsegundos, bastante mas que un delta-ciclo) antes del
// flanco donde realmente se muestrea.
// ============================================================
`timescale 1ns / 1ps

module tb_ws2812_matrix8x8_multiframe;

    localparam CLK_PERIOD  = 40;   // 25 MHz (mismos ciclos de bit que el resto de tb/)
    localparam N_LEDS      = 64;
    localparam N_FRAMES    = 12;
    localparam FSW         = 4;

    reg  clk = 0;
    reg  rst_n = 0;
    reg  [FSW-1:0] frame_sel = 0;
    wire dout;
    wire frame_done;

    integer errors = 0;

    ws2812_matrix8x8 #(
        .HEX_FILE("../img/calc_glyphs.hex"),
        .N_LEDS(N_LEDS),
        .N_FRAMES(N_FRAMES),
        .FRAME_SEL_WIDTH(FSW)
    ) dut (
        .clk(clk), .rst_n(rst_n), .frame_sel(frame_sel),
        .dout(dout), .frame_done(frame_done)
    );

    always #(CLK_PERIOD/2) clk = ~clk;

    // ------------------------------------------------------------
    // Referencia: los 12 cuadros completos
    // ------------------------------------------------------------
    reg [23:0] ref_img [0:(N_FRAMES*N_LEDS)-1];
    initial $readmemh("../img/calc_glyphs.hex", ref_img);

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

    // Decodifica 'count' pixeles empezando en 'start' dentro del cuadro
    // actual y los compara contra ref_img[expect_frame*64 + start .. +count-1]
    task check_pixel_range(input integer tag, input integer start, input integer count, input integer expect_frame);
        integer    n, fails;
        reg [23:0] rx;
        begin
            fails = 0;
            for (n = start; n < start + count; n = n + 1) begin
                decode_pixel(rx);
                if (rx !== ref_img[expect_frame*N_LEDS + n]) begin
                    $display("  [%0d] pixel %0d: esperado %06h (glifo %0d), recibido %06h [ERROR]",
                             tag, n, ref_img[expect_frame*N_LEDS + n], expect_frame, rx);
                    fails = fails + 1;
                end
            end
            if (fails == 0)
                $display("[%0d] pixeles %0d..%0d correctos (glifo %0d) [OK]", tag, start, start+count-1, expect_frame);
            errors = errors + fails;
        end
    endtask

    task check_frame(input integer tag, input integer expect_frame);
        begin
            check_pixel_range(tag, 0, N_LEDS, expect_frame);
        end
    endtask

    integer f;
    initial begin
        $dumpfile("tb_ws2812_matrix8x8_multiframe.vcd");
        $dumpvars(0, tb_ws2812_matrix8x8_multiframe);

        repeat (4) @(posedge clk);
        rst_n = 1;

        // --- 1) Recorre los 12 glifos en orden, uno por cuadro ---
        // El cuadro justo despues del reset usa frame_sel_reg=0 (valor de
        // reset), sin necesidad de esperar ningun frame_done.
        check_frame(0, 0);
        for (f = 1; f < N_FRAMES; f = f + 1) begin
            // Se deja listo el proximo glifo con mucho margen: el cuadro
            // que se acaba de decodificar todavia tiene que pasar por su
            // periodo de latch (>50us) antes de que el DUT vuelva a
            // muestrear frame_sel.
            frame_sel = f;
            @(posedge frame_done);
            check_frame(f, f);
        end

        // --- 2) Prueba de "sin corte a medias" ---
        // Deja pedido el digito '0' con margen de sobra (el ultimo cuadro
        // del bucle anterior, glifo 11, todavia esta en su latch).
        frame_sel = 0;
        @(posedge frame_done);
        // Decodifica la primera mitad del cuadro (glifo 0 esperado)
        check_pixel_range(98, 0, 30, 0);
        // Cambia frame_sel A MITAD del barrido de este mismo cuadro
        frame_sel = 5;
        // El resto del cuadro en curso NO debe verse afectado: debe
        // seguir siendo el glifo 0 (frame_sel_reg ya quedo fijo para
        // todo este cuadro en el flanco anterior).
        check_pixel_range(99, 30, 34, 0);

        // Recien el cuadro siguiente (tras su propio latch) debe
        // reflejar el nuevo valor pedido (glifo 5).
        @(posedge frame_done);
        check_frame(100, 5);

        if (errors == 0) $display("\n== TB_MATRIX_MULTIFRAME: TODAS LAS PRUEBAS PASARON ==");
        else             $display("\n== TB_MATRIX_MULTIFRAME: %0d ERRORES ==", errors);
        $finish;
    end

    // Timeout de seguridad (14 cuadros ~ 14*(64*30us + 100us) < 30 ms)
    initial begin
        #40_000_000;
        $display("ERROR: timeout de simulacion");
        $finish;
    end

endmodule
