`timescale 1ns / 1ps

module encode_and_tx_top(
    input logic clk,
    input logic en,
    output logic done,
    output logic txd,
    output logic led_test1,
    output logic led_test2,
    output logic led_test3,
    output logic led_test4
    );
    
    encode_and_send_FSM #(.DATA_BITS(1024))DUT (
        .clk(clk),
        .en(en),
        .raw_data(1024'b1),
        .done(done),
        .txd(txd),
        .led_test1(led_test1),
        .led_test2(led_test2),
        .led_test3(led_test3),
        .led_test4(led_test4)
    );
    
endmodule
