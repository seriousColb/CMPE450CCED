`timescale 1ns / 1ps

module top(
    input logic clk,        // system clock (e.g., 100 MHz)
    input logic reset,      // reset button/signal
    input logic RxD,        // UART receive line
    input logic transmit,
    output logic TxD,

    output logic [7:0] LED  // display received byte on LEDs
);

logic [7:0] rx_data; // internal wire to connect receiver output
logic in_bit; //extract bit from byte due to ASCII
logic data_valid; //high when byte is received
logic [1023:0] msg; //input message


logic done; 

transmitter dut1 (
    .clk(clk),
    .reset(reset),
    .transmit(transmit),
    .data(msg[7:0]),
    .TxD(TxD),
    .done(done)
);

//transmit V17 (first)
//reset V16 (second)

// instantiate the receiver module
receiver dut2 (
    .clk(clk),
    .reset(reset),
    .RxD(RxD),
    .RxData(rx_data),
    .data_valid(data_valid)
);

// assign received data to LEDs
assign LED = rx_data;

//code to take in from a text file. a 1 or a 0. 
//python program not yet made to do this

always_ff @(posedge clk or posedge reset) begin
    if(reset) begin
        msg <= 0;
    end
    else if(data_valid) begin
        if(rx_data == 8'b00110000)
            msg <= {msg[1022:0], 1'b0};
        else if(rx_data == 8'b00110001)
            msg <= {msg[1022:0], 1'b1};
    end
end


endmodule
