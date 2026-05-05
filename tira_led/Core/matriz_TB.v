`timescale 1ns / 1ps

module matriz_tb;

    reg CLK;
    reg RESET;
    reg INIT;
    reg [23:0] DATA;
    wire LED_OUT;
    wire DONE;

    controlador_led uut (
        .CLK(CLK),
        .RESET(RESET),
        .INIT(INIT),
        .DATA(DATA),
        .LED_OUT(LED_OUT),
        .DONE(DONE)
    );

    // Generacion del Reloj a 25MHz
    // 1 ciclo = 40ns -> El reloj cambia de estado cada 20ns
    always #20 CLK = ~CLK;

    initial begin
        CLK = 0;
        RESET = 1;
        INIT = 0;
        DATA = 24'd0;

        // Espera un momento
       #100;
        RESET = 0;
        #40;

        // (0xAA55F0) = 10101010_01010101_11110000 en binario
        DATA = 24'hAA55F0;
        
        // init
        INIT = 1;
        #40;
        INIT = 0;
        wait (DONE == 1'b1);
        
        // espera para el siguiente dato
        #200;

        // (verde puro 0x00FF00)
        DATA = 24'h00FF00;
        
        // Pulso de INIT
        INIT = 1;
        #40;
        INIT = 0;
        
        wait (DONE == 1'b1);
        #200;

        // mensaje final
        $display("Simulacion terminada correctamente.");
        $finish;
    end
    
    initial begin
        $monitor("Tiempo=%0t | RESET=%b | INIT=%b | DATA=%h | DONE=%b | LED_OUT=%b", 
                 $time, RESET, INIT, DATA, DONE, LED_OUT);
    end

    //Generacion de archivo VCD
    initial begin
        $dumpfile("matriz_tb.vcd");
        $dumpvars(0, matriz_tb);
    end

endmodule
