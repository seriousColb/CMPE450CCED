`timescale 1ns / 1ps

module uart_tx_to_sink(
    input logic clk,
    input logic reset,
    input logic transmit,
    output logic txd
    );
    
    logic done;
    
    transmitter DUT(
        .clk(clk),
        .reset(reset),
        .transmit(transmit),
        .data(8'b11110000),
        .TxD(txd),
        .done(done)
    );   
    
endmodule
