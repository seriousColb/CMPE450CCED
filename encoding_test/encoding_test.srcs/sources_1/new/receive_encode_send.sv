`timescale 1ns / 1ps

module receive_encode_send(
    input logic clk,
    input logic en,
    input logic rxd,
    output logic done,
    output logic txd,
    output logic led_test1,
    output logic led_test2
    );
    
    //receiver signals
    logic [1023:0] user_msg;
    logic [8:0] num_bytes = 0;
    logic rx_done = 0;
    logic rx_en;
    
    //transmitter signals
    logic tx_done = 0;
    logic [1023:0] to_encode;
    logic tx_en;
    
    //state machine signals
    logic [2:0]state;
    logic [23:0]wait_counter = 0;
    
    receive_msg_FSM receiver_logic(
        .clk(clk),
        .en(rx_en),
        .rxd(rxd),
        .msg(user_msg),
        .done(rx_done),
        .num_bytes(num_bytes)
    );
    
    encode_and_send_FSM #(.DATA_BITS(1024))DUT (
        .clk(clk),
        .en(tx_en),
        .raw_data(to_encode),
        .done(tx_done),
        .txd(txd)
    );
    
    localparam IDLE = 3'b000;
    localparam RECEIVE = 3'b001;
    localparam TRANSMIT = 3'b010;
    localparam WAIT_TRANSMIT = 3'b011;
    
    always_ff @(posedge clk) begin
        if(!en) begin
            user_msg <= 0;
            rx_en <= 0;
            tx_en <= 0;
            state <= IDLE;
            done <= 0;
            led_test1 <= 0;
            led_test2 <= 0;
        end else begin
            case(state)
                IDLE: begin
                    if(done == 0) begin
                        state <= RECEIVE;
                        rx_en <= 1;
                    end else begin
                        state <= IDLE;
                    end
                end
                
                RECEIVE: begin
                    led_test1 <= 1;
                    if(rx_done == 1) begin
                        led_test2 <= 1;
                        state <= WAIT_TRANSMIT;
                        //register the encoder input. clocked
                        to_encode <= user_msg;
                        rx_en <= 0;
                        tx_en <= 1;
                    end else begin
                        state <= RECEIVE;
                    end
                end
                
                WAIT_TRANSMIT: begin
                    //add a state that waits between receive and transmit. this is to give python time to prepare to receive
                    wait_counter <= wait_counter + 1;
                    if(wait_counter == 16777215) begin
                        state <= TRANSMIT;
                    end
                end
                
                TRANSMIT: begin
                    if(tx_done == 1) begin
                        tx_en <= 0;
                        done <= 1;
                        state <= IDLE;
                    end else begin
                        state <= TRANSMIT;
                    end
                end
            endcase
        end
    end
endmodule
