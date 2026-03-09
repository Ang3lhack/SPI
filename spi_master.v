module spi_master #(parameter DATA_WIDTH = 8)(
    input  wire                   clk,       // Reloj del sistema
    input  wire                   rst_n,     // Reset asíncrono activo en bajo
    input  wire                   start,     // Señal de inicio
    input  wire [DATA_WIDTH-1:0]  data_in,   // Datos a transmitir
    input  wire                   miso,      // Entrada de datos del esclavo
    output reg                    sclk,      // Reloj SPI
    output reg                    mosi,      // Salida de datos al esclavo
    output reg                    cs_n,      // Chip Select (activo en bajo)
    output reg  [DATA_WIDTH-1:0]  data_out,  // Datos recibidos
    output reg                    done       // Bandera de transmisión completa
);

    localparam IDLE = 2'b00, SETUP = 2'b01, TRANSFER = 2'b10, DONE = 2'b11;
    reg [1:0] state;
    reg [2:0] bit_cnt;
    reg [DATA_WIDTH-1:0] tx_reg, rx_reg;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE; bit_cnt <= 3'd7; tx_reg <= 0; rx_reg <= 0;
            sclk <= 1'b0; cs_n <= 1'b1; done <= 1'b0; mosi <= 1'b0; data_out <= 0;
        end else begin
            case (state)
                IDLE: begin
                    done <= 1'b0; cs_n <= 1'b1; sclk <= 1'b0;
                    if (start) begin
                        tx_reg <= data_in; cs_n <= 1'b0; state <= SETUP;
                    end
                end
                SETUP: begin
                    mosi <= tx_reg[7]; sclk <= 1'b0; state <= TRANSFER;
                end
                TRANSFER: begin
                    sclk <= ~sclk;
                    if (sclk == 1'b0) rx_reg <= {rx_reg[6:0], miso}; // Sube: Lee
                    else begin // Baja: Escribe
                        tx_reg <= {tx_reg[6:0], 1'b0}; 
                        if (bit_cnt == 0) state <= DONE;
                        else begin bit_cnt <= bit_cnt - 1; state <= SETUP; end
                    end
                end
                DONE: begin
                    cs_n <= 1'b1; sclk <= 1'b0; mosi <= 1'b0; done <= 1'b1;
                    data_out <= rx_reg; bit_cnt <= 3'd7; state <= IDLE;
                end
            endcase
        end
    end
endmodule