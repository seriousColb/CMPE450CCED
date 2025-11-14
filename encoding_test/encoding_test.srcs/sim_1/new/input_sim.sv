`timescale 1ns / 1ps

//module to simulate taking in input (from a text file) and running the encoder
module input_sim#(parameter K=3)(
   
    );
    logic [7:0] memory [0:127]; //unpacked array of 128 bytes
    logic [15:0]encoded [0:127]; //unpacked array of 256 bytes
    logic clk;
    logic in_bit;
    logic shift_en;
    logic shift_reset;
    logic [K-2:0] state_reg;
    logic out1,out2;
    int unsigned index1, index2;
    int i, j;
    
    encode encoder(
        .in(in_bit),
        .shift_reg(state_reg),
        .out1(out1),
        .out2(out2)
    );
    
    shift_register shift_register(
        .in(in_bit),
        .clk(clk),
        .reset(shift_reset),
        .en(shift_en),
        .shift_reg(state_reg),
        .out_reg(state_reg)
    );
    
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // Generate clock with period 10 ns
    end
     
    initial begin 
         in_bit = 0;
         index1 = 0;
         index2 = 0;
         state_reg[0] = 0;
         state_reg[1] = 0;
         shift_reset = 0;
         
        $readmemh("data.txt", memory);
        $display("First value: %b", memory[0]);
        #10;
        
        for(i = 0; i<128; i++) begin
            for(j = 0; j<8; j++) begin
                  in_bit = memory[i][j];
                  #10;
                  index1 = (j*2);
                  index2 = (j*2) + 1;
                  encoded[i][index1] = out1;
                  encoded[i][index2] = out2;
                  $display("Encoded bit %0d,%0d -> %b %b", i, j, out1, out2);
                  //wait and then enable the shift register to shift
                  #10;
                  shift_en = 1;
                  #10;
                  shift_en = 0;
            end
            //#10;
        end
    end
endmodule
