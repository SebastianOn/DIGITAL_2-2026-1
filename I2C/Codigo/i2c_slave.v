//==============================================================================
// i2c_slave.v
// Esclavo I2C implementado con una Maquina de Estados Finitos (FSM)
//
// - Detecta las condiciones de START y STOP observando SDA mientras SCL=1
// - Recibe la direccion de 7 bits + bit R/W y responde ACK si coincide
//   con su parametro ADDR (como en el diagrama: el ACK lo genera el esclavo)
// - Escritura del maestro : recibe bytes (D7..D0) y responde ACK tras cada uno
// - Lectura del maestro   : transmite 'data_tx' bit a bit y revisa el
//   ACK/NACK del maestro (NACK = fin de la lectura)
// - SDA cambia solo con SCL bajo y se muestrea en el flanco de subida de SCL
//   (el dato permanece estable durante el pulso alto de SCL)
//
// El esclavo NO genera SCL (no implementa clock stretching); solo lo observa.
//==============================================================================
module i2c_slave #(
    parameter [6:0] ADDR = 7'b1100100    // 0x64, como en el diagrama (1100100x)
)(
    input  wire       clk,        // reloj del sistema (para sincronizar)
    input  wire       rst_n,
    input  wire       scl,        // el esclavo solo escucha SCL
    inout  wire       sda,
    input  wire [7:0] data_tx,    // byte que enviara cuando el maestro lea
    output reg  [7:0] data_rx,    // ultimo byte recibido del maestro
    output reg        rx_valid    // pulso: 'data_rx' es valido
);

    //-------------------------------------------------------------------------
    // Salida de drenador abierto
    //-------------------------------------------------------------------------
    reg sda_o;
    assign sda = sda_o ? 1'bz : 1'b0;

    //-------------------------------------------------------------------------
    // Sincronizadores y deteccion de flancos / condiciones START-STOP
    //-------------------------------------------------------------------------
    reg [2:0] scl_s, sda_s;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            scl_s <= 3'b111;
            sda_s <= 3'b111;
        end else begin
            scl_s <= {scl_s[1:0], scl};
            sda_s <= {sda_s[1:0], sda};
        end
    end

    wire scl_rise = (scl_s[2:1] == 2'b01);                 // flanco subida SCL
    wire scl_fall = (scl_s[2:1] == 2'b10);                 // flanco bajada SCL
    wire start_c  = scl_s[2] & scl_s[1] &  sda_s[2] & ~sda_s[1]; // SDA cae, SCL=1
    wire stop_c   = scl_s[2] & scl_s[1] & ~sda_s[2] &  sda_s[1]; // SDA sube, SCL=1

    //-------------------------------------------------------------------------
    // Estados de la FSM
    //-------------------------------------------------------------------------
    localparam [2:0] S_IDLE = 3'd0,   // espera condicion de START
                     S_ADDR = 3'd1,   // recibe direccion + R/W
                     S_ACKA = 3'd2,   // genera ACK de direccion
                     S_RX   = 3'd3,   // recibe byte de datos (maestro escribe)
                     S_ACKR = 3'd4,   // genera ACK del dato recibido
                     S_TX   = 3'd5,   // transmite byte de datos (maestro lee)
                     S_ACKM = 3'd6,   // lee ACK/NACK del maestro
                     S_WAIT = 3'd7;   // ignora el bus hasta STOP/START

    reg [2:0] st;
    reg [3:0] bit_cnt;
    reg [7:0] sh;         // registro de desplazamiento
    reg       rw;         // bit R/W recibido
    reg       mack;       // ACK/NACK muestreado del maestro

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            st       <= S_IDLE;
            sda_o    <= 1'b1;
            bit_cnt  <= 4'd0;
            sh       <= 8'h00;
            rw       <= 1'b0;
            mack     <= 1'b1;
            data_rx  <= 8'h00;
            rx_valid <= 1'b0;
        end else begin
            rx_valid <= 1'b0;                  // pulso de 1 ciclo

            if (start_c) begin                 // START (o START repetido)
                st      <= S_ADDR;
                bit_cnt <= 4'd0;
                sda_o   <= 1'b1;
            end else if (stop_c) begin         // STOP -> reposo
                st    <= S_IDLE;
                sda_o <= 1'b1;
            end else begin
                case (st)
                //-------------------------------------------- reposo
                S_IDLE: sda_o <= 1'b1;

                //-------------------------------------------- direccion + R/W
                S_ADDR: begin
                    if (scl_rise) begin
                        sh      <= {sh[6:0], sda_s[1]};    // muestrea con SCL=1
                        bit_cnt <= bit_cnt + 1'b1;
                    end else if (scl_fall && bit_cnt == 4'd8) begin
                        if (sh[7:1] == ADDR) begin         // ¿es para mi?
                            rw    <= sh[0];
                            sda_o <= 1'b0;                 // ACK (SDA a 0)
                            st    <= S_ACKA;
                        end else
                            st <= S_WAIT;                  // no es mi direccion
                    end
                end

                //-------------------------------------------- fin del ACK addr
                S_ACKA: if (scl_fall) begin
                    bit_cnt <= 4'd0;
                    if (rw) begin                          // maestro LEE
                        sh    <= data_tx;
                        sda_o <= data_tx[7];               // coloca D7
                        st    <= S_TX;
                    end else begin                         // maestro ESCRIBE
                        sda_o <= 1'b1;                     // libera SDA
                        st    <= S_RX;
                    end
                end

                //-------------------------------------------- recepcion de byte
                S_RX: begin
                    if (scl_rise) begin
                        sh      <= {sh[6:0], sda_s[1]};
                        bit_cnt <= bit_cnt + 1'b1;
                    end else if (scl_fall && bit_cnt == 4'd8) begin
                        data_rx  <= sh;
                        rx_valid <= 1'b1;
                        sda_o    <= 1'b0;                  // ACK
                        bit_cnt  <= 4'd0;
                        st       <= S_ACKR;
                    end
                end

                //-------------------------------------------- fin del ACK dato
                S_ACKR: if (scl_fall) begin
                    sda_o <= 1'b1;                         // libera SDA
                    st    <= S_RX;                         // admite mas bytes
                end

                //-------------------------------------------- transmision de byte
                S_TX: begin
                    if (scl_rise)
                        bit_cnt <= bit_cnt + 1'b1;
                    else if (scl_fall) begin
                        if (bit_cnt == 4'd8) begin
                            sda_o   <= 1'b1;               // libera para ACK
                            bit_cnt <= 4'd0;
                            st      <= S_ACKM;
                        end else begin
                            sda_o <= sh[6];                // siguiente bit
                            sh    <= {sh[6:0], 1'b0};
                        end
                    end
                end

                //-------------------------------------------- ACK/NACK maestro
                S_ACKM: begin
                    if (scl_rise)
                        mack <= sda_s[1];                  // 0=ACK, 1=NACK
                    else if (scl_fall) begin
                        if (mack == 1'b0) begin            // ACK -> otro byte
                            sh    <= data_tx;
                            sda_o <= data_tx[7];
                            st    <= S_TX;
                        end else begin                     // NACK -> terminar
                            sda_o <= 1'b1;
                            st    <= S_WAIT;
                        end
                    end
                end

                //-------------------------------------------- espera STOP
                S_WAIT: sda_o <= 1'b1;

                default: st <= S_IDLE;
                endcase
            end
        end
    end

endmodule
