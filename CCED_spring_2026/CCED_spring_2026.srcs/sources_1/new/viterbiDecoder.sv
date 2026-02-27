`timescale 1ns / 1ps

module viterbiDecoder #(parameter k = 3) (
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
    logic [10:0] path_metrics [0:3];
    logic [10:0] updated_path_metrics [0:3];
    logic branch_bits [0:3];
    logic acs_en;
    logic [1:0] rx0;

    logic [3:0] time_step;
    logic [3:0] tb_timer;
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

    logic [1:0] curr_state [0:3];

    // -----------------------------
    // Initial states
    // -----------------------------
    initial begin
        curr_state[0] = 2'b00;
        curr_state[1] = 2'b01;
        curr_state[2] = 2'b10;
        curr_state[3] = 2'b11;
    end
    
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
    acs acs0 (
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

    acs acs1 (
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

    acs acs2 (
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

    acs acs3 (
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

    // -----------------------------
    // SMU
    // -----------------------------
    SMU #(.TB_DEPTH(16)) smu0 (
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
