`timescale 1ns / 1ps

/*
 * AXI4-Stream UART
 */
module uart_tx #(parameter DATA_WIDTH = 8)
(
    input  logic                   clk,
    input  logic                   rst,

    /*
     * AXI input
     */
    input  logic [DATA_WIDTH-1:0]  s_axis_tdata,
    input  logic                   s_axis_tvalid,
    output logic                   s_axis_tready,

    /*
     * UART interface
     */
    output logic                   txd,

    /*
     * Status
     */
    output logic                   busy,

    /*
     * Configuration
     */
    input  logic [15:0]            prescale
);

logic s_axis_tready_reg = 0;

logic txd_reg = 1;

logic busy_reg = 0;

logic [DATA_WIDTH:0] data_reg = 0;
logic [18:0] prescale_reg = 0;
logic [3:0] bit_cnt = 0;

assign s_axis_tready = s_axis_tready_reg;
assign txd = txd_reg;

assign busy = busy_reg;

always @(posedge clk) begin
    if (rst) begin
        s_axis_tready_reg <= 0;
        txd_reg <= 1;
        prescale_reg <= 0;
        bit_cnt <= 0;
        busy_reg <= 0;
    end else begin
        if (prescale_reg > 0) begin
            s_axis_tready_reg <= 0;
            prescale_reg <= prescale_reg - 1;
        end else if (bit_cnt == 0) begin
            s_axis_tready_reg <= 1;
            busy_reg <= 0;

            if (s_axis_tvalid) begin
                s_axis_tready_reg <= !s_axis_tready_reg;
                prescale_reg <= (prescale << 3)-1;
                bit_cnt <= DATA_WIDTH+1;
                data_reg <= {1'b1, s_axis_tdata};
                txd_reg <= 0;
                busy_reg <= 1;
            end
        end else begin
            if (bit_cnt > 1) begin
                bit_cnt <= bit_cnt - 1;
                prescale_reg <= (prescale << 3)-1;
                {data_reg, txd_reg} <= {1'b0, data_reg};
            end else if (bit_cnt == 1) begin
                bit_cnt <= bit_cnt - 1;
                prescale_reg <= (prescale << 3);
                txd_reg <= 1;
            end
        end
    end
end

endmodule