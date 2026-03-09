module spi_slave #(parameter DATA_WIDTH = 8)(
    input  wire                   rst_n,     
    input  wire                   sclk,      
    input  wire                   cs_n,      
    input  wire                   mosi,      
    input  wire [DATA_WIDTH-1:0]  data_in,   
    output reg                    miso,      
    output reg  [DATA_WIDTH-1:0]  data_out,  
    output reg                    done       
);
    reg [2:0] bit_cnt;
    reg [DATA_WIDTH-1:0] rx_reg, tx_reg;

    always @(posedge sclk or posedge cs_n or negedge rst_n) begin
        if (!rst_n) begin bit_cnt <= 3'd7; rx_reg <= 0; data_out <= 0; done <= 1'b0; end 
        else if (cs_n) begin bit_cnt <= 3'd7; done <= 1'b0; end 
        else begin
            rx_reg <= {rx_reg[6:0], mosi};
            if (bit_cnt == 0) begin data_out <= {rx_reg[6:0], mosi}; done <= 1'b1; end 
            else begin bit_cnt <= bit_cnt - 1; done <= 1'b0; end
        end
    end

    always @(negedge sclk or posedge cs_n or negedge rst_n) begin
        if (!rst_n) begin tx_reg <= 0; miso <= 1'bZ; end 
        else if (cs_n) begin tx_reg <= data_in; miso <= 1'bZ; end 
        else begin miso <= tx_reg[7]; tx_reg <= {tx_reg[6:0], 1'b0}; end
    end
endmodule