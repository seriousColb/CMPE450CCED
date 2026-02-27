`timescale 1ns / 1ps

//this testbench tests a single ACS unit. this was created to take a closer look at why the ACS is not working
module ACS_tb_single;

logic [1:0] rx;
logic [1:0] state;
logic [10:0] path_weight0;
logic [10:0] path_weight1;
logic en;
logic clk;
logic rst;
logic branch_bit0;
logic [10:0] updated_path0;
logic [1:0] bm0; 
logic [1:0] bm1;

bmu bmu0 (
        .rx(rx),
        .curr_state(state),
        .branch_weight0(bm0), //lower branch
        .branch_weight1(bm1)  //upper branch
    );

acs_no_bmu acs0 (
        .rx(rx),
        .curr_state(state),
        .path_weight0(path_weight0),
        .path_weight1(path_weight1),
        .en(en),
        .clk(clk),
        .rst(rst),
        .bm0(bm0),
        .bm1(bm1),
        .branch_bit(branch_bit0),
        .updated_path(updated_path0)
    );
    
initial clk = 0;
always #5 clk = ~clk;

initial begin
    rx = 2'b10;    //received 11
    state = 2'b00; //state 0
    en = 1;
    rst = 0;
    path_weight0 = 2;
    path_weight1 = 1;
    
    #10;
    
    path_weight0 = updated_path0;
    path_weight1 = 2;
    rx = 2'b01;
    
    #10;
    
    path_weight0 = updated_path0;
    path_weight1 = 1;
    rx = 2'b10;
    
    #10;
    
    path_weight0 = updated_path0;
    path_weight1 = 3;
    rx = 2'b10;
    
    #10;
    
    path_weight0 = updated_path0;
    path_weight1 = 2;
    rx = 2'b11;
    
    #10;
    
    $stop;
end

endmodule
