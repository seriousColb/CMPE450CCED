`timescale 1ns / 1ps
//state machine that receives each byte and outputs the entire message

module receive_msg_FSM #(parameter DATA_BITS=8)(
    input logic clk,
    input logic en,
    input logic rxd,
    output logic[1023:0] msg,
    output logic done,
    output logic[8:0] num_bytes
    );
    
    logic rx_reset;
    logic[7:0] rx_data;
    logic data_valid;
    
    // instantiate the receiver module
    receiver dut2 (
        .clk(clk),
        .reset(rx_reset),
        .RxD(rxd),
        .RxData(rx_data),
        .data_valid(data_valid)
    );
    
    always_ff @(posedge clk) begin
        if(!en) begin
            msg <= 0;
            num_bytes <= 0;
            done <= 0;
            rx_reset <= 1;
        end else begin
            rx_reset <= 0;
            if(data_valid) begin
                if(done == 0) begin
                    if(rx_data == 8'b00000000)begin
                        //all bytes received. null terminator
                        msg[num_bytes*8 +: 8] <= rx_data;
                        done <= 1;
                    end else begin
                        if(data_valid) begin
                            msg[num_bytes*8 +: 8] <= rx_data;
                            num_bytes <= num_bytes + 1;
                        end
                    end 
                end 
            end
        end
    end

endmodule
