`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/03/2025 10:46:39 AM
// Design Name: 
// Module Name: encode
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

//encoder for K=3
module encode#(parameter K=3)(
    input logic in,
    input logic [K-2:0]shift_reg,
    output logic out1,
    output logic out2
    );
    
    always_comb begin
        out1 = shift_reg[0] ^ shift_reg[1] ^ in;
        out2 = shift_reg[1] ^ in;
    end
endmodule
