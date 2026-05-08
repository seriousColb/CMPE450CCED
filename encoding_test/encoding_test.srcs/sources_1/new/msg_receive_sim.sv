`timescale 1ns / 1ps

module receive_msg_FSM_tb;

    //-------------------------------------------------
    // Parameters
    //-------------------------------------------------

    parameter CLK_PERIOD = 10;        // 100 MHz clock
    parameter BAUD_PERIOD = 104170;   // matches ~9600 baud
    parameter div_counter = 26050;

    //-------------------------------------------------
    // DUT signals
    //-------------------------------------------------

    logic clk;
    logic en;
    logic rxd;

    logic [1023:0] msg;
    logic done;
    logic [8:0] num_bytes;

    //-------------------------------------------------
    // Instantiate DUT
    //-------------------------------------------------

    receive_msg_FSM dut (
        .clk(clk),
        .en(en),
        .rxd(rxd),
        .msg(msg),
        .done(done),
        .num_bytes(num_bytes)
    );

    //-------------------------------------------------
    // Clock generator
    //-------------------------------------------------

    always #(CLK_PERIOD/2) clk = ~clk;

    //-------------------------------------------------
    // UART send task
    //-------------------------------------------------

    task send_uart_byte(input [7:0] data);
        integer i;

        begin

            // Start bit
            rxd = 0;
            #(BAUD_PERIOD);

            // Data bits (LSB first)
            for(i = 0; i < 8; i = i + 1) begin
                rxd = data[i];
                #(BAUD_PERIOD);
            end

            // Stop bit
            rxd = 1;
            #(BAUD_PERIOD);

        end
    endtask

    //-------------------------------------------------
    // Test procedure
    //-------------------------------------------------

    initial begin

        //---------------------------------------------
        // Initialize
        //---------------------------------------------

        clk = 0;
        rxd = 1;   // idle high
        en  = 0;

        #100;

        en = 1;
        
        #100;

        //---------------------------------------------
        // Send message: DA 4F 22 00
        //---------------------------------------------

        send_uart_byte(8'hDA);
        #(BAUD_PERIOD * 2);
        send_uart_byte(8'h4F);
        #(BAUD_PERIOD * 9);
        send_uart_byte(8'h22);
        #(BAUD_PERIOD * 7);
        send_uart_byte(8'h70);
        #(BAUD_PERIOD * 3);

        // Null terminator
        send_uart_byte(8'h00);
        #(BAUD_PERIOD * 5);

        //---------------------------------------------
        // Wait for FSM completion
        //---------------------------------------------

        wait(done);

        #1000;

        //---------------------------------------------
        // Display results
        //---------------------------------------------

        $display("Message received:");
        $display("num_bytes = %d", num_bytes);
        $display("msg = %h", msg);

        $finish;

    end

endmodule