//This is the branch metric unit. It takes in as inputs the current state, the
//previous state and the encoded symbol at that trellis step. It outputs the hamming
//distance between the symbol and the output of the given state transition.

//possible previous states given state 3 - state 1 and state 3
//possible previous states given state 2 - state 1 and state 3
//possible previous states given state 1 - state 0 and state 2
//possible previous states given state 0 - state 0 and state 2
module branch_metric_unit(
    input logic [1:0]symbol, //2 bit encoded symbol
    input logic [1:0]curr_state,
    input logic [1:0]prev_state,
    input logic en,
    input logic clk,
    output logic [1:0]branch_weight
    );
    logic [1:0]state0_prev[0:1] = {00,11}; //store possible transition outputs given state 0. index 0 corresponds to the transition 0 -> 0 while index 1 corresponds to 2 -> 0
    logic [1:0]state1_prev[0:1] = {11,11};
    logic [1:0]state2_prev[0:1] = {10,01};
    logic [1:0]state3_prev[0:1] = {01,10};
    
    logic [1:0]compared_val;
    logic [1:0]hamming_weight;
    
    //combinational block that calculates the hamming weight
    always_comb begin
        if(curr_state == 00)begin //state 0
            if(prev_state == 00)begin
                //transition 0 -> 0
                compared_val = symbol ^ state0_prev[0];
                hamming_weight = compared_val[0] + compared_val[1];
            end else if(prev_state == 01)begin //state 2 = 01
                //transition 2 -> 0
                compared_val = symbol ^ state0_prev[1];
                hamming_weight = compared_val[0] + compared_val[1];
            end
        end else if(curr_state == 10)begin //state 1 == 10 
            if(prev_state == 00)begin
                //transition 0 -> 1
                compared_val = symbol ^ state1_prev[0];
                hamming_weight = compared_val[0] + compared_val[1];
            end else if(prev_state == 01)begin
                //transition 2 -> 1
                compared_val = symbol ^ state1_prev[1];
                hamming_weight = compared_val[0] + compared_val[1];
            end
        end else if(curr_state == 01)begin //state 2 
            if(prev_state == 10)begin
                //transition 1 -> 2
                compared_val = symbol ^ state2_prev[0];
                hamming_weight = compared_val[0] + compared_val[1];
            end else if(prev_state == 11)begin
                //transition 3 -> 2
                compared_val = symbol ^ state2_prev[1];
                hamming_weight = compared_val[0] + compared_val[1];
            end
        end else if(curr_state == 11)begin //state 3
            if(prev_state == 10)begin
                //transition 1 -> 3
                compared_val = symbol ^ state3_prev[0];
                hamming_weight = compared_val[0] + compared_val[1];
            end else if(prev_state == 11)begin
                //transition 3 -> 3
                compared_val = symbol ^ state3_prev[1];
                hamming_weight = compared_val[0] + compared_val[1];
            end
        end
    end
             
    always_ff @(posedge clk or posedge en) begin
        if(en) 
            //update when enabled
            branch_weight <= hamming_weight;
        else
            branch_weight <= branch_weight;
    end

endmodule
