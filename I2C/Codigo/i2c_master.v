//==============================================================================
// i2c_master.v
// Maestro I2C implementado con una Maquina de Estados Finitos (FSM)
//
// - Direccion de 7 bits + bit R/W (0 = escritura, 1 = lectura)
// - Genera las condiciones de START y STOP (como en los diagramas:
//   SDA baja/sube mientras SCL esta en alto)
// - Cada bit de SCL se divide en 4 fases:
//     fase 0: SCL=0 -> se coloca el dato en SDA (SDA solo cambia con SCL bajo)
//     fase 1: SCL=1
//     fase 2: SCL=1 -> se muestrea SDA (dato estable durante SCL alto)
//     fase 3: SCL=0
// - Verifica el bit ACK/NACK del esclavo (ack_error = 1 si recibe NACK)
// - En lectura, el maestro responde NACK tras el byte (lectura de 1 byte)
//
// SDA y SCL son de drenador abierto: el modulo solo fuerza '0' o libera
// la linea ('z'); las resistencias de pull-up (externas o tri1 en el
// testbench) la llevan a '1'.
//==============================================================================
module i2c_master #(
    parameter CLK_FREQ = 50_000_000,   // frecuencia del reloj del sistema
    parameter I2C_FREQ = 100_000       // frecuencia de SCL (100 kHz estandar)
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       start,       // pulso: inicia una transaccion
    input  wire [6:0] addr,        // direccion de 7 bits del esclavo
    input  wire       rw,          // 0 = escribir, 1 = leer
    input  wire [7:0] data_wr,     // byte a escribir
    output reg  [7:0] data_rd,     // byte leido del esclavo
    output reg        busy,        // transaccion en curso
    output reg        done,        // pulso: transaccion terminada
    output reg        ack_error,   // 1 = el esclavo respondio NACK
    inout  wire       sda,
    inout  wire       scl
);

    //-------------------------------------------------------------------------
    // Divisor de reloj: un "tick" por cada cuarto de periodo de SCL
    //-------------------------------------------------------------------------
    localparam integer DIV = CLK_FREQ / (I2C_FREQ * 4);

    reg [15:0] cnt;
    wire tick = (cnt == DIV-1);

    //-------------------------------------------------------------------------
    // Salidas de drenador abierto (1 = liberar linea, 0 = forzar bajo)
    //-------------------------------------------------------------------------
    reg sda_o, scl_o;
    assign sda = sda_o ? 1'bz : 1'b0;
    assign scl = scl_o ? 1'bz : 1'b0;

    //-------------------------------------------------------------------------
    // Estados de la FSM
    //-------------------------------------------------------------------------
    localparam [3:0] ST_IDLE  = 4'd0,   // reposo (SDA=SCL=1)
                     ST_START = 4'd1,   // condicion de START
                     ST_ADDR  = 4'd2,   // envia direccion (7 bits) + R/W
                     ST_ACKA  = 4'd3,   // lee ACK/NACK de la direccion
                     ST_WR    = 4'd4,   // envia byte de datos
                     ST_ACKW  = 4'd5,   // lee ACK/NACK del dato
                     ST_RD    = 4'd6,   // recibe byte de datos
                     ST_MACK  = 4'd7,   // maestro envia NACK (fin de lectura)
                     ST_STOP  = 4'd8;   // condicion de STOP

    reg [3:0] state;
    reg [1:0] phase;      // fase dentro del bit (0..3)
    reg [3:0] bit_cnt;    // contador de bits
    reg [7:0] shifter;    // registro de desplazamiento
    reg       rw_r;       // R/W registrado
    reg       nack;       // ACK muestreado (1 = NACK)

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            cnt <= 0;
        else if (state == ST_IDLE || tick)
            cnt <= 0;
        else
            cnt <= cnt + 1'b1;
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state     <= ST_IDLE;
            sda_o     <= 1'b1;
            scl_o     <= 1'b1;
            busy      <= 1'b0;
            done      <= 1'b0;
            ack_error <= 1'b0;
            phase     <= 2'd0;
            bit_cnt   <= 4'd0;
            data_rd   <= 8'h00;
            shifter   <= 8'h00;
            rw_r      <= 1'b0;
            nack      <= 1'b0;
        end else begin
            done <= 1'b0;                       // 'done' es un pulso de 1 ciclo

            case (state)
            //------------------------------------------------ reposo
            ST_IDLE: begin
                sda_o <= 1'b1;
                scl_o <= 1'b1;
                phase <= 2'd0;
                if (start) begin
                    busy      <= 1'b1;
                    ack_error <= 1'b0;
                    shifter   <= {addr, rw};    // direccion + bit R/W
                    rw_r      <= rw;
                    state     <= ST_START;
                end
            end

            //------------------------------------------------ START:
            // SDA cae mientras SCL permanece en alto
            ST_START: if (tick) begin
                phase <= phase + 1'b1;
                case (phase)
                    2'd0: begin sda_o <= 1'b1; scl_o <= 1'b1; end
                    2'd1: sda_o <= 1'b0;                    // <- START
                    2'd2: ;
                    2'd3: begin
                        scl_o   <= 1'b0;
                        bit_cnt <= 4'd0;
                        state   <= ST_ADDR;
                    end
                endcase
            end

            //------------------------------------------------ direccion + R/W
            ST_ADDR: if (tick) begin
                phase <= phase + 1'b1;
                case (phase)
                    2'd0: sda_o <= shifter[7];  // coloca bit con SCL bajo
                    2'd1: scl_o <= 1'b1;
                    2'd2: ;                     // dato estable con SCL alto
                    2'd3: begin
                        scl_o   <= 1'b0;
                        shifter <= {shifter[6:0], 1'b0};
                        if (bit_cnt == 4'd7) begin
                            bit_cnt <= 4'd0;
                            state   <= ST_ACKA;
                        end else
                            bit_cnt <= bit_cnt + 1'b1;
                    end
                endcase
            end

            //------------------------------------------------ ACK de direccion
            // El maestro libera SDA; el esclavo debe llevarla a 0 (ACK)
            ST_ACKA: if (tick) begin
                phase <= phase + 1'b1;
                case (phase)
                    2'd0: sda_o <= 1'b1;        // libera SDA
                    2'd1: scl_o <= 1'b1;
                    2'd2: nack  <= sda;         // muestrea ACK/NACK
                    2'd3: begin
                        scl_o <= 1'b0;
                        if (nack) begin
                            ack_error <= 1'b1;  // nadie respondio -> STOP
                            state     <= ST_STOP;
                        end else if (rw_r)
                            state <= ST_RD;
                        else begin
                            shifter <= data_wr;
                            state   <= ST_WR;
                        end
                    end
                endcase
            end

            //------------------------------------------------ escritura de byte
            ST_WR: if (tick) begin
                phase <= phase + 1'b1;
                case (phase)
                    2'd0: sda_o <= shifter[7];
                    2'd1: scl_o <= 1'b1;
                    2'd2: ;
                    2'd3: begin
                        scl_o   <= 1'b0;
                        shifter <= {shifter[6:0], 1'b0};
                        if (bit_cnt == 4'd7) begin
                            bit_cnt <= 4'd0;
                            state   <= ST_ACKW;
                        end else
                            bit_cnt <= bit_cnt + 1'b1;
                    end
                endcase
            end

            //------------------------------------------------ ACK del dato
            ST_ACKW: if (tick) begin
                phase <= phase + 1'b1;
                case (phase)
                    2'd0: sda_o <= 1'b1;
                    2'd1: scl_o <= 1'b1;
                    2'd2: nack  <= sda;
                    2'd3: begin
                        scl_o <= 1'b0;
                        if (nack) ack_error <= 1'b1;
                        state <= ST_STOP;       // 1 byte por transaccion
                    end
                endcase
            end

            //------------------------------------------------ lectura de byte
            // El maestro libera SDA y muestrea; el esclavo transmite
            ST_RD: if (tick) begin
                phase <= phase + 1'b1;
                case (phase)
                    2'd0: sda_o <= 1'b1;                     // SDA liberada
                    2'd1: scl_o <= 1'b1;
                    2'd2: shifter <= {shifter[6:0], sda};    // muestrea bit
                    2'd3: begin
                        scl_o <= 1'b0;
                        if (bit_cnt == 4'd7) begin
                            bit_cnt <= 4'd0;
                            data_rd <= shifter;
                            state   <= ST_MACK;
                        end else
                            bit_cnt <= bit_cnt + 1'b1;
                    end
                endcase
            end

            //------------------------------------------------ NACK del maestro
            // Tras el ultimo byte leido, el maestro deja SDA en alto (NACK)
            ST_MACK: if (tick) begin
                phase <= phase + 1'b1;
                case (phase)
                    2'd0: sda_o <= 1'b1;        // NACK (fin de la lectura)
                    2'd1: scl_o <= 1'b1;
                    2'd2: ;
                    2'd3: begin
                        scl_o <= 1'b0;
                        state <= ST_STOP;
                    end
                endcase
            end

            //------------------------------------------------ STOP:
            // SDA sube mientras SCL esta en alto
            ST_STOP: if (tick) begin
                phase <= phase + 1'b1;
                case (phase)
                    2'd0: begin sda_o <= 1'b0; scl_o <= 1'b0; end
                    2'd1: scl_o <= 1'b1;
                    2'd2: sda_o <= 1'b1;        // <- STOP
                    2'd3: begin
                        busy  <= 1'b0;
                        done  <= 1'b1;
                        state <= ST_IDLE;
                    end
                endcase
            end

            default: state <= ST_IDLE;
            endcase
        end
    end

endmodule
