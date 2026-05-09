`timescale 1ns / 1ps
//this module uses an instance of the encode_FSM and transmitter modules to encode 
//incoming data and transmit it through UART. the data is sent byte by byte because our
//UART transmitter uses 8 bit frames

module send_FSM #(parameter DATA_BITS=1024, K=3)(
    input logic clk,
    input logic en,
    input logic [DATA_BITS-1:0]raw_data,
    output logic done,
    output logic txd,
    output logic reset
    );
    
    //encoder signals
    logic encoder_en;
    logic [(DATA_BITS)-1:0]encoded_data;
    logic encode_done;
    
    //transmitter signals
    logic tx_reset;
    logic tx_transmit;
    logic [7:0]tx_data;
    logic tx_done;
    logic tx_busy_prev; //used to detect falling edge of busy
    logic tx_busy;
    logic [16:0] wait_counter;
    
    //state machine control signals
    logic [2:0]state;
    logic [8:0]byte_counter; //byte_counter tracks bytes to be sent by transmitter. it is a decremental counter.
    
//    encode_FSM #(.DATA_BITS(DATA_BITS),.K(K)) encoder(
//        .raw_data(raw_data),
//        .clk(clk),
//        .en(encoder_en),
//        .encoded_data(encoded_data),
//        .done(encode_done)
//    );
    
//    transmitter transmitter(
//        .clk(clk),
//        .reset(tx_reset),
//        .transmit(tx_transmit),
//        .data(tx_data),
//        .TxD(txd),
//        .done(tx_done)
//    );

//    buffered_transmitter transmitter(
//        .clk(clk),
//        .reset(tx_reset),
//        .transmit(tx_transmit),
//        .data(encoded_data[byte_counter*8 +: 8]),
//        .TxD(txd),
//        .busy(tx_busy)
//        //.done(tx_done)
//    );

transmitter dut1 (
    .clk(clk),
    .reset(tx_reset),
    .transmit(tx_transmit),
    .data(raw_data[byte_counter*8 +: 8]),
    .TxD(txd),
    .busy(tx_busy)
);
    
    //state machine will start with an encode state that encodes the entire message.
    localparam IDLE = 3'b000;
    localparam ENCODE = 3'b001;
    localparam WAIT_TRANSMIT = 3'b010;
    localparam WAIT_BUSY_HIGH = 3'b011;
    localparam WAIT_READY = 3'b100;
    localparam TRANSMIT_BYTE = 3'b101;
    
    //edge detection
    always_ff @(posedge clk) begin
        tx_busy_prev <= tx_busy;  
    end
    
    //assign tx_reset = !en;
    
    always_ff @(posedge clk) begin
        if(!en) begin
            state <= IDLE;
            encoder_en <= 0;
            //encoded_data <= 0; this signal is driven by encoder
            //encode_done <= 0; this signal is driven by encoder
            
            tx_transmit <= 0;
            tx_data <= 0;
            //tx_done <= 0; this signal is driven by transmitter
            
            done <= 0;
            tx_reset <= 1;
            wait_counter <= 0;
        end else begin
            case(state)
                IDLE: begin
                    tx_reset <= 0;
                    reset <= 0;
                    if(done == 0)begin
                        state <= WAIT_READY;
                        byte_counter <= ((DATA_BITS/8) - 1);
                        //encoder_en <= 1;
                    end else begin
                        state <=IDLE;
                    end
                end
                
//                ENCODE: begin
//                    //entire message is encoded in this state, storing the result in encoded_data
//                    if(encode_done == 0) begin
//                        state <= ENCODE;
//                    end else begin
//                        //encoding is done so disable the the encoder and move to transmission states
//                        //encoder_en <= 0;
//                        byte_counter <= ((DATA_BITS*2/8) - 1); //double the amount of bytes in the encoded message
//                        state <= WAIT_READY;
//                    end
//                end
                
//                SET_BYTE: begin
//                        ////there are more bytes to send. set tx_data and move to transmit. 
//                        //wouldn't let me set tx_data to a range so i just assigned each bit one by one
//                        tx_data[0] <= encoded_data[byte_counter*8 +: 8];
                        
//                        state <= TOGGLE_TRANSMIT;
//                end 
                
                //add a toggle transmit state that sets transmit to high for 1 cycle (needs to be pulsed)
//                TOGGLE_TRANSMIT: begin
//                    tx_transmit <= 1;
//                    state <= WAIT_BUSY_HIGH;
//                end
                
                WAIT_READY: begin
                    //if tx is not busy, transmit
                    wait_counter <= 0;
                    tx_reset <= 0;
                    if(!tx_busy) begin
                        tx_transmit <= 1;
                        state <= WAIT_BUSY_HIGH;
                    end else begin
                        state <= WAIT_READY;
                    end
                end
                
                WAIT_BUSY_HIGH: begin
                    tx_transmit <= 0;

                    //rising edge of busy
                    if(tx_busy && !tx_busy_prev) begin
                        state <= TRANSMIT_BYTE;
                    end else begin
                        state <= WAIT_BUSY_HIGH;
                    end
                end
                
                TRANSMIT_BYTE: begin
                    //wait in this state for transmission to complete. this happens on the falling edge of the busy bit
                  
                    //falling edge of busy
                    if(tx_busy_prev && !tx_busy) begin
                        state <= WAIT_TRANSMIT;
                    end else begin
                        state <= TRANSMIT_BYTE;
                    end
                end
                
                WAIT_TRANSMIT: begin
                    //just added a state that will wait for the byte to transmit before moving to the next state
                    wait_counter <= wait_counter + 1;
                    if(wait_counter >= 105000) begin
                        tx_reset <= 1;
                        byte_counter <= byte_counter - 1;
                        if(byte_counter == 0) begin
                            state <= IDLE;
                            done <= 1;
                            reset <= 1;
                        end else begin
                            state <= WAIT_READY;
                        end
                    end else begin
                        state <= WAIT_TRANSMIT;
                    end
                end       
            endcase
        end
    end
endmodule
