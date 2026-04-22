`timescale 1ns / 1ps
//this testbench tests the encode_FSM value with different constraint lengths. the constraint length, K, is a parameter in
//of the module. 4 instances with K = 3,4,5 and 7 are created and tested.

module encoder_FSM_sim(
        
    );
    logic clk;
    logic encoder_en;
    logic [7:0] raw_data;
    logic [1023:0] raw_data2;
    logic done1;
    logic done2;
    logic done3;
    logic done4;
    logic done5;
    
    //different encoded_data signals for each constraint length
    logic [15:0] encoded_data_3;
    logic [15:0] encoded_data_4;
    logic [15:0] encoded_data_5;
    logic [15:0] encoded_data_7;
    logic [2047:0] encoded_data_8;
    
    //encoder with constraint length of 3
    encode_FSM DUT_3(
        .raw_data(raw_data),
        .clk(clk),
        .en(encoder_en),
        .encoded_data(encoded_data_3),
        .done(done1)
    );
    
    encode_FSM #(.K(4)) DUT_4(
        .raw_data(raw_data),
        .clk(clk),
        .en(encoder_en),
        .encoded_data(encoded_data_4),
        .done(done2)
    );
    
    encode_FSM #(.K(5)) DUT_5(
        .raw_data(raw_data),
        .clk(clk),
        .en(encoder_en),
        .encoded_data(encoded_data_5),
        .done(done3)
    );
    
    encode_FSM #(.K(7)) DUT_7(
        .raw_data(raw_data),
        .clk(clk),
        .en(encoder_en),
        .encoded_data(encoded_data_7),
        .done(done4)
    );
    
    encode_FSM #(.DATA_BITS(1024)) DUT_8(
        .raw_data(raw_data2),
        .clk(clk),
        .en(encoder_en),
        .encoded_data(encoded_data_8),
        .done(done5)
    );
    
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // Generate clock with period 10 ns
    end
    
    initial begin
        encoder_en = 0;
        
        #10;
        
        encoder_en = 1;
        raw_data = 8'b11110000;
        raw_data2 = '1;
        
        #300;
        
        encoder_en = 0;
        
        #50;
        
        encoder_en = 1;
        raw_data = 8'b00000000;
        
        #300;
        
        $stop;
    end
    
endmodule
