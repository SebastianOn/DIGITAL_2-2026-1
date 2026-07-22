module Teclado(
    input clk,
    input reset,
    input init,
    input C0,
    input C1,
    input C2,
    input C3,
    output  R0,
    output  R1, 
    output  R2,
    output  R3,
    output [5:0] tecla,
    output  done
);

wire w_R0;
wire w_R1;
wire w_R2;
wire w_R3;
wire w_end;
wire w_done;
wire w_kp_rd;

data_tcl data_tcl0(
    .clk(clk),
    .reset(reset),
    .done(w_done),
    .init(init),
    .C0(C0),
    .C1(C1),
    .C2(C2),
    .C3(C3),
    .R0(w_R0),
    .R1(w_R1),
    .R2(w_R2),
    .R3(w_R3),
    .tecla(tecla),
    .end_flag(w_end),
    .rd_flag(w_kp_rd)
);

Control_Teclado ctrl_tcl0(
    .clk(clk),
    .reset(reset),
    .init(init),
    .end_flag(w_end),
    .rd_flag(w_kp_rd),
    .c0(C0),
    .c1(C1),
    .c2(C2),
    .c3(C3),
    .r0(w_R0),
    .r1(w_R1),
    .r2(w_R2),
    .r3(w_R3),
    .done(w_done)
);

assign R0 = w_R0;
assign R1 = w_R1;
assign R2 = w_R2;
assign R3 = w_R3;
assign done = w_done;

endmodule
/*
Este módulo tiene 2 partes , una secuencial que se encarga de leer el teclado
en este, si una fila está activa y al mismo tiempo una columna esta activa, se asigna
un valor a la salida next_tecla.
El modulo combinacional, se encarga de hacer un antirrebote, asegurandose de que el valor
de tecla sea estable durante n ciclos de reloj, en este caso 4000 ciclos,cuando
es así ,se activa la señal end_flag, indicando que el valor de tecla es estable y puede ser leído.
Otra función del modulo combinacional es la de generar la señal rd_flag, la cual indica que
el valor de tecla esta siendo leido evitando que se cabie de estado mientras se asegura que es 
estable. Por último, para evitar que se lea la misma tecla varias veces, se genera la señal unique_flag,
la cual indica que la tecla ya fue leida y no se puede leer hasta que se suelte y se vuelva a presionar.

N es el número de ciclos de reloj que se espera para que la tecla sea estable, en este caso
 4000 ciclos. Debido a que el rebote dura unos 20ms y el periodo del reloj es de 5us,
se necesitan 4000 ciclos para que la tecla sea estable.


*/
module data_tcl #(parameter N = 4000)(
    input clk,
    input reset,
    input done,
    input init,
    input C0,
    input C1,
    input C2,
    input C3,
    input R0,
    input R1,
    input R2,
    input R3,
    output reg [5:0] tecla,
    output reg end_flag,
    output reg rd_flag
);
reg [11:0]unique_flag;
reg [11:0] Antirebote;
reg [5:0] Prev_tecla;
reg [5:0] next_tecla;
reg [5:0] last_tcl;

always @(*) begin
    next_tecla = 6'h0; 
    
    if (R0) begin
        if (C0) next_tecla = 6'h31;
        else if (C1) next_tecla = 6'h32;
        else if (C2) next_tecla = 6'h33;
    end
    else if (R1) begin
        if (C0) next_tecla = 6'h34;
        else if (C1) next_tecla = 6'h35;
        else if (C2) next_tecla = 6'h36;
    end
    else if (R2) begin
        if (C0) next_tecla = 6'h37;
        else if (C1) next_tecla = 6'h38;
        else if (C2) next_tecla = 6'h39;
        else if (C3) next_tecla = 6'h13;
    end
    else if (R3) begin
        if (C0) next_tecla = 42;
        else if (C1) next_tecla = 6'h30;
        else if (C2) next_tecla = 35;
        else if (C3) next_tecla = 47;
    end
end

always @(posedge clk or posedge reset) begin
    if (reset) begin
        Antirebote <= 0;
        Prev_tecla <= 16;
        tecla <= 5'h30;
        unique_flag <= 0;
    end
    else if (done) begin
        Antirebote <= 0;
        Prev_tecla <= 16;
        last_tcl <= tecla;
    end
    else if (init) begin
        Prev_tecla <= 16;
        Antirebote <= 0;
        unique_flag <= N;
    end
    else begin
        if (unique_flag) begin
            // Espera a que la tecla realmente se suelte (next_tecla == 0)
            if (next_tecla == 0) begin
                if (unique_flag > 0) unique_flag <= unique_flag - 1;
            end else begin
                unique_flag <= N; // mantiene el bloqueo mientras siga presionada
            end
        end
        else if (next_tecla == Prev_tecla && next_tecla != 0 && !unique_flag) begin
            if (Antirebote < (N + 1)) Antirebote <= Antirebote + 1;
            //if (Prev_tecla == last_tcl) unique_flag <= 200;
        end
        else Antirebote <= 0;
        Prev_tecla <= next_tecla;
        tecla <= next_tecla;
    end  
end

always @(*) begin
    end_flag = (Antirebote > N) ? 1 : 0; 
    rd_flag = Antirebote? 1 : 0;
end

endmodule

/*

Este es el módulo de control del teclado, el cual se encarga de activar las filas del
teclado y leer las columnas.
Posible estados: START, Row0, Row1, Row2, Row3, READ
START: Estado inicial, espera a que se active la señal init para pasar al estado Row0
Row0: Activa la fila 0 y pasa al estado READ
Row1: Activa la fila 1 y pasa al estado READ
Row2: Activa la fila 2 y pasa al estado READ
Row3: Activa la fila 3 y pasa al estado READ
READ: Espera a que se acabe el contador para pasar a la siguiente fila, si se ha detectado
un tecla presionada (read_flag = 1) se mantiene en el estado READ hasta que se suelte la tecla,
si no se ha detectado sigue a la siguiente fila, si se ha llegado a la fila 3 pasa a la fila 0.
*/
module Control_Teclado(
    input clk,
    input reset,
    input init,
    input end_flag,
    input rd_flag,    // from data_tcl (posedge domain)
    input c0,
    input c1,
    input c2,
    input c3,
    output reg r0,
    output reg r1,
    output reg r2,
    output reg r3,
    output reg done
);

parameter START = 3'b000,
          Row0  = 3'b001, 
          Row1  = 3'b010, 
          Row2  = 3'b011,
          Row3  = 3'b100, 
          READ  = 3'b101;
          
reg [2:0] state;
reg [2:0] prev_row;
reg [2:0] cnt;              
reg rd_flag_sync;           

always @(negedge clk or posedge reset) begin
    if (reset) begin
        rd_flag_sync <= 1'b0;
    end
    else begin
        rd_flag_sync <= rd_flag;
    end
end

always @(negedge clk or posedge reset) begin
    if (reset) begin
        state <= START;
        prev_row <= 3'd5;
        cnt <= 0;
    end
    else begin 
        case (state)
            START: begin
                if (init) state <= Row0;
                else state <= START;
                prev_row <= 3'd5;
                cnt <= 0;
            end
            
            Row0: begin
                state <= READ;
                prev_row <= 3'd0;
                cnt <= 3'd5;
            end
            
            Row1: begin
                state <= READ;
                prev_row <= 3'd1;
                cnt <= 3'd5;
            end
            
            Row2: begin
                state <= READ;
                prev_row <= 3'd2;
                cnt <= 3'd5;
            end
            
            Row3: begin
                state <= READ;
                prev_row <= 3'd3;
                cnt <= 3'd5;
            end
            
            READ: begin
                if (end_flag) state <= START;
                else begin
                    if (!cnt) begin
                        case (prev_row)
                            0: if (rd_flag_sync) state <= READ; else state <= Row1;
                            1: if (rd_flag_sync) state <= READ; else state <= Row2;
                            2: if (rd_flag_sync) state <= READ; else state <= Row3;
                            3: if (rd_flag_sync) state <= READ; else state <= Row0;
                            default: state <= START;
                        endcase
                    end
                    else begin
                        cnt <= cnt - 1'b1;
                        state <= READ;
                    end
                end
            end
            
            default: state <= START;
        endcase
    end
end

always @(*) begin
    case (state)
        START: begin     
            r0 = 0; r1 = 0; r2 = 0; r3 = 0; done = 1;
        end

        Row0: begin r0 = 1; r1 = 0; r2 = 0; r3 = 0; done = 0; end
        Row1: begin r0 = 0; r1 = 1; r2 = 0; r3 = 0; done = 0; end
        Row2: begin r0 = 0; r1 = 0; r2 = 1; r3 = 0; done = 0; end  
        Row3: begin r0 = 0; r1 = 0; r2 = 0; r3 = 1; done = 0; end
        
        READ: begin
            done = 0;
            case (prev_row)
                0: begin r0 = 1; r1 = 0; r2 = 0; r3 = 0; end
                1: begin r0 = 0; r1 = 1; r2 = 0; r3 = 0; end
                2: begin r0 = 0; r1 = 0; r2 = 1; r3 = 0; end
                3: begin r0 = 0; r1 = 0; r2 = 0; r3 = 1; end
                default: begin r0 = 0; r1 = 0; r2 = 0; r3 = 0; end
            endcase
        end
        
        default: begin r0 = 0; r1 = 0; r2 = 0; r3 = 0; done = 1; end
    endcase
end

endmodule
