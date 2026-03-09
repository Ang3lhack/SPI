`timescale 1ns / 1ps
module tb_spi_system();
    parameter DATA_WIDTH = 8, CLK_PERIOD = 10;
    
    reg clk, rst_n, start;
    reg [DATA_WIDTH-1:0] master_data_in, slave_data_in;
    wire [DATA_WIDTH-1:0] master_data_out, slave_data_out;
    wire master_done, slave_done, sclk, cs_n, mosi, miso;

    spi_master #(.DATA_WIDTH(DATA_WIDTH)) u_master (
        .clk(clk), .rst_n(rst_n), .start(start), .data_in(master_data_in), 
        .miso(miso), .sclk(sclk), .mosi(mosi), .cs_n(cs_n), 
        .data_out(master_data_out), .done(master_done)
    );

    spi_slave #(.DATA_WIDTH(DATA_WIDTH)) u_slave (
        .rst_n(rst_n), .sclk(sclk), .cs_n(cs_n), .mosi(mosi), 
        .data_in(slave_data_in), .miso(miso), .data_out(slave_data_out), .done(slave_done)
    );

    always #(CLK_PERIOD/2) clk = ~clk;

    initial begin
        clk = 0; rst_n = 0; start = 0; master_data_in = 0; slave_data_in = 0;
        
        // PRUEBA 1: Reset
        #(CLK_PERIOD * 2); rst_n = 1; #(CLK_PERIOD * 2);
        
        // PRUEBA 2: Envío de byte aleatorio (Full-Duplex)
        master_data_in = 8'hA5; slave_data_in = 8'h3C;
        start = 1; #(CLK_PERIOD); start = 0;
        wait(master_done == 1'b1); #(CLK_PERIOD);
        
        // PRUEBA 3: Continuidad (Otro envío)
        #(CLK_PERIOD * 5);
        master_data_in = 8'h55; slave_data_in = 8'hAA;
        start = 1; #(CLK_PERIOD); start = 0;
        wait(master_done == 1'b1); #(CLK_PERIOD);
        
        #(CLK_PERIOD * 10); $finish;
    end
endmodule