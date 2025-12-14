module SMU #(
    parameter int TB_DEPTH = 16
)(
    input logic        clk,
    input logic        rst,

    // Write interface
    input logic        write_en,
    input logic        sel_in [0:3],     //  bit per state (4 states)

    // Traceback control
    input logic tb_start,
    input logic [1:0] tb_state_start,
    // Traceback output
    output logic        tb_bit,
    output logic        tb_valid
);


    // survivor_mem[time][state]
    logic [3:0] survivor_mem [TB_DEPTH-1:0];

    logic [4:0] wr_ptr;
    logic [4:0] tb_ptr;
    logic [1:0] tb_state;

    // -----------------------------
    // Write survivor decisions
    // -----------------------------
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            wr_ptr <= '0;
        end else if (write_en) begin
            survivor_mem[wr_ptr] <= sel_in;
            wr_ptr <= wr_ptr + 1'b1;
        end
    end
    // -----------------------------
    // Traceback logic
    // -----------------------------
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            tb_ptr   <= '0;
            tb_state <= '0;
            tb_bit   <= 1'b0;
            tb_valid <= 1'b0;
        end else if (tb_start) begin
            tb_ptr   <= wr_ptr - 1'b1;
            tb_state <= tb_state_start;
            tb_valid <= 1'b0;
        end else begin
            tb_bit   <= survivor_mem[tb_ptr][tb_state];
            tb_state <= {tb_bit, tb_state[1]};
            tb_ptr   <= tb_ptr - 1'b1;
            tb_valid <= 1'b1;
        end
    end

endmodule
