`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/22/2025 10:27:10 AM
// Design Name: 
// Module Name: encoder
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


module shift_register#(parameter K=3)(
    input in,
    input clk,
    input reset,
    output reg shift_reg[K-2:0]
    );
    
    //shifts the register and adds the new bit
    always @(posedge clk)
        if(reset)
            shift_reg <= 0;    
        else begin
            shift_reg <= {in, shift_reg[K-2:1]};
        end
    end
endmodule
