`timescale 1ns / 1ps

module encode_and_tx_sim(

    );
    
    logic clk;
    logic en;
    logic [1023:0] raw_data;
    
    encode_and_send_FSM #(.DATA_BITS(1024))DUT(
        .clk(clk),
        .en(en),
        .raw_data(raw_data),
        .done(done),
        .txd(txd),
        .led_test1(led_test1),
        .led_test2(led_test2),
        .led_test3(led_test3),
        .led_test4(led_test4)
    );
    
    initial begin
        clk = 0;
        forever #5 clk = ~clk; // Generate clock with period 10 ns
    end
    
    initial begin
        en = 0;
        raw_data = 1024'b1;
        
        #10;
        
        en = 1;
        
        #300000000;
        $stop;
    end
    
endmodule
