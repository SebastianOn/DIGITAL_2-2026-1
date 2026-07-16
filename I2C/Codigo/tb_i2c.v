//==============================================================================
// tb_i2c.v
// Testbench: conecta i2c_master <-> i2c_slave por el bus (SDA, SCL)
//
// Escenario simulado (igual a los diagramas):
//   1) ESCRITURA : START + direccion 1100100 + W(0) + ACK + byte 0xA5 + ACK + STOP
//   2) LECTURA   : START + direccion 1100100 + R(1) + ACK + el esclavo devuelve
//                  el byte que recibio + NACK del maestro + STOP
//   3) Direccion equivocada: el esclavo no responde -> NACK (ack_error = 1)
//
// Las lineas SDA y SCL se declaran 'tri1' para modelar las resistencias
// de pull-up del bus I2C (valen '1' cuando nadie las fuerza a '0').
//==============================================================================
`timescale 1ns/1ps

module tb_i2c;

    // Reloj de 50 MHz y reset
    reg clk = 1'b0;
    reg rst_n = 1'b0;
    always #10 clk = ~clk;                 // periodo 20 ns

    // Bus I2C con pull-ups
    tri1 sda;
    tri1 scl;

    // Interfaz del maestro
    reg         start = 1'b0;
    reg  [6:0]  addr;
    reg         rw;
    reg  [7:0]  data_wr;
    wire [7:0]  data_rd;
    wire        busy, done, ack_error;

    // Interfaz del esclavo
    wire [7:0] data_rx;
    wire       rx_valid;
    reg  [7:0] slave_mem = 8'h00;          // "memoria" de 1 byte del esclavo

    // El esclavo devuelve en lectura lo ultimo que se le escribio
    always @(posedge clk)
        if (rx_valid) slave_mem <= data_rx;

    //-------------------------------------------------------------------------
    // DUTs  (I2C a 1 MHz para acortar la simulacion; usar 100_000 en HW real)
    //-------------------------------------------------------------------------
    i2c_master #(
        .CLK_FREQ(50_000_000),
        .I2C_FREQ(1_000_000)
    ) u_master (
        .clk(clk), .rst_n(rst_n),
        .start(start), .addr(addr), .rw(rw),
        .data_wr(data_wr), .data_rd(data_rd),
        .busy(busy), .done(done), .ack_error(ack_error),
        .sda(sda), .scl(scl)
    );

    i2c_slave #(
        .ADDR(7'b1100100)                  // 0x64, como en el diagrama
    ) u_slave (
        .clk(clk), .rst_n(rst_n),
        .scl(scl), .sda(sda),
        .data_tx(slave_mem),
        .data_rx(data_rx), .rx_valid(rx_valid)
    );

    //-------------------------------------------------------------------------
    // Tarea: lanzar una transaccion y esperar a que termine
    //-------------------------------------------------------------------------
    task transaccion(input [6:0] a, input r, input [7:0] d);
        begin
            @(posedge clk);
            addr    <= a;
            rw      <= r;
            data_wr <= d;
            start   <= 1'b1;
            @(posedge clk);
            start   <= 1'b0;
            wait (done);
            @(posedge clk);
        end
    endtask

    integer errores = 0;

    initial begin
        $dumpfile("i2c_sim.vcd");
        $dumpvars(0, tb_i2c);

        // Reset
        repeat (5) @(posedge clk);
        rst_n = 1'b1;
        repeat (5) @(posedge clk);

        //---------------- 1) ESCRITURA: maestro -> esclavo (0xA5) ----------------
        $display("\n[%0t ns] ESCRITURA: addr=0x64, dato=0xA5", $time);
        transaccion(7'b1100100, 1'b0, 8'hA5);
        $display("[%0t ns]   esclavo recibio  = 0x%02h  | ack_error=%b",
                  $time, data_rx, ack_error);
        if (data_rx !== 8'hA5 || ack_error) begin
            $display("   >>> ERROR en la escritura"); errores = errores + 1;
        end

        //---------------- 2) LECTURA: esclavo -> maestro --------------------------
        $display("\n[%0t ns] LECTURA:   addr=0x64", $time);
        transaccion(7'b1100100, 1'b1, 8'h00);
        $display("[%0t ns]   maestro leyo     = 0x%02h  | ack_error=%b",
                  $time, data_rd, ack_error);
        if (data_rd !== 8'hA5 || ack_error) begin
            $display("   >>> ERROR en la lectura"); errores = errores + 1;
        end

        //---------------- 3) Direccion inexistente -> NACK ------------------------
        $display("\n[%0t ns] ESCRITURA a direccion inexistente 0x23", $time);
        transaccion(7'h23, 1'b0, 8'hFF);
        $display("[%0t ns]   ack_error=%b (se espera 1 = NACK)", $time, ack_error);
        if (!ack_error) begin
            $display("   >>> ERROR: se esperaba NACK"); errores = errores + 1;
        end

        //---------------- Resumen --------------------------------------------------
        if (errores == 0)
            $display("\n=== SIMULACION EXITOSA: todas las pruebas pasaron ===\n");
        else
            $display("\n=== SIMULACION CON %0d ERROR(ES) ===\n", errores);

        $finish;
    end

    // Guardia de tiempo maximo
    initial begin
        #2_000_000;   // 2 ms
        $display(">>> TIMEOUT de simulacion");
        $finish;
    end

endmodule
