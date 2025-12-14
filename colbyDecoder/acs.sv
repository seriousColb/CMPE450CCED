module acs(
    input logic [1:0] rx,
    input logic [1:0] curr_state,
    input logic [10:0] path_weight0,
    input logic [10:0] path_weight1,
    input logic clk,
    input logic en,
    input logic rst,
    output logic branch_bit, //signifies which branch was added to the path. 1 = upper branch, 0 = lower branch
    output logic [10:0] updated_path
    );

    logic [1:0] bm0, //lower path
    logic [1:0] bm1, //upper path

    bmu bmu0(
        .rx(rx),
        .curr_state(curr_state),
        .en(en),
        .clk(clk),
        .branch_weight0(bm0),
        .branch_weight1(bm1)
    );
    
    logic [10:0] path0; //lower path
    logic [10:0] path1; //upper path
    
    always_comb begin
        path0 = path_weight0 + {{9{1'b0}}, bm0};
        path1 = path_weight1 + {{9{1'b0}}, bm1};
    end
    
    always_ff @(posedge clk or posedge rst) begin
        if(rst) begin
            updated_path <= 11'b0;
            branch_bit <= 1'b0;
        end
        else if(en)begin
            //update when enabled
            if(path0 <= path1) begin
                updated_path <= path0[10:0];
                branch_bit <= 1'b0;
            end else begin
                updated_path <= path1[10:0];
                branch_bit <= 1'b1;
            end
        end
        else begin
            updated_path <= updated_path;
            branch_bit <= branch_bit;
        end
        
    end
endmodule