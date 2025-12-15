`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
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
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module SMU #(
    parameter int TB_DEPTH = 16
)(
    input  logic        clk,
    input  logic        rst,

    // Write interface
    input  logic        write_en,
    input  logic        sel_in [0:3],
    input  logic        index,

    // Traceback control
    input  logic        tb_start,
    input  logic [1:0]  tb_state_start,

    // Traceback output
    output logic        tb_bit,
    output logic        tb_valid,
    output logic        tb_active
);

    // survivor_mem[time][state]
    logic [3:0] survivor_mem [0:TB_DEPTH-1];
    logic [$clog2(TB_DEPTH):0] tb_count;
    logic [$clog2(TB_DEPTH)-1:0] wr_ptr;
    logic [$clog2(TB_DEPTH)-1:0] tb_ptr;
    logic [1:0] tb_state;
    logic [4:0] wr_en;
    logic stop_write;
    

    // -----------------------------
    // Write survivor decisions
    // -----------------------------
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr <= '0;
            stop_write <=0;
        end else if (write_en) begin
            survivor_mem[wr_ptr] <= { sel_in[3], sel_in[2], sel_in[1], sel_in[0] };
            wr_ptr <= wr_ptr + 1'b1;
            /*if(wr_ptr == TB_DEPTH - 1)begin
                stop_write <= 1;
            end*/
        end
    end

    // -----------------------------
    // Traceback logic
    // -----------------------------
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            tb_ptr    <= '0;
            tb_state  <= '0;
            tb_bit    <= 1'b0;
            tb_valid  <= 1'b0;
            tb_active <= 1'b0;
        end else begin
            tb_valid <= 1'b0;


            // Start traceback (one-shot)
            if (tb_start && !tb_active) begin
                tb_active <= 1'b1;
                tb_ptr    <= TB_DEPTH - 1;
                tb_state  <= tb_state_start;
                tb_count <= wr_ptr;
            end
            // Perform traceback
            else if (tb_active) begin
                 // Output the current bit
                tb_bit   <= survivor_mem[tb_ptr][tb_state];
                tb_state <= { survivor_mem[tb_ptr][tb_state], tb_state[1] };
                tb_valid <= 1'b1;

                // Decrement counters
                tb_ptr   <= tb_ptr - 1'b1;
                tb_count <= tb_count - 1'b1;

                // Stop traceback when last bit has been output
                if (tb_ptr == 0) begin
                    tb_active <= 1'b0;
                    //stop_write <= 0;
                    wr_ptr <= 0;   // stops next cycle
                end
            end
         end
    end

endmodule
