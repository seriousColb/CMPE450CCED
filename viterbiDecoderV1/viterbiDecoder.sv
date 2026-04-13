`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12/14/2025 11:11:24 AM
// Design Name: 
// Module Name: viterbiDecoder
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module viterbiDecoder #(parameter K = 3)(
    input  logic clk,
    input  logic rst,
    input  logic en,
    input  logic [31:0] encoded_bits [0:63],
    output logic [1023:0] decoded_bits,
    output logic done
);

    // -----------------------------
    // Parameters / Types
    // -----------------------------
    typedef enum logic [2:0] {
        SMU_START,
        SMU_IDLE,
        SMU_TRACEBACK,
        SMU_DONE
    } smu_state_t;

    // -----------------------------
    // Signals
    // -----------------------------
    logic [3:0] tb = 4'b1111;
    logic [10:0] path_metrics [0:2**(K-1)];
    logic [10:0] updated_path_metrics [0:2**(K-1)];
    logic branch_bits [0:2**(K-1)];
    logic acs_en;
    logic [1:0] rx0;

    logic [6:0] time_step;
    logic [6:0] tb_timer;
    logic [6:0] tb_index;
    logic tb_done;
    logic tb_rdy;

    logic smu_en;
    logic smu_rst;
    logic tb_active;

    logic [1:0] best_state;
    logic [9:0] decoder_counter;

    logic smu_tb_valid;
    logic smu_tb_bit;

    smu_state_t smu_state;

    logic [K-1:0] curr_state [0:2**(K-1)];

    // -----------------------------
    // Initialize states
    // -----------------------------
    genvar j;
    
    generate
        for(j = 0; j < 2**(K-1); j = j + 1) begin : STATE_BLOCK
            assign curr_state[j] = (K-1)'(j);
        end
    endgenerate
    
    // -----------------------------
    // SMU FSM (sole owner of smu_en)
    // -----------------------------
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            smu_en    <= 0;
            smu_rst   <= 1;
            smu_state <= SMU_START;
            tb_timer  <= 0;
            time_step <= 0;
            tb_index <= 0;
            tb_done <= 0;
            done <= 0;
            acs_en <= 1;
            rx0 <= encoded_bits[0][31 - (0) -: 2];
            decoder_counter <= 0;
            path_metrics[0] <= 0;
            path_metrics[1] <= 11'h7FF;
            path_metrics[2] <= 11'h7FF;
            path_metrics[3] <= 11'h7FF;
        end else begin
            smu_rst <= 0;
            case (smu_state)
                SMU_START: begin
                    smu_state <= SMU_IDLE;
                end
                SMU_IDLE: begin
                    smu_en <= 0;
                    if(time_step < tb)begin
                        path_metrics <= updated_path_metrics;
                        rx0 <= encoded_bits[tb_index][31 - (2*time_step) -: 2];
                        time_step <= time_step + 1;
                        if(time_step == tb - 1)begin
                            if      (path_metrics[0] < path_metrics[1] &&
                                     path_metrics[0] < path_metrics[2] &&
                                     path_metrics[0] < path_metrics[3]) best_state <= 2'b00;
                           else if (path_metrics[1] < path_metrics[0] &&
                                    path_metrics[1] < path_metrics[2] &&
                                    path_metrics[1] < path_metrics[3]) best_state <= 2'b01;
                            else if (path_metrics[2] < path_metrics[0] &&
                                    path_metrics[2] < path_metrics[1] &&
                                    path_metrics[2] < path_metrics[3])best_state <= 2'b10;
                            else  if(path_metrics[3] < path_metrics[1] &&
                                    path_metrics[3] < path_metrics[0] &&
                                    path_metrics[3] < path_metrics[2]) best_state <= 2'b11;
                            else best_state <= best_state;
                        end                                        
                    end else begin
                        smu_en <= 1;
                        acs_en <= 0;
                        time_step <= 0;
                         tb_index <= tb_index + 1;
                        smu_state <= SMU_TRACEBACK;
                    end           
                end
                SMU_TRACEBACK: begin
                    if(smu_tb_valid)begin
                        decoded_bits[((16*(64-tb_index))) + decoder_counter] <= smu_tb_bit;
                        decoder_counter <= decoder_counter + 1;
                    end
                    if (!tb_active) begin
                        decoder_counter <= 0;
                        smu_state <= SMU_DONE;
                        //tb_index <= tb_index + 1;
                    end
                end

                SMU_DONE: begin
                    if(tb_index < 64)begin
                        smu_en    <= 0;
                        tb_done   <= 0;                
                        rx0 <= encoded_bits[tb_index][31 - (2*time_step) -: 2];
                        acs_en <= 1;
                        smu_state <= SMU_IDLE;
                    end else begin
                        done <= 1;
                    end
                end
            endcase
        end
    end
    
    // -----------------------------
    // ACS Units
    // -----------------------------
            genvar i;
            
            generate
            
            for(i = 0; i < 2**(K-1); i= i+1) begin : ACS_BLOCK
                localparam int pthmet0 = j >> 1;
                localparam int pthmet1 = pthmet0 + ((2**(K-1)>>1));
                acs #(.K(K)) u_acs (
                    .clk(clk),
                    .rst(rst),
                    .en(acs_en),
                    .rx(rx),
                    .curr_state(curr_state[i]),
                    .path_weight0(path_metrics[pthmet0]),
                    .path_weight1(path_metrics[pthmet1]),
                    .branch_bit(branch_bits[i]),
                    .updated_path(updated_path_metrics[i])
                );
            
            end
            
            endgenerate  
            
            
            
            /*
            acs #(.K(K)) acs0 (
                .rx(rx0),
                .curr_state(00),
                .path_weight0(path_metrics[0]),
                .path_weight1(path_metrics[2]),
                .en(acs_en),
                .clk(clk),
                .rst(rst),
                .branch_bit(branch_bits[0]),
                .updated_path(updated_path_metrics[0])
            );
        
            acs #(.K(K)) acs1 (
                .rx(encoded_bits[tb_index][31 - (2*time_step) -: 2]),
                .curr_state(10),
                .path_weight0(path_metrics[0]),
                .path_weight1(path_metrics[2]),
                .en(acs_en),
                .clk(clk),
                .rst(rst),
                .branch_bit(branch_bits[1]),
                .updated_path(updated_path_metrics[1])
            );
        
            acs #(.K(K)) acs2 (
                .rx(encoded_bits[tb_index][31 - (2*time_step) -: 2]),
                .curr_state(01),
                .path_weight0(path_metrics[1]),
                .path_weight1(path_metrics[3]),
                .en(acs_en),
                .clk(clk),
                .rst(rst),
                .branch_bit(branch_bits[2]),
                .updated_path(updated_path_metrics[2])
            );
        
            acs #(.K(K)) acs3 (
                .rx(encoded_bits[tb_index][31 - (2*time_step) -: 2]),
                .curr_state(11),
                .path_weight0(path_metrics[1]),
                .path_weight1(path_metrics[3]),
                .en(acs_en),
                .clk(clk),
                .rst(rst),
                .branch_bit(branch_bits[3]),
                .updated_path(updated_path_metrics[3])
            );
            */

    // -----------------------------
    // SMU
    // -----------------------------
    SMU #(.TB_DEPTH(K*5)) smu0 (
        .clk(clk),
        .rst(smu_rst),
        .write_en(acs_en), //formerly acs_en
        .sel_in(branch_bits),
        .index(tb_index),
        .tb_start(smu_en),
        .tb_state_start(best_state),
        .tb_bit(smu_tb_bit),
        .tb_valid(smu_tb_valid),
        .tb_active(tb_active)
    );
endmodule
