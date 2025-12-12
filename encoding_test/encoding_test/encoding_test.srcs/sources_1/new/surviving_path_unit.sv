`timescale 1ns / 1ps

//takes in the 4 surviving paths at the end of the traceback depth and outputs the one with the lowest weight
module surviving_path_unit(
    input logic [10:0] path_weight1,
    input logic [10:0] path_weight2,
    input logic [10:0] path_weight3,
    input logic [10:0] path_weight4,
    input logic clk,
    input logic en,
    output logic [1:0] path_choice
    );
    
    logic [10:0] min_12, min_34, min_all;

    always_comb begin
        min_12  = (path_weight1 < path_weight2) ? path_weight1 : path_weight2;
        min_34  = (path_weight3 < path_weight4) ? path_weight3 : path_weight4;
        min_all = (min_12 < min_34) ? min_12 : min_34;
    end
    
    always_ff @(posedge clk or posedge en) begin
        if(en) begin
            if(min_all == path_weight1)
                path_choice <= 00;
            else if(min_all == path_weight2)
                path_choice <= 01;
            else if(min_all == path_weight3)
                path_choice <= 10;
            else if(min_all == path_weight4)
                path_choice <= 11;
            else
                //should never get here. need it to avoid an inferred latch
                path_choice <= path_choice;
        end else begin
            path_choice <= path_choice;
        end
    end
endmodule

