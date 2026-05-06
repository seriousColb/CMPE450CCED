`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Colby J. Martin
// 
// Create Date: 12/14/2025 11:20:49 AM
// Design Name: 
// Module Name: SMU
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
//   - BUG 1 FIX: tb_bit and tb_state now use a combinatorial wire (decision_comb)
//                so both are derived from the same un-updated tb_state/tb_index_reg,
//                preventing a one-cycle stale-read error during traceback.
//   - BUG 3 FIX: Changed blocking assignment (=) on wr_ptr in SMU_IDLE to
//                non-blocking (<=) to match always_ff semantics and avoid
//                simulation/synthesis mismatch.
//   - BUG 4 FIX: Removed conflicting double non-blocking assignment to wr_ptr
//                at traceback end. wr_ptr is now set to a single unambiguous
//                value based on whether we re-enter WRITE or not.
//////////////////////////////////////////////////////////////////////////////////


module SMU #(parameter TB_DEPTH = 16, K = 3)(
    input  logic        clk,
    input  logic        rst,

    // Write interface
    input  logic        write_en,
    input  logic        sel_in[0:(2**(K-1))-1],
    input  logic        index,

    // Traceback control
    input  logic        tb_start,
    input  logic [K-2:0]  tb_state_start,

    // Traceback output
    output logic        tb_bit,
    output logic        tb_valid,
    output logic        tb_active
);

    //States for FSM
    typedef enum logic [2:0] {
    START_SMU,
    SMU_IDLE,
    WRITE,
    TRACEBACK
    } smu_state_t;

    // survivor_mem[time][state]
    logic [(2**(K-1))-1:0] survivor_mem [0:TB_DEPTH-1];
    logic [$clog2(TB_DEPTH):0] tb_count;
    logic [$clog2(TB_DEPTH)-1:0] wr_ptr;
    logic [$clog2(TB_DEPTH)-1:0] tb_index_reg;
    logic [K-2:0] tb_state;
    logic decision;

    // ------------------------------------------------------------------
    // BUG 1 FIX: Combinatorial wire for the current survivor bit.
    // Using this instead of reading survivor_mem directly inside always_ff
    // ensures tb_bit and the tb_state shift both see the SAME (current-cycle)
    // tb_state and tb_index_reg, before either is updated by non-blocking
    // assignments. Previously, tb_bit and the tb_state next-value both read
    // survivor_mem[tb_index_reg][tb_state], but tb_index_reg was also being
    // decremented in the same block - causing the output to be off by one step.
    // ------------------------------------------------------------------
    logic decision_comb;
    assign decision_comb = survivor_mem[tb_index_reg][tb_state];

    smu_state_t smu_state;

    // Helper task to pack sel_in into survivor_mem - avoids duplicating
    // the large case statement in both branches of WRITE.
    // (Inlined below since SV tasks inside always_ff can be tricky with
    //  some tools; kept as a case block but referenced once via a flag.)

    // -----------------------------
    // Traceback logic
    // -----------------------------
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            tb_count     <= 1'b0;
            tb_state     <= '0;
            tb_bit       <= 1'b0;
            tb_valid     <= 1'b0;
            tb_active    <= 1'b0;
            tb_index_reg <= K*5;
            wr_ptr       <= '0;
            smu_state    <= START_SMU;
        end else begin
            case (smu_state)
                START_SMU: begin
                    if (write_en == 1) begin
                        smu_state <= WRITE;
                        tb_count  <= TB_DEPTH;
                        tb_state  <= tb_state_start;
                    end else begin
                        smu_state <= SMU_IDLE;
                    end
                end

                WRITE: begin
                    if (wr_ptr == TB_DEPTH-1) begin
                        // Last write slot - pack sel_in, then begin traceback
                        case (K)
                            7: survivor_mem[wr_ptr] <= { sel_in[63], sel_in[62], sel_in[61], sel_in[60],
                                sel_in[59], sel_in[58], sel_in[57], sel_in[56], sel_in[55], sel_in[54],
                                sel_in[53], sel_in[52], sel_in[51], sel_in[50], sel_in[49], sel_in[48], sel_in[47],
                                sel_in[46], sel_in[45], sel_in[44], sel_in[43], sel_in[42], sel_in[41], sel_in[40],
                                sel_in[39], sel_in[38], sel_in[37], sel_in[36], sel_in[35], sel_in[34], sel_in[33],
                                sel_in[32], sel_in[31], sel_in[30], sel_in[29], sel_in[28], sel_in[27], sel_in[26],
                                sel_in[25], sel_in[24], sel_in[23], sel_in[22], sel_in[21], sel_in[20], sel_in[19],
                                sel_in[18], sel_in[17], sel_in[16], sel_in[15], sel_in[14], sel_in[13], sel_in[12],
                                sel_in[11], sel_in[10], sel_in[9],  sel_in[8],  sel_in[7],  sel_in[6],  sel_in[5],
                                sel_in[4],  sel_in[3],  sel_in[2],  sel_in[1],  sel_in[0] };
                            5: survivor_mem[wr_ptr] <= { sel_in[15], sel_in[14], sel_in[13], sel_in[12],
                                sel_in[11], sel_in[10], sel_in[9], sel_in[8], sel_in[7], sel_in[6], sel_in[5],
                                sel_in[4], sel_in[3], sel_in[2], sel_in[1], sel_in[0] };
                            4: survivor_mem[wr_ptr] <= { sel_in[7], sel_in[6], sel_in[5], sel_in[4],
                                sel_in[3], sel_in[2], sel_in[1], sel_in[0] };
                            default: survivor_mem[wr_ptr] <= {sel_in[3], sel_in[2], sel_in[1], sel_in[0]};
                        endcase
                        tb_active    <= 1'b1;
                        tb_valid     <= 1'b0;
                        tb_count     <= TB_DEPTH;
                        tb_state     <= tb_state_start;
                        tb_index_reg <= TB_DEPTH - 1;
                        smu_state    <= TRACEBACK;
                    end else begin
                        // Normal write
                        case (K)
                            7: survivor_mem[wr_ptr] <= { sel_in[63], sel_in[62], sel_in[61], sel_in[60],
                                sel_in[59], sel_in[58], sel_in[57], sel_in[56], sel_in[55], sel_in[54],
                                sel_in[53], sel_in[52], sel_in[51], sel_in[50], sel_in[49], sel_in[48], sel_in[47],
                                sel_in[46], sel_in[45], sel_in[44], sel_in[43], sel_in[42], sel_in[41], sel_in[40],
                                sel_in[39], sel_in[38], sel_in[37], sel_in[36], sel_in[35], sel_in[34], sel_in[33],
                                sel_in[32], sel_in[31], sel_in[30], sel_in[29], sel_in[28], sel_in[27], sel_in[26],
                                sel_in[25], sel_in[24], sel_in[23], sel_in[22], sel_in[21], sel_in[20], sel_in[19],
                                sel_in[18], sel_in[17], sel_in[16], sel_in[15], sel_in[14], sel_in[13], sel_in[12],
                                sel_in[11], sel_in[10], sel_in[9],  sel_in[8],  sel_in[7],  sel_in[6],  sel_in[5],
                                sel_in[4],  sel_in[3],  sel_in[2],  sel_in[1],  sel_in[0] };
                            5: survivor_mem[wr_ptr] <= { sel_in[15], sel_in[14], sel_in[13], sel_in[12],
                                sel_in[11], sel_in[10], sel_in[9], sel_in[8], sel_in[7], sel_in[6], sel_in[5],
                                sel_in[4], sel_in[3], sel_in[2], sel_in[1], sel_in[0] };
                            4: survivor_mem[wr_ptr] <= { sel_in[7], sel_in[6], sel_in[5], sel_in[4],
                                sel_in[3], sel_in[2], sel_in[1], sel_in[0] };
                            default: survivor_mem[wr_ptr] <= {sel_in[3], sel_in[2], sel_in[1], sel_in[0]};
                        endcase
                        wr_ptr <= wr_ptr + 1'b1;
                    end
                end

                TRACEBACK: begin
                    if (tb_count == 0) begin
                        // --------------------------------------------------
                        // BUG 4 FIX: Previously wr_ptr was assigned 0 AND
                        // wr_ptr+1 in the same always_ff block (double
                        // non-blocking), causing the +1 to win with the old
                        // value, not the reset value. Now we assign a single
                        // unambiguous value: 1 if re-entering WRITE (since
                        // slot 0 has already been written conceptually), or 0
                        // if going idle.
                        // --------------------------------------------------
                        tb_active <= 1'b0;
                        tb_valid  <= 1'b0;
                        if (write_en == 1) begin
                            smu_state <= WRITE;
                            wr_ptr    <= 1;   // slot 0 counted as already consumed
                        end else begin
                            smu_state <= SMU_IDLE;
                            wr_ptr    <= 0;
                        end
                    end else begin
                        // --------------------------------------------------
                        // BUG 1 FIX: Use decision_comb (combinatorial wire)
                        // so that tb_bit and the tb_state shift are both based
                        // on the current (pre-update) tb_state and tb_index_reg.
                        // Previously, reading survivor_mem[tb_index_reg][tb_state]
                        // twice inside always_ff after also decrementing
                        // tb_index_reg caused a one-step offset between the
                        // traced state path and the output bit.
                        // --------------------------------------------------
                        decision <= decision_comb;
                        tb_bit       <= decision_comb;
                        tb_state     <= {decision_comb, tb_state[K-2:1]};
                        tb_index_reg <= tb_index_reg - 1;
                        tb_valid     <= 1'b1;
                        tb_count     <= tb_count - 1'b1;
                    end
                end

                SMU_IDLE: begin
                    if (write_en == 1) begin
                        smu_state <= WRITE;
                        wr_ptr    <= wr_ptr + 1'b1;  // BUG 3 FIX: was blocking (=), now non-blocking (<=)
                        tb_count  <= TB_DEPTH;
                    end else begin
                        smu_state <= SMU_IDLE;
                    end
                end

            endcase
        end
    end

endmodule
