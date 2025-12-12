`timescale 1ns / 1ps

//takes in previous path weight for state, both branch weights
//outputs new path weight 
module add_comp_sel(
    input logic [10:0] path_weight,
    input logic [1:0] branch1, //upper path
    input logic [1:0] branch2, //lower path
    input logic clk,
    input logic en,
    output logic branch_bit, //signifies which branch was added to the path. 1 = upper branch, 0 = lower branch
    output logic [10:0] updated_path
    );
    
    logic [10:0] path1; //upper path
    logic [10:0] path2; //lower path
    
    always_comb begin
        path1 = path_weight;
        path2 = path_weight;
        path1 += branch1;
        path2 += branch2;
    end
    
    always_ff @(posedge clk or posedge en) begin
        if(en) 
            //update when enabled
            if(path1 < path2) begin
                updated_path <= path1;
                branch_bit <= 1;
            end else begin
                updated_path <= path2;
                branch_bit <= 0;
            end
        else begin
            updated_path <= path_weight;
        end
    end
endmodule
