`timescale 1ns / 1ps

//this module will encode messages with size DATA_BITS. It will support constraint lengths
//of K = 3,4,5 and 7.
//Constraint length of 3 uses the following generator polynomials: e1 = {7} = {111} | e2 = {5} = {101}
//Constraint lehgth of 4 uses the following generator polynomials: e1 = {17} = {1111} | e2 = {13} = {1011}. ref: https://www.math.tecnico.ulisboa.pt/~pmartins/CTC/CTC20Notes10.pdf
//Constraint length of 5 uses the following generator polynomials: e1 = {37} = {11111} | e2 = {33} = {11011}. ref: https://www.mathworks.com/help/comm/ref/poly2trellis.html
//Constraint length of 7 uses the following generator polynomials: e1 = {171} = {1111001} | e2 = {133} = {1011011}. ref: https://en.wikipedia.org/wiki/Convolutional_code#References

module encode_FSM #(parameter DATA_BITS = 8, K=3)(
        input logic [DATA_BITS-1:0] raw_data,
        input logic clk,
        input logic en,
        output logic [(DATA_BITS*2)-1:0] encoded_data,
        output logic done
    );
    
    logic [K-2:0] state_reg; //encoder state register
    logic out1,out2; //encoder outputs   
    
    //FSM states
    localparam IDLE = 2'b00;
    localparam SET = 2'b01;
    localparam SHIFT = 2'b10;
   
    //FSM control signals
    logic[1:0] state;
    logic[10:0] counter; //maximum is 1024 for 1024 length input message. tracks what bit we are at in decoding process
    
    always_ff @(posedge clk) begin
        if(!en) begin
            state <= IDLE;
            state_reg <= 0;
            counter <= 0;
            encoded_data <= 0;
            done <= 0;
        end else begin
            case(state)
                IDLE: begin
                    if(counter < DATA_BITS) begin
                        //done <= 0;
                        state <= SET;
                    end else begin
                        //set to high when the encoding process is done (when counter exceeds data bits).
                        done <= 1;
                        state <= IDLE;
                    end
                end
                
                SET: begin
                    //set encoded bits. data is loaded from MSB -> LSB so the output can be read from left to right on waveform
                    case(K)
                        3: begin
                            encoded_data[(DATA_BITS*2) - counter*2 - 1] <= state_reg[0] ^ state_reg[1] ^ raw_data[DATA_BITS - counter - 1]; //{1|11}
                            encoded_data[(DATA_BITS*2 - (counter*2)- 2)] <= state_reg[0] ^ raw_data[DATA_BITS - counter - 1]; //{1|01}
                            state <= SHIFT;
                        end
                        
                        4: begin
                            encoded_data[(DATA_BITS*2) - counter*2 - 1] <=  raw_data[DATA_BITS - counter - 1] ^ state_reg[2] ^ state_reg[1] ^ state_reg[0]; //{1|111}
                            encoded_data[(DATA_BITS*2 - (counter*2)- 2)] <= raw_data[DATA_BITS - counter - 1] ^ state_reg[1] ^ state_reg[0];//{1|011}
                            state <= SHIFT;
                        end
                        
                        5: begin
                            encoded_data[(DATA_BITS*2) - counter*2 - 1] <=  raw_data[DATA_BITS - counter - 1] ^ state_reg[3] ^ state_reg[2] ^ state_reg[1] ^ state_reg[0]; //{1|1111}
                            encoded_data[(DATA_BITS*2 - (counter*2)- 2)] <= raw_data[DATA_BITS - counter - 1] ^ state_reg[3] ^ state_reg[1] ^ state_reg[0];//{1|1011}
                            state <= SHIFT;
                        end
                        
                        7: begin
                            encoded_data[(DATA_BITS*2) - counter*2 - 1] <=  raw_data[DATA_BITS - counter - 1] ^ state_reg[5] ^ state_reg[4] ^ state_reg[3] ^ state_reg[0]; //{1|111001}
                            encoded_data[(DATA_BITS*2 - (counter*2)- 2)] <= raw_data[DATA_BITS - counter - 1] ^ state_reg[4] ^ state_reg[3] ^ state_reg[1] ^ state_reg[0];//{1|011011}
                            state <= SHIFT;
                        end
      
                    endcase
                end
                
                SHIFT: begin
                    //shift the state register. shift from MSB -> LSB
                    state_reg <= {raw_data[DATA_BITS - counter - 1], state_reg[K-2:1]};
                    counter <= counter + 1;
                    state <= IDLE;
                end
            endcase
        end
    end
    
endmodule
