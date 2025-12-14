`timescale 1ns/1ps

module viterbiDecoder_tb;

    // --------------------------------
    // Clock / reset
    // --------------------------------
    logic clk;
    logic rst;
    logic en;
    logic done;

    // --------------------------------
    // DUT signals
    // --------------------------------
    logic [31:0] encoded_bits [0:63];
    logic [1023:0] decoded_bits;

    // --------------------------------
    // Instantiate DUT
    // --------------------------------
    viterbiDecoder dut (
        .clk(clk),
        .rst(rst),
        .en(en),
        .encoded_bits(encoded_bits),
        .decoded_bits(decoded_bits),
        .done(done)
    );

    // --------------------------------
    // Clock generation (100 MHz)
    // --------------------------------
    initial clk = 0;
    always #5 clk = ~clk;

    // --------------------------------
    // Test stimulus
    // --------------------------------
    initial begin
        integer i;

        // Initialize inputs
        rst = 1'b1;
        en  = 1'b0;

        // Clear encoded input
        for (i = 0; i < 64; i = i + 1) begin
            encoded_bits[i] = 32'b0;
        end

        // --------------------------------
        // Example encoded sequence
        // (You can replace this with real encoder output)
        // Each 2 bits = one symbol
        // --------------------------------
        encoded_bits[0] = {
            2'b11, 2'b01, 2'b00, 2'b10,
            2'b11, 2'b01, 2'b00, 2'b10,
            2'b11, 2'b01, 2'b00, 2'b10,
            2'b11, 2'b01, 2'b00, 2'b10
        };

        // Hold reset
        #20;
        rst = 1'b0;

        // Start decoding
        #10;
        en = 1'b1;

        // --------------------------------
        // Wait for completion
        // --------------------------------
        wait (done);

        #20;
        $display("Decoding complete!");
        $display("Decoded bits = %b", decoded_bits);

        $stop;
    end

endmodule
