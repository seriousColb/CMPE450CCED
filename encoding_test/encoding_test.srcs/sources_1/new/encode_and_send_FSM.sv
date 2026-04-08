`timescale 1ns / 1ps
//this module uses an instance of the encode_FSM and transmitter modules to encode 
//incoming data and transmit it through UART. the data is sent byte by byte because our
//UART transmitter uses 8 bit frames

module encode_and_send_FSM #(parameter DATA_BITS=8, K=3)(
    input logic clk,
    input logic en,
    input logic [DATA_BITS-1:0]raw_data,
    output logic done,
    output logic txd,
    output logic led_test
    );
    
    //encoder signals
    logic encoder_en;
    logic [(DATA_BITS*2)-1:0]encoded_data;
    logic encode_done;
    
    //transmitter signals
    logic tx_reset;
    logic tx_transmit;
    logic [7:0]tx_data;
    logic tx_done;
    
    //state machine control signals
    logic [2:0]state;
    logic [7:0]byte_counter; //byte_counter tracks bytes to be sent by transmitter. it is a decremental counter.
    
    encode_FSM #(.DATA_BITS(DATA_BITS), .K(K)) encoder(
        .raw_data(raw_data),
        .clk(clk),
        .en(encoder_en),
        .encoded_data(encoded_data),
        .done(encode_done)
    );
    
    transmitter transmitter(
        .clk(clk),
        .reset(tx_reset),
        .transmit(tx_transmit),
        .data(tx_data),
        .TxD(txd),
        .done(tx_done)
    );
    
    //state machine will start with an encode state that encodes the entire message.
    localparam IDLE = 3'b000;
    localparam ENCODE = 3'b001;
    localparam SET_BYTE = 3'b010;
    localparam TRANSMIT_BYTE = 3'b011;
    
    always_ff @(posedge clk) begin
        if(!en) begin
            state <= IDLE;
            encoder_en <= 0;
            encoded_data <= 0;
            encode_done <= 0;
            
            tx_reset <= 0;
            tx_transmit <= 0;
            tx_data <= 0;
            tx_done <= 0;
            
            done <= 0;
            byte_counter <= (DATA_BITS*2) % 8;
            led_test <= 0;
        end else begin
            case(state)
                IDLE: begin
                    if(done == 0)begin
                        state <= ENCODE;
                        encoder_en <= 1;
                    end else begin
                        state <=IDLE;
                    end
                end
                
                ENCODE: begin
                    //entire message is encoded in this state, storing the result in encoded_data
                    if(encode_done == 0) begin
                        state <= ENCODE;
                        led_test <= encode_done;
                    end else begin
                        //encoding is done so disable the the encoder and move to transmission states
                        //encoder_en <= 0;
                        state <= SET_BYTE;
                    end
                end
                
                SET_BYTE: begin
                    if(byte_counter > 0) begin
                        //there are more bytes to send. set tx_data and move to transmit. 
                        //wouldn't let me set tx_data to a range so i just assigned each bit one by one
                        tx_data[0] <= encoded_data[byte_counter*8-1];
                        tx_data[1] <= encoded_data[byte_counter*8-2];
                        tx_data[2] <= encoded_data[byte_counter*8-3];
                        tx_data[3] <= encoded_data[byte_counter*8-4];
                        tx_data[4] <= encoded_data[byte_counter*8-5];
                        tx_data[5] <= encoded_data[byte_counter*8-6];
                        tx_data[6] <= encoded_data[byte_counter*8-7];
                        tx_data[7] <= encoded_data[byte_counter*8-8];
                        
                        tx_reset <=0;
                        state <= TRANSMIT_BYTE;
                    end else begin
                        //all bytes have been sent
                        done <= 1;
                        state <= IDLE;
                    end
                end 
                
                TRANSMIT_BYTE: begin
                    //set transmit bit to high and move back to set_byte state after transmission is done
                    tx_transmit <= 1;
                    if(tx_done == 0) begin
                        //not done transmitting
                        state <= TRANSMIT_BYTE;
                    end else begin
                        //done transmitting. reset the transmitter
                        tx_transmit <= 0;
                        tx_reset <= 1;
                        byte_counter = byte_counter - 1;
                        state <= SET_BYTE;
                    end
                end       
            endcase
        end
    end
endmodule
