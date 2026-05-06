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
// Revision 0.02 - Bug fixes:
//   - BUG 2 FIX: rx0 is now loaded one cycle BEFORE path metrics are updated.
//                Previously rx0 and the metric latch happened in the same clock
//                edge, meaning the ACS computed on the old rx0 while new metrics
//                were being registered - effectively lagging the received symbol
//                by one step. Fix: rx0 is pre-loaded at the END of the preceding
//                state (SMU_DONE / reset) so the ACS has a full cycle to settle
//                before metrics are latched.
//   - BUG 5 FIX: decoded_bits bit placement now correctly handles the final
//                (potentially shorter) block. The write index is clamped so
//                bits never land outside [0:1023].
//////////////////////////////////////////////////////////////////////////////////


module viterbiDecoder #(parameter K = 3)(
    input  logic clk,
    input  logic rst,
    input  logic en,
    input  logic [2047:0] encoded_bits,//formerly [31:0] encoded_bits [0:63]
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
    localparam int tb = (K*5) + 1;
    localparam NUM_STATES = 1 << (K-1);
    localparam STATE_BITS = K-1;

    // Total bits remaining to process (counts down by tb each traceback block)
    logic [10:0] num_bits;

    logic [10:0] path_metrics         [0:(1 << (K-1)) - 1];
    logic [10:0] updated_path_metrics [0:(1 << (K-1)) - 1];
    logic        branch_bits          [0:(1 << (K-1)) - 1];
    logic        acs_en;

    // ------------------------------------------------------------------
    // BUG 2 FIX: rx0 is loaded at the END of the previous state so the
    // ACS combinational logic has a full clock cycle to compute
    // updated_path_metrics before we latch them in SMU_IDLE.
    //
    // Concretely:
    //   - On reset:   rx0 <= encoded_bits[0][31:30]   (bit-pair 0 of block 0)
    //   - In SMU_IDLE at time_step N: we latch updated_path_metrics (computed
    //     from the rx0 that was loaded last cycle), THEN load the NEXT rx0 for
    //     time_step N+1.
    //   - In SMU_DONE (when starting a new traceback block): rx0 is loaded for
    //     time_step 0 of the new block so it is ready when SMU_IDLE begins.
    //
    // This matches the original intent: each rx0 must be stable for one full
    // cycle before its corresponding path metrics are latched.
    // ------------------------------------------------------------------
    logic [1:0] rx0;

    logic [6:0] time_step;
    logic [6:0] tb_timer;
    logic [6:0] tb_index;
    logic       tb_done;
    logic       tb_rdy;

    logic smu_en;
    logic smu_rst;
    logic tb_active;

    logic [STATE_BITS-1:0] best_state;
    logic [10:0]           decoder_counter;

    logic smu_tb_valid;
    logic smu_tb_bit;

    smu_state_t smu_state;

    logic [K-2:0] curr_state [0:(1 << (K-1)) - 1];

    logic [STATE_BITS-1:0] min_state;
    logic [10:0]           min_metric;
    int                    active_len;

    integer i, k;

    // -----------------------------
    // Best-state (min metric) finder
    // -----------------------------
    always_comb begin
        min_metric = path_metrics[0];
        min_state  = '0;
        for (i = 1; i < NUM_STATES; i = i + 1) begin
            if (path_metrics[i] <= min_metric) begin
                min_metric = path_metrics[i];
                min_state  = i[STATE_BITS-1:0];
            end
        end
    end

    // -----------------------------
    // Initialize states
    // -----------------------------
    genvar j;
    generate
        for (j = 0; j < 2**(K-1); j = j + 1) begin : STATE_BLOCK
            assign curr_state[j] = j[STATE_BITS-1:0];
        end
    endgenerate

    // -----------------------------
    // SMU FSM
    // -----------------------------
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            smu_en          <= 0;
            smu_rst         <= 1;
            smu_state       <= SMU_START;
            tb_timer        <= 0;
            time_step       <= 0;
            tb_index        <= 0;
            tb_done         <= 0;
            done            <= 0;
            acs_en          <= 1;
            decoder_counter <= 0;
            num_bits        <= 11'd1024;

            // BUG 2 FIX: Pre-load rx0 for time_step 0 so ACS is ready on
            // the very first SMU_IDLE cycle.
            rx0 <= encoded_bits[1:0];

            path_metrics[0] <= 0;
            for (k = 1; k < (1 << (K-1)); k = k + 1) begin
                path_metrics[k] <= 11'hff;
            end
        end else begin
            smu_rst <= 0;
            case (smu_state)
                SMU_START: begin
                    smu_state <= SMU_IDLE;
                end

                SMU_IDLE: begin
                    smu_en <= 0;
                    active_len = (num_bits >= tb) ? tb : num_bits;

                    if (time_step < active_len) begin
                    // Step 1: Load rx0 for the CURRENT time_step (combinatorially feeds ACS this cycle)

                    rx0 <= encoded_bits[(tb_index*tb)+(2*time_step)+1 -: 2];

                    // Step 2: On the NEXT cycle the ACS will have registered updated_path_metrics.
                    //         Latch them into path_metrics so the cycle after that sees updated weights.
                    //         But we must skip the very first cycle (time_step==0) since updated_path
                    //         hasn't been computed yet - use a one-cycle delay flag instead.
                    if (time_step > 0) begin
                        for (int m = 0; m < NUM_STATES; m++) begin
                             path_metrics[m] <= updated_path_metrics[m];
                        end
                     end

                    time_step <= time_step + 1;

                    if (time_step == active_len - 1) begin
                        best_state <= min_state;
                    end
                    end else begin
                    // Final latch before leaving - capture the last ACS output
                        for (int m = 0; m < NUM_STATES; m++) begin
                     path_metrics[m] <= updated_path_metrics[m];
                     end
                    num_bits  <= (num_bits >= tb) ? (num_bits - tb) : 0;
                    smu_en    <= 1;
                    acs_en    <= 0;
                    time_step <= 0;
                    smu_state <= SMU_TRACEBACK;
                    end
                    end

                SMU_TRACEBACK: begin
                    smu_en <= 0;
                    if (smu_tb_valid) begin

                        begin
                            automatic logic [10:0] base = tb_index * tb;
                            automatic logic [10:0] idx  = base + (tb - 1) - decoder_counter;
                            if (idx < 1024 && decoder_counter < tb) begin
                                decoded_bits[idx] <= smu_tb_bit;
                                decoder_counter   <= decoder_counter + 1;
                            end
                        end
                    end
                    if (!tb_active) begin
                        decoder_counter <= 0;
                        smu_state       <= SMU_DONE;
                        tb_index        <= tb_index + 1;
                    end
                end

                SMU_DONE: begin
                    if ((tb_index) * tb < 1024) begin
                        smu_en    <= 0;
                        tb_done   <= 0;
                        acs_en    <= 1;
                        smu_state <= SMU_START;
                        time_step <= 0;
                        // BUG 2 FIX: Pre-load rx0 for time_step 0 of the new
                        // block so the ACS has a full cycle before the first
                        // SMU_IDLE metric latch.
                        rx0 <= encoded_bits[tb_index*tb+1 -:2];
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
    genvar gi;
    generate
        for (gi = 0; gi < 2**(K-1); gi = gi + 1) begin : ACS_BLOCK
            localparam int pthmet0 = gi >> 1;
            localparam int pthmet1 = pthmet0 + (NUM_STATES >> 1);
            acs #(.K(K)) u_acs (
                .clk(clk),
                .rst(rst),
                .en(acs_en),
                .rx(rx0),
                .curr_state(curr_state[gi]),
                .path_weight0(path_metrics[pthmet0]),
                .path_weight1(path_metrics[pthmet1]),
                .branch_bit(branch_bits[gi]),
                .updated_path(updated_path_metrics[gi])
            );
        end
    endgenerate

    // -----------------------------
    // SMU
    // -----------------------------
    SMU #(.TB_DEPTH(K*5 + 1)) smu0 (
        .clk(clk),
        .rst(smu_rst),
        .write_en(acs_en),
        .sel_in(branch_bits),
        .index(tb_index),
        .tb_start(smu_en),
        .tb_state_start(best_state),
        .tb_bit(smu_tb_bit),
        .tb_valid(smu_tb_valid),
        .tb_active(tb_active)
    );

endmodule
