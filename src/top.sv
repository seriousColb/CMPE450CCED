`timescale 1ns / 1ps

module top(
    input logic clk,        // system clock (e.g., 100 MHz)
    input logic reset,      // reset button/signal
    input logic RxD,
    input logic RxD_2,        // UART receive line
    input logic btn,
    input logic en,
    input logic en_2,
    output logic TxD,
    output logic TxD_2,
    output logic [7:0] LED  // display received byte on LEDs
);

//en --> V17 (first switch)
//reset--> 

logic [7:0] rx_data; // internal wire to connect receiver output
logic [7:0] rx_data_2; //second receiver
logic data_valid; //high when byte is received
logic data_valid_2; //second data valid
logic [1023:0] msg; //input message
logic [2047:0] enc_msg; //encoded message
logic [1023:0] msg_2;
logic [6:0] byte_index;
logic [7:0] byte_count;

logic start;
logic done;
logic busy_prev;
logic start_prev;
logic transmit_pulse;
logic reset_en;
logic reset_en_2;

encode_and_send_FSM #(
    .DATA_BITS(1024),
    .K(3)
) encode_and_send_FSM_1 (
    .clk(clk),
    .en(en),
    .raw_data(msg),
    .done(done),
    .txd(TxD),
    .reset(reset_en)
);

send_FSM #(
    .DATA_BITS(1024),
    .K(3)
) send_FSM (
    .clk(clk),
    .en(en_2),
    .raw_data(msg_2),
    .done(done),
    .txd(TxD_2),
    .reset(reset_en_2)
);

// instantiate the receiver module
receiver rec1 (
    .clk(clk),
    .reset(reset),
    .RxD(RxD),
    .RxData(rx_data),
    .data_valid(data_valid)
);

receiver rec2 (
    .clk(clk),
    .reset(reset),
    .RxD(RxD_2),
    .RxData(rx_data_2),
    .data_valid(data_valid_2)
);
//receive message and place in msg
always_ff @(posedge clk or posedge reset_en) begin
    if(reset_en) begin
        msg <= 0;
    end
    else if(data_valid) begin
        msg <= {msg[1015:0], rx_data};
    end
    else begin
        msg <= msg;
    end
end

//receive encoded message and place in enc_msg
always_ff @(posedge clk or posedge reset_en_2) begin
    if(reset_en_2) begin
        enc_msg <= 0;
    end
    else if(data_valid) begin
        enc_msg <= {enc_msg[2039:0], rx_data_2};
        byte_count <= byte_count + 1;
    end
    else if(byte_count == 128) begin
        msg_2 <= enc_msg[1023:0];
        //msg_2 <= 1024'b1;
        //the above commented out line works. meaning it transmitted 1023 0's and one 1
        //i could not get the non commented out line to work
        //maybe a receiver issue or a shifting issue, not sure
    end
    else begin
        enc_msg <= enc_msg;
    end
end

//use a different data_valid for second uart to tell difference

assign LED[0] = enc_msg[0];
assign LED[1] = enc_msg[1];
assign LED[2] = enc_msg[2];
assign LED[3] = enc_msg[3];
assign LED[4] = enc_msg[4];
assign LED[5] = enc_msg[5];
assign LED[6] = enc_msg[6];
assign LED[7] = enc_msg[7];

assign LED[8] = msg_2[8];
assign LED[9] = msg_2[9];
assign LED[10] = msg_2[10];
assign LED[11] = msg_2[11];
assign LED[12] = msg_2[12];
assign LED[13] = msg_2[13];
assign LED[14] = msg_2[14];
assign LED[15] = msg_2[15];

endmodule


