`timescale 1ns / 1ps

module top(
    input logic clk,        // system clock (e.g., 100 MHz)
    input logic reset,      // reset button/signal
    input logic RxD,        // UART receive line
    input logic btn,
    input logic en,
    output logic TxD,
    output logic [7:0] LED  // display received byte on LEDs
);

logic [7:0] rx_data; // internal wire to connect receiver output
logic data_valid; //high when byte is received
logic [1023:0] msg; //input message
logic [6:0] byte_index;

logic start;
logic done;

logic busy_prev;
logic start_prev;
logic transmit_pulse;

//transmitter dut1 (
//    .clk(clk),
//    .reset(reset),
//    .transmit(transmit_pulse),
//    .data(msg[byte_index*8 +: 8]),
//    .TxD(TxD),
//    .busy(busy)
//);

encode_and_send_FSM #(
    .DATA_BITS(1024),
    .K(3)
) encode_and_send_FSM (
    .clk(clk),
    .en(en),
    .raw_data(msg),
    .done(done),
    .txd(TxD)
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

//debounce dut3 (
//    .pb_1(btn),
//    .clk(clk),
//    .pb_out(start)
//);

//code to take in from a text file. a 1 or a 0. 
always_ff @(posedge clk or posedge reset) begin
    if(reset) begin
        msg <= 0;
    end
    else if(data_valid) begin
        msg <= {msg[1015:0], rx_data};
    end
    else begin
        msg <= msg;
    end
end

assign LED[0] = byte_index[0];
assign LED[1] = byte_index[1];
assign LED[2] = byte_index[2];
assign LED[3] = byte_index[3];
assign LED[4] = byte_index[4];
assign LED[5] = byte_index[5];
assign LED[6] = byte_index[6];

//start at 127th byte and decrement to send all bytes
//always_ff @(posedge clk or posedge reset) begin
//    if (reset) begin
//        byte_index <= 127;
//        busy_prev <= 0;
//    end
//    else begin
//        busy_prev <= busy;

//        // detect falling edge of busy (byte finished)
//        if (busy_prev && !busy) begin
//            if (byte_index == 0)
//                byte_index <= 127;
//            else
//                byte_index <= byte_index - 1;
//        end
//    end
//end

//always_ff @(posedge clk) begin
//    start_prev <= start;
//    transmit_pulse <= start && !start_prev; // rising edge detect
//end

endmodule


