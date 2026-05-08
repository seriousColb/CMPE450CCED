`timescale 1ns / 1ps

module encode_and_tx_top(
    input logic clk,
    input logic en,
    output logic done,
    output logic txd
    );
    
    logic [1023:0]raw_data = '1;
    
    encode_and_send_FSM #(.DATA_BITS(1024))DUT (
        .clk(clk),
        .en(en),
        .raw_data(raw_data),
        .done(done),
        .txd(txd)
    );
    
endmodule
