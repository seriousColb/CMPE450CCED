`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 03/25/2026 10:46:34 AM
// Design Name: 
// Module Name: encode_and_tx_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module encode_and_tx_top(
    input logic clk,
    input logic en,
    output logic done,
    output logic txd
    );
    
    encode_and_send_FSM DUT(
        .clk(clk),
        .en(en),
        .raw_data(8'b11110000),
        .done(done),
        .txd(txd),
        .led_test(led_test)
    );
    
endmodule
