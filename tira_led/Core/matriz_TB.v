`timescale 1ns / 1ps

module matriz_tb;

    reg CLK;
    reg RESET;
    reg INIT;
    reg [23:0] DATA;

    // Salidas del DUT declaradas como wire
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
        // 1. Inicializacion de señales
        CLK = 0;
        RESET = 1;
        INIT = 0;
        DATA = 24'd0;

        // Esperar unos ciclos y soltar el reset
       #100;
        RESET = 0;
        #40;

        // 2. Primera prueba: Enviar un patron mixto (0xAA55F0)
        // 0xAA55F0 = 10101010_01010101_11110000 en binario
        DATA = 24'hAA55F0;
        
        // Dar el pulso de INIT por un ciclo de reloj
        INIT = 1;
        #40;
        INIT = 0;

        // Esperar hasta que el modulo indique que termino
        wait (DONE == 1'b1);
        
        // Dar un pequeño margen de tiempo antes de la siguiente trama
        #200;

        // 3. Segunda prueba: (verde puro 0x00FF00)
        DATA = 24'h00FF00;
        
        // Pulso de INIT
        INIT = 1;
        #40;
        INIT = 0;

        // Esperar a que termine
        wait (DONE == 1'b1);
        #200;

        // Finalizar la simulacion
        $display("Simulacion terminada correctamente.");
        $finish;
    end

    //Bloque para monitorear señales en la consola del simulador
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
