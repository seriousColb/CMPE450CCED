`timescale 1ns / 1ps

module encode_and_tx_top(
    input logic clk,
    input logic en,
    output logic done,
    output logic txd
    );
    
    encode_and_send_FSM #(.DATA_BITS(1024))DUT (
        .clk(clk),
        .en(en),
        .raw_data(1024'b1),
        .done(done),
        .txd(txd)
    );
    
endmodule
