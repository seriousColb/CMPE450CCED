`timescale 1ns / 1ps
//this file tests sending a byte to the com port on a laptop.

module uart_tx_test(
    input logic clk,
    input logic rst,
    input logic uart_rxd,
    output logic uart_txd
    );
    
    //tx signals
    logic [7:0]uart_tx_data;
    logic uart_tx_valid;
    logic uart_tx_ready;
    
    //rx signals
    logic [7:0]uart_rx_data;
    logic uart_rx_valid;
    logic uart_rx_ready;
    
    uart
    uart_inst (
        .clk(clk),
        .rst(rst),
        // AXI input
        .s_axis_tdata(8'b11110000),
        .s_axis_tvalid(uart_tx_valid),
        .s_axis_tready(uart_tx_ready),
        // AXI output
        .m_axis_tdata(uart_rx_data),
        .m_axis_tvalid(uart_rx_valid),
        .m_axis_tready(uart_rx_ready),
        // uart
        .rxd(uart_rxd),
        .txd(uart_txd),
        // status
        .tx_busy(),
        .rx_busy(),
        .rx_overrun_error(),
        .rx_frame_error(),
        // configuration. Basys 3 clock frequency = 100 MHz
        .prescale(100000000/(9600*8))
    );
    
    always_ff @(posedge clk or posedge rst) begin
        if(rst) begin
            uart_tx_data <= 0;
            uart_tx_valid <= 0;
            uart_rx_ready <= 0;
        end
    
    end
    
endmodule
