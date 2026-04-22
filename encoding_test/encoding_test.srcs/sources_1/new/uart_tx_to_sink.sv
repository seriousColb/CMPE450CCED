`timescale 1ns / 1ps

module uart_tx_to_sink(
    input logic clk,
    input logic reset,
    input logic transmit,
    output logic done,
    output logic txd
    );
    
    
    transmitter DUT(
        .clk(clk),
        .reset(reset),
        .transmit(transmit),
        .data(8'b11110000),
        .TxD(txd),
        .done(done)
    );  
    
    always_ff @(posedge clk) begin
        
    end 
    
endmodule
