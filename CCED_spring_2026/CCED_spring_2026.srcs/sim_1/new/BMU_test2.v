`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02/11/2026 11:31:08 AM
// Design Name: 
// Module Name: BMU_tb
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


//this testbench is used to test and verify 4 branch metric units in parallel. it is meant to simulate the branch metric calculation of all 4 nodes in a single trellis step.
module BMU_tb;

    logic [1:0]rx;
    //logic[1:0] curr_state;
    logic [1:0]branch_weight0;
    logic [1:0]branch_weight1;
    logic [1:0]branch_weight2;
    logic [1:0]branch_weight3;
    logic [1:0]branch_weight4;
    logic [1:0]branch_weight5;
    logic [1:0]branch_weight6;
    logic [1:0]branch_weight7;

    BMU bmu0 (
        .rx(rx),
        .curr_state(2'b00),
        .branch_weight0(branch_weight0), //lower branch
        .branch_weight1(branch_weight1)  //upper branch
    );
    
    BMU bmu1 (
        .rx(rx),
        .curr_state(2'b10),
        .branch_weight0(branch_weight2), //lower branch
        .branch_weight1(branch_weight3)  //upper branch
    );
    
    BMU bmu2 (
        .rx(rx),
        .curr_state(2'b01),
        .branch_weight0(branch_weight4), //lower branch
        .branch_weight1(branch_weight5)  //upper branch
    );
    
    BMU bmu3 (
        .rx(rx),
        .curr_state(2'b11),
        .branch_weight0(branch_weight6), //lower branch
        .branch_weight1(branch_weight7)  //upper branch
    );
    
    //test stimulus
    initial begin
        rx = 2'b00;
        #10;
        rx = 2'b01;
        #10;
        rx = 2'b10;
        #10;
        rx = 2'b11;
    end
endmodule

module BMU_test2(

    );
endmodule
