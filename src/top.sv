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
logic [3:0] bit_counter;
logic [7:0] to_send;
logic [6:0] byte_index;

transmitter dut1 (
    .clk(clk),
    .reset(reset),
    .transmit(transmit),
    .data(to_send),
    .TxD(TxD),
    .bit_counter(bit_counter)
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

always_comb begin
    to_send = msg[(byte_index * 8) +: 8];
end

always_ff @(posedge clk or posedge reset) begin
    if(reset) begin
        byte_index <= 0;
    end
    else if(bit_counter >= 10) begin
            if(byte_index == 127) begin
                byte_index <= 0;
            end else begin
                byte_index <= byte_index + 1;
            end
    end 
    else begin
        byte_index <= byte_index;
    end
end



endmodule
