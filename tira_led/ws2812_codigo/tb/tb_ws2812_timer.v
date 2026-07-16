// ============================================================
// tb_ws2812_timer.v
// Verifica que el timer genere:
//   - Bit '0': ~0.40 us en alto dentro de un periodo de ~1.24 us
//   - Bit '1': ~0.80 us en alto dentro de un periodo de ~1.24 us
//   - RESET  : ~100 us con la linea en bajo
// Mide los anchos reales con marcas de tiempo y los compara.
// ============================================================
`timescale 1ns / 1ps

module tb_ws2812_timer;

    localparam CLK_PERIOD = 40; // 25 MHz

    reg  clk = 0;
    reg  rst_n = 0;
    reg  run = 0;
    reg  bit_in = 0;
    reg  rst_req = 0;
    wire dout_level, bit_done, rst_done;

    integer errors = 0;

    ws2812_timer dut (
        .clk(clk), .rst_n(rst_n),
        .run(run), .bit_in(bit_in), .rst_req(rst_req),
        .dout_level(dout_level), .bit_done(bit_done), .rst_done(rst_done)
    );

    always #(CLK_PERIOD/2) clk = ~clk;

    // ------------------------------------------------------------
    // Tarea: transmitir un bit y medir T_high y el periodo total
    // ------------------------------------------------------------
    task check_bit(input value, input integer exp_high_ns, input integer exp_period_ns);
        realtime t_start, t_fall, t_end;
        integer  high_ns, period_ns;
        begin
            bit_in = value;
            @(posedge clk);
            run = 1;
            @(posedge dout_level);
            t_start = $realtime;
            @(negedge dout_level);
            t_fall  = $realtime;
            @(posedge bit_done);
            t_end   = $realtime;
            @(posedge clk);
            run = 0;
            @(posedge clk);

            high_ns   = t_fall - t_start;
            period_ns = t_end  - t_start + CLK_PERIOD; // bit_done llega 1 flanco despues

            $display("Bit %0d: T_high = %0d ns (esperado %0d), periodo ~ %0d ns (esperado %0d)",
                     value, high_ns, exp_high_ns, period_ns, exp_period_ns);

            // Tolerancia de +/- 1 ciclo (40 ns)
            if (high_ns < exp_high_ns - CLK_PERIOD || high_ns > exp_high_ns + CLK_PERIOD) begin
                $display("  ERROR: T_high fuera de rango");
                errors = errors + 1;
            end
            if (period_ns < exp_period_ns - 2*CLK_PERIOD || period_ns > exp_period_ns + 2*CLK_PERIOD) begin
                $display("  ERROR: periodo fuera de rango");
                errors = errors + 1;
            end
        end
    endtask

    // ------------------------------------------------------------
    // Estimulo principal
    // ------------------------------------------------------------
    realtime t_rst0, t_rst1;
    integer  rst_ns;

    initial begin
        $dumpfile("tb_ws2812_timer.vcd");
        $dumpvars(0, tb_ws2812_timer);

        // Reset
        repeat (4) @(posedge clk);
        rst_n = 1;
        repeat (2) @(posedge clk);

        // --- Prueba 1: bit '0' (400 ns en alto, 1240 ns de periodo)
        check_bit(1'b0, 400, 1240);

        // --- Prueba 2: bit '1' (800 ns en alto)
        check_bit(1'b1, 800, 1240);

        // --- Prueba 3: la linea debe estar en bajo si run=0
        if (dout_level !== 1'b0) begin
            $display("ERROR: dout_level deberia ser 0 en reposo");
            errors = errors + 1;
        end

        // --- Prueba 4: periodo de RESET (latch) ~100 us
        @(posedge clk);
        t_rst0 = $realtime;
        rst_req = 1;
        @(posedge rst_done);
        t_rst1 = $realtime;
        rst_req = 0;
        rst_ns = t_rst1 - t_rst0;
        $display("RESET: duracion = %0d ns (esperado ~100000, minimo WS2812 = 50000)", rst_ns);
        if (rst_ns < 50000) begin
            $display("  ERROR: el latch es menor a 50 us");
            errors = errors + 1;
        end

        // --- Resultado
        if (errors == 0) $display("\n== TB_TIMER: TODAS LAS PRUEBAS PASARON ==");
        else             $display("\n== TB_TIMER: %0d ERRORES ==", errors);
        $finish;
    end

endmodule
