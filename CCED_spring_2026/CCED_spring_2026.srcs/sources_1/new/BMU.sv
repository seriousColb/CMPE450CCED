`timescale 1ns / 1ps

module bmu(
    input logic [1:0]rx,
    input logic [1:0]curr_state,
    output logic [1:0]branch_weight0,
    output logic [1:0]branch_weight1
    );

    logic [1:0]enc0; //expected encoder output for lower branch
    logic [1:0]enc1; //expected encoder output for upper branch

    logic [1:0]hamming_weight0;
    logic [1:0]hamming_weight1;

    // Determine expected encoder outputs based on current state
    always_comb begin
        // No inferred latches here...
        enc0 = 2'b00;
        enc1 = 2'b00;

        case (curr_state)
            2'b00: begin enc0 = 2'b00; enc1 = 2'b11;/*
                branch_weight0 = (rx[0] ^ enc0[0]) + (rx[1] ^ enc0[1]);

                branch_weight1 = (rx[0] ^ enc1[0]) + (rx[1] ^ enc1[1]);*/
            end
            2'b10: begin enc0 = 2'b11; enc1 = 2'b00; /*
                branch_weight0 = (rx[0] ^ enc0[0]) + (rx[1] ^ enc0[1]);

                branch_weight1 = (rx[0] ^ enc1[0]) + (rx[1] ^ enc1[1]);*/
            end
            2'b01: begin enc0 = 2'b10; enc1 = 2'b01; /*
                branch_weight0 = (rx[0] ^ enc0[0]) + (rx[1] ^ enc0[1]);

                branch_weight1 = (rx[0] ^ enc1[0]) + (rx[1] ^ enc1[1]);*/
            end
            2'b11: begin enc0 = 2'b01; enc1 = 2'b10; /*
                branch_weight0 = (rx[0] ^ enc0[0]) + (rx[1] ^ enc0[1]);

                branch_weight1 = (rx[0] ^ enc1[0]) + (rx[1] ^ enc1[1]);*/
            end
        endcase
    end

    // Hamming distance
    
    always_comb begin
        branch_weight0 =
            (rx[0] ^ enc0[0]) + (rx[1] ^ enc0[1]);

        branch_weight1 =
            (rx[0] ^ enc1[0]) + (rx[1] ^ enc1[1]);
    end
    
endmodule
