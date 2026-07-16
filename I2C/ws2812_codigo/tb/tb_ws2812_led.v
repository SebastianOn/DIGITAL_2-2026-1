// ============================================================
// tb_ws2812_led.v
// Envia dos pixeles conocidos al serializador y DECODIFICA la
// forma de onda de 'dout' midiendo el ancho de cada pulso alto:
//   ancho > 600 ns -> bit '1', ancho < 600 ns -> bit '0'
// Luego compara los 24 bits recuperados con el dato original.
// Tambien verifica el handshake ready/valid y el latch.
// ============================================================
`timescale 1ns / 1ps

module tb_ws2812_led;

    localparam CLK_PERIOD = 40; // 25 MHz

    reg         clk = 0;
    reg         rst_n = 0;
    reg  [23:0] data = 0;
    reg         valid = 0;
    reg         latch = 0;
    wire        ready, latch_done, dout;

    integer errors = 0;

    ws2812_led dut (
        .clk(clk), .rst_n(rst_n),
        .data(data), .valid(valid), .latch(latch),
        .ready(ready), .latch_done(latch_done), .dout(dout)
    );

    always #(CLK_PERIOD/2) clk = ~clk;

    // ------------------------------------------------------------
    // Decodificador: mide 24 pulsos y reconstruye la palabra
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
    // Tarea: enviar un pixel y verificar lo decodificado
    // ------------------------------------------------------------
    task send_and_check(input [23:0] px);
        reg [23:0] rx;
        begin
            wait (ready);
            @(posedge clk);
            data  <= px;
            valid <= 1'b1;
            @(posedge clk);
            valid <= 1'b0;

            decode_pixel(rx);
            $display("Enviado: %06h  |  Decodificado: %06h  %s",
                     px, rx, (rx === px) ? "[OK]" : "[ERROR]");
            if (rx !== px) errors = errors + 1;
        end
    endtask

    // ------------------------------------------------------------
    // Estimulo principal
    // ------------------------------------------------------------
    realtime t0, t1;
    initial begin
        $dumpfile("tb_ws2812_led.vcd");
        $dumpvars(0, tb_ws2812_led);

        repeat (4) @(posedge clk);
        rst_n = 1;

        // Prueba 1: patron alternado
        send_and_check(24'hA5C3F0);

        // Prueba 2: otro patron (verde puro en GRB)
        send_and_check(24'hFF0000);

        // Prueba 3: ready debe volver a 1 al terminar
        wait (ready);
        $display("Handshake: ready volvio a 1 tras el pixel [OK]");

        // Prueba 4: latch >= 50 us
        @(posedge clk);
        t0 = $realtime;
        latch <= 1'b1;
        @(posedge clk);
        latch <= 1'b0;
        @(posedge latch_done);
        t1 = $realtime;
        $display("Latch: %0d ns (minimo 50000)", t1 - t0);
        if (t1 - t0 < 50000) begin
            $display("  ERROR: latch demasiado corto");
            errors = errors + 1;
        end
        if (dout !== 1'b0) begin
            $display("  ERROR: dout deberia permanecer en 0 durante el latch");
            errors = errors + 1;
        end

        if (errors == 0) $display("\n== TB_LED: TODAS LAS PRUEBAS PASARON ==");
        else             $display("\n== TB_LED: %0d ERRORES ==", errors);
        $finish;
    end

    // Timeout de seguridad
    initial begin
        #2_000_000;
        $display("ERROR: timeout de simulacion");
        $finish;
    end

endmodule
