`timescale 1ns / 1ps

//this testbench will test 4 ACS units in parallel. it well simulate 5 trellis steps to get the path weights for the following data:
//Encoded =  11 01 10 01 00 10 11
//Received = 11 11 10 01 10 10 11
//the first 2 trellis steps will be ignored
module ACS_tb;
    //ACS inputs
    logic [1:0] rx;
    //logic [1:0] curr_state;
    logic [10:0] path_weight0;
    logic [10:0] path_weight1;
    logic [10:0] path_weight2;
    logic [10:0] path_weight3;
    logic en;
    logic clk;
    logic rst;
    
    //ACS outputs 
    logic branch_bit0; //indicates which branch was taken. traceback these to get the actual path
    logic branch_bit1;
    logic branch_bit2;
    logic branch_bit3;
    logic [10:0] updated_path0;
    logic [10:0] updated_path1;
    logic [10:0] updated_path2;
    logic [10:0] updated_path3;
    
    acs acs0 (
        .rx(rx),
        .curr_state(2'b00),
        .path_weight0(path_weight0),
        .path_weight1(path_weight2),
        .en(en),
        .clk(clk),
        .rst(rst),
        .branch_bit(branch_bit0),
        .updated_path(updated_path0)
    );
    
    acs acs1 (
        .rx(rx),
        .curr_state(2'b10),
        .path_weight0(path_weight0),
        .path_weight1(path_weight2),
        .en(en),
        .clk(clk),
        .rst(rst),
        .branch_bit(branch_bit1),
        .updated_path(updated_path1)
    );
    
    acs acs2 (
        .rx(rx),
        .curr_state(2'b01),
        .path_weight0(path_weight1),
        .path_weight1(path_weight3),
        .en(en),
        .clk(clk),
        .rst(rst),
        .branch_bit(branch_bit2),
        .updated_path(updated_path2)
    );
    
    acs acs3 (
        .rx(rx),
        .curr_state(2'b11),
        .path_weight0(path_weight1),
        .path_weight1(path_weight3),
        .en(en),
        .clk(clk),
        .rst(rst),
        .branch_bit(branch_bit3),
        .updated_path(updated_path3)
    );
    
    initial clk = 0;
    always #5 clk = ~clk;
    
    logic [10:0] trellis_step; //this variable is just to keep track of which trellis step we are at
    
    initial begin
        //initialize inputs
        path_weight0 = 2;
        path_weight1 = 0;
        path_weight2 = 1;
        path_weight3 = 1;
        en = 1;
        rst = 0;
        rx = 2'b10;
        trellis_step = 1;
        
        #10;
        
        //path weights have to be updated before next acs cycle
        path_weight0 = updated_path0;
        path_weight1 = updated_path1;
        path_weight2 = updated_path2;
        path_weight3 = updated_path3;
        rx = 2'b01;
        trellis_step = 2;
        
        #10;
        
        path_weight0 = updated_path0;
        path_weight1 = updated_path1;
        path_weight2 = updated_path2;
        path_weight3 = updated_path3;
        rx = 2'b10;
        trellis_step = 3;
        
        #10;
        
        path_weight0 = updated_path0;
        path_weight1 = updated_path1;
        path_weight2 = updated_path2;
        path_weight3 = updated_path3;
        rx = 2'b10;
        trellis_step = 4;
        
        #10;
        
        path_weight0 = updated_path0;
        path_weight1 = updated_path1;
        path_weight2 = updated_path2;
        path_weight3 = updated_path3;
        rx = 2'b11;
        trellis_step = 5;
        
        #10;
        
        //final update required
        path_weight0 = updated_path0;
        path_weight1 = updated_path1;
        path_weight2 = updated_path2;
        path_weight3 = updated_path3;
                 
        #10;
        
        $stop;
    end    
endmodule
