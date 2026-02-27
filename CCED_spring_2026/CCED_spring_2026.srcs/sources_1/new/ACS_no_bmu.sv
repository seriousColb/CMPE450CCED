`timescale 1ns / 1ps

module acs_no_bmu(
    input logic [1:0] rx,
    input logic [1:0] curr_state,
    input logic [10:0] path_weight0, //lower path weight 
    input logic [10:0] path_weight1, //upper path weight
    input logic en,
    input logic clk,
    input logic rst,
    input logic [1:0] bm0, //lower branch metric
    input logic [1:0] bm1,
    output logic branch_bit, //signifies which branch was added to the path. 1 = upper branch, 0 = lower branch
    output logic [10:0] updated_path
    );

    
    logic [10:0] path0; //lower path
    logic [10:0] path1; //upper path
    
    //update path weight combinationally    
    always_comb begin
        path0 = path_weight0 + {{9{1'b0}}, bm0}; //the branch metric has to be concatenated with 9 bits of 0's, so it can be added to the 11 bit number
        path1 = path_weight1 + {{9{1'b0}}, bm1};
    end
    
    always_ff @(posedge clk or posedge rst) begin
        if(rst) begin
            updated_path <= 11'b0;
            branch_bit <= 1'b0;
        end
        else if(en)begin
            //update when enabled
            if(path0 < path1) begin
                updated_path <= path0[10:0];
                branch_bit <= 1'b0;
            end else if(path1 < path0)  begin
                updated_path <= path1[10:0];
                branch_bit <= 1'b1;
            end else begin
                updated_path <= path1[10:0];
                branch_bit <= branch_bit;
             end
        end
        else begin
            updated_path <= updated_path;
            branch_bit <= branch_bit;
        end
        
    end
endmodule
