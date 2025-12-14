module viterbiDecoder #(parameter k = 3) (
    input logic clk,
    input logic rst,
    input logic en,
    input logic [31:0] encoded_bits [0:63], //input encoded bits to be decoded
    output logic [1023:0] decoded_bits, //output decoded bits
    output logic done
);
logic [3:0] tb = 4'b1000; //traceback length setting to 16 for 16bit input
logic [10:0] path_metrics [0:3] = 0; //path metrics for 4 states
logic [10:0] updated_path_metrics [0:3];
logic [15:0][3:0] branch_bits; //store branch bits for each time step and state (16 time steps, 4 states)
logic [3:0] time_step; //current time step
logic [5:0] tb_index = 0; //index for traceback
logic tb_done = 1'b0;
logic smu_en = 1'b0;
logic smu_rst = 1'b1;
logic [1:0] best_state;
logic [9:0] decoder_counter = 0;

logic [1:0] curr_state [0:3];
initial begin
    curr_state[0] = 2'b00;
    curr_state[1] = 2'b01;
    curr_state[2] = 2'b10;
    curr_state[3] = 2'b11;
end

always_ff @(posedge clk or posedge rst) begin
    if(rst) begin
        time_step <= 0;
        path_metrics[0] <= 0; //initial state metric
        path_metrics[1] <= 11'b11111111111; //other states set to max
        path_metrics[2] <= 11'b11111111111;
        path_metrics[3] <= 11'b11111111111;
        done <= 1'b0;
    end
    else if(tb_done) begin
        smu_en <= 1'b1;
        smu_rst <= 1'b0;
        tb_done <= 1'b0;
    end
    else if(en) begin
        decoder_counter <= decoder_counter + 1;

        if(time_step < tb-1) begin
            //perform ACS for each state
            //update path metrics
            path_metrics[0] <= updated_path_metrics[0];
            path_metrics[1] <= updated_path_metrics[1];
            path_metrics[2] <= updated_path_metrics[2];
            path_metrics[3] <= updated_path_metrics[3];
            time_step <= time_step + 1;
        end
        else begin
            if(tb_index < 64)begin
                path_metrics[0] <= updated_path_metrics[0];
                path_metrics[1] <= updated_path_metrics[1];
                path_metrics[2] <= updated_path_metrics[2];
                path_metrics[3] <= updated_path_metrics[3];
                if(path_metrics[0] < path_metrics[1] && path_metrics[0] < path_metrics[2] && path_metrics[0] < path_metrics[3]) begin
                    best_state <= 2'b00;
                end
                else if(path_metrics[1] < path_metrics[0] && path_metrics[1] < path_metrics[2] && path_metrics[1] < path_metrics[3]) begin
                    best_state <= 2'b01;
                end
                else if(path_metrics[2] < path_metrics[0] && path_metrics[2] < path_metrics[1] && path_metrics[2] < path_metrics[3]) begin
                    best_state <= 2'b10;
                end
                else begin
                    best_state <= 2'b11;
                end
                time_step <= 0;
                tb_index <= tb_index + 1;
                tb_done <= 1'b1;
            end
            else begin
                done <= 1'b1;
            end
        end
    end
end
//ACS units for each state

//ACS for state 0 (00 -> 00 and 01 -> 00)
acs acs0(
    .rx(encoded_bits[tb_index][tb_index*2 +:2]),
    .curr_state(curr_state[0]),
    .path_weight0(path_metrics[0]),
    .path_weight1(path_metrics[1]),
    .clk(clk),
    .en(en),
    .rst(rst),
    .branch_bit(branch_bits[time_step][0]),
    .updated_path(updated_path_metrics[0])
); 
//ACS for state 1 (11->01 and 10->01)
acs acs1(
    .rx(encoded_bits[tb_index][tb_index*2 +:2]),
    .curr_state(curr_state[1]),
    .path_weight0(path_metrics[2]),
    .path_weight1(path_metrics[3]),
    .clk(clk),
    .en(en),
    .rst(rst),
    .branch_bit(branch_bits[time_step][1]),
    .updated_path(updated_path_metrics[1])
);

//ACS for state 2 (00->10 and 01->10)
acs acs2(
    .rx(encoded_bits[tb_index][tb_index*2 +:2]),
    .curr_state(curr_state[2]),
    .path_weight0(path_metrics[0]),
    .path_weight1(path_metrics[1]),
    .clk(clk),
    .en(en),
    .rst(rst),
    .branch_bit(branch_bits[time_step][2]),
    .updated_path(updated_path_metrics[2])
);

//ACS for state 3 (11->11 and 10->11)
acs acs3(
    .rx(encoded_bits[tb_index][tb_index*2 +:2]),
    .curr_state(curr_state[3]),
    .path_weight0(path_metrics[2]),
    .path_weight1(path_metrics[3]),
    .clk(clk),
    .en(en),
    .rst(rst),
    .branch_bit(branch_bits[time_step][3]),
    .updated_path(updated_path_metrics[3])
);

SMU #(.TB_DEPTH(16)) smu0(
    .clk(clk),
    .rst(smu_rst),
    .write_en(~smu_en),
    .sel_in(branch_bits[time_step]),
    .tb_start(smu_en),
    .tb_state_start(best_state),
    .tb_bit(decoded_bits[tb_index*2 +:2]),
    .tb_valid(~smu_en)
);
endmodule