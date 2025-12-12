`timescale 1ns / 1ps

//viterbi algorithm 
//first two steps will be hard coded because they have less branches
module viterbi_decoder(
    input logic [15:0]encoded [0:127],
    output logic [7:0]decoded_message [0:127], 
    input logic BMU_en, ACS_en, SPU_en,
    input clk
    );
    genvar i,j;
    genvar index1, index2;
    logic [1:0] symbol;
    logic [1:0] branch_weights [0:7];
    logic [3:0] path_weights [0:10];
    logic [3:0] paths [0:1023];
    
    generate
        for(i = 0; i<128; i++) begin
            for(j = 0; j<8; j++) begin
                  assign index1 = (j*2);
                  assign index2 = (j*2) + 1;
                  assign symbol = {encoded[i][index1],encoded[i][index2]};
                  if(i == 0 && j == 0) begin
                    //first step of trellis
                     branch_metric_unit BMU1(
                        .symbol(symbol),
                        .curr_state(10),
                        .prev_state(00),
                        .en(BMU_en),
                        .clk(clk),
                        .branch_weight(branch_weights[0])
                     );
                     
                     branch_metric_unit BMU2(
                        .symbol(symbol),
                        .curr_state(00),
                        .prev_state(00),
                        .en(BMU_en),
                        .clk(clk),
                        .branch_weight(branch_weights[1])
                     );
                     
                     add_comp_sel ACS1(
                        
                     );
                  end else if(i == 0 && j == 1) begin
                    //second step of trellis
                    
                  end
            end
        end
    endgenerate
endmodule
