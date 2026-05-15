`timescale 1ns / 1ps

module top #(parameter K = 3)(
    input logic clk,        // system clock (e.g., 100 MHz)
    input logic reset,      // reset button/signal
    input logic RxD,        // RxD for source
    input logic RxD_2,      // RxD for sink
    //input logic btn,
    input logic en,
    output logic TxD,       // TxD for source
    output logic TxD_2      // TxD for sink
    //output logic [7:0] LED  // display received byte on LEDs
);

logic [7:0] rx_data; // internal wire to connect receiver output
logic [7:0] rx_data_2;
logic data_valid; //high when byte is received
logic data_valid_2;


logic [1023:0] msg; //input message
logic [2047:0] corrupt_enc_msg;
logic [6:0] byte_index;

logic start;
logic encode_done;
logic decode_done;

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
    .K(K)
) encode_and_send_FSM (
    .clk(clk),
    .en(en),
    .raw_data(msg),
    .done(encode_done),
    .txd(TxD_2) //send encoded to sink for corruption
);

decode_and_send_FSM #(
    .DATA_BITS(1024),
    .K(K)
) decode_and_send_FSM (
    .clk(clk),
    .en(en),
    .encoded(corrupt_enc_msg),
    .done(decode_done),
    .txd(TxD) //send decoded to source for validation
);

//transmit V17 (first)
//reset V16 (second)

//source receiver. will receive raw message from the source.
receiver rec_0 (
    .clk(clk),
    .reset(reset),
    .RxD(RxD),
    .RxData(rx_data),
    .data_valid(data_valid)
);

//sink receiver. will receive erroneous encoded message from the sink.
receiver rec_1 (
    .clk(clk),
    .reset(reset),
    .RxD(RxD_2),
    .RxData(rx_data_2),
    .data_valid(data_valid_2)
);

//debounce dut3 (
//    .pb_1(btn),
//    .clk(clk),
//    .pb_out(start)
//);

//receiver logic for rec_0. receives raw message from source laptop
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

//receiver logic for rec_1. receives the corrupted encoded message from the sink laptop
always_ff @(posedge clk or posedge reset) begin
    if(reset) begin
        corrupt_enc_msg <= 0;
     end else if (data_valid_2) begin
        corrupt_enc_msg <= {corrupt_enc_msg[2039:0], rx_data_2};
     end else begin
        corrupt_enc_msg <= corrupt_enc_msg;
     end
end

endmodule