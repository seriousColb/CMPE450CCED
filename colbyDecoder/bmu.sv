`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/14/2025 11:25:06 AM
// Design Name: 
// Module Name: bmu
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


module bmu #(parameter K =3)(
    input logic [1:0] rx,
    input logic [K-2:0] curr_state,
    output logic [1:0] branch_weight0,
    output logic [1:0] branch_weight1
    );
    
    logic [1:0] enc0; //expected encoder output for lower branch
    logic [1:0] enc1; //expected encoder output for upper branch
    
    logic [K-1:0]reg0;
    logic [K-1:0]reg1;
    
    always_comb begin
        //No inferred latches
        enc0 = 2'b00;
        enc1 = 2'b00;
        //Cancatenate possible inputs on curr_state
        reg0 = {1'b0, curr_state};
        reg1 = {1'b1, curr_state};
        //Calculate next possible encoded states
        case(K)
            7: begin
            //if 0 is received
                enc0[0] = reg0[6] ^ reg0[4] ^ reg0[3] ^ reg0[1] ^ reg0[0];
                enc0[1] = reg0[6] ^ reg0[5] ^ reg0[4] ^ reg0[3] ^ reg0[0];
            //if 1 is received
                enc1[0] = reg1[6]^reg1[4]^reg1[3]^reg1[1]^reg1[0];
                enc1[1] = reg1[6]^reg1[5]^reg1[4]^reg1[3]^reg1[0];
            end
            5: begin
            //if 0 is received
                enc0[0] = reg0[4] ^ reg0[3] ^ reg0[1] ^ reg0[0];
                enc0[1] = reg0[4] ^ reg0[3] ^ reg0[2] ^ reg0[1] ^ reg0[0];
            //if 1 is received
                enc1[0] = reg1[4] ^ reg1[3] ^ reg1[1] ^ reg1[0];
                enc1[1] = reg1[4] ^ reg1[3] ^ reg1[2] ^ reg1[1] ^ reg1[0];
            end
            4: begin
            //if 0 is received
                enc0[0] = reg0[3] ^ reg0[1] ^ reg0[0];
                enc0[1] = reg0[3] ^ reg0[2] ^ reg0[1] ^ reg0[0];
            //if 1 is received
                enc1[0] = reg1[3] ^ reg1[1] ^ reg1[0];
                enc1[1] = reg1[3] ^ reg1[2] ^ reg1[1] ^ reg1[0];
            end
            default begin
            //if 0 is received
                enc0[0] = reg0[2] ^ reg0[0]; 
                enc0[1] = reg0[2] ^ reg0[1] ^ reg0[0];
            //if 1 is received
                enc1[0] = reg1[2] ^ reg1[0]; 
                enc1[1] = reg1[2] ^ reg1[1] ^ reg1[0];
            end
        endcase
        //Calculate branch weights        
        branch_weight0 = (rx[0]^enc0[0]) + (rx[1]^enc0[1]);
        branch_weight1 = (rx[0]^enc1[0]) + (rx[1]^enc1[1]);        
    
    end
endmodule
