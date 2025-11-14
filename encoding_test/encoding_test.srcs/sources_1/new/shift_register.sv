`timescale 1ns / 1ps

//module that shifts the passed in shift register given the input bit
module shift_register#(parameter K=3)(
    input in,
    input clk,
    input reset,
    input en,
    input reg [K-2:0]shift_reg,
    output reg [K-2:0]out_reg
    );
    
    //shifts the register and adds the new bit
    always @(posedge clk) begin
        if(reset)
            out_reg <= 0;    
        else if(en)
            out_reg <= {in, shift_reg[K-2:1]};
    end
endmodule

