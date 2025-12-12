`timescale 1ns / 1ps

//viterbi algorithm 
//first two steps will be hard coded because they have less branches
module viterbi_decoder(
    input logic [15:0]encoded [0:127],
    output logic [7:0]decoded_message [0:127], 
    input clk
    );
    genvar i,j;
    int index1, index2;
    logic [1:0] symbol;
    
    generate
        for(i = 0; i<128; i++) begin
            for(j = 0; j<8; j++) begin
                  assign index1 = (j*2);
                  assign index2 = (j*2) + 1;
                  assign symbol = {encoded[i][index1],encoded[i][index2]};
            end
        end
    endgenerate
endmodule
