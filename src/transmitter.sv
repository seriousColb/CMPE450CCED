`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Module Name: transmitter
// Description: UART transmitter with double buffer (staging register)
//              allowing one byte to be queued while another is transmitting.
//////////////////////////////////////////////////////////////////////////////////

module transmitter(
    input  logic        clk,      // UART input clock
    input  logic        reset,    // reset signal
    input  logic        transmit, // strobe signal to load new byte (hold high for 1 cycle)
    input  logic [7:0]  data,     // data to transmit
    output logic        TxD,      // serial output, held high when idle
    output logic        busy      // high when staging buffer is full - do not write
);

//-------------------------------------------------------------------------
// Internal signals
//-------------------------------------------------------------------------
logic [3:0]  bitcounter;    // counts bits shifted out (0..10)
logic [13:0] counter;       // baud rate counter, counts to 10415
logic        state;         // current state: 0=idle, 1=transmitting
logic        nextstate;     // next state
logic [9:0]  rightshiftreg; // 10-bit shift register {stop, d7..d0, start}
logic        shift;         // asserted to shift one bit out
logic        load;          // asserted to load staging_reg into shift register
logic        clear;         // asserted to reset bitcounter

// Double buffer
logic [7:0]  staging_reg;   // holds next byte while current one is transmitting
logic        staging_valid; // 1 = staging_reg contains a byte waiting to be sent

assign busy = staging_valid;

//-------------------------------------------------------------------------
// Baud tick + datapath block
//-------------------------------------------------------------------------
always_ff @(posedge clk) begin
    if (reset) begin
        state         <= 0;
        counter       <= 0;
        bitcounter    <= 0;
        staging_valid <= 0;
        staging_reg   <= 0;
        rightshiftreg <= 0;
    end
    else begin

        // --- Staging write (every cycle, not gated by baud tick) ----------
        // Accept a new byte whenever transmit is strobed and staging is empty
        if (transmit && !staging_valid) begin
            staging_reg   <= data;
            staging_valid <= 1;
        end

        // --- Baud tick ---------------------------------------------------
        counter <= counter + 1;
        if (counter >= 10415) begin
            counter <= 0;
            state   <= nextstate;

            if (load) begin
                // Promote staging buffer into shift register
                rightshiftreg <= {1'b1, staging_reg, 1'b0};
                staging_valid <= 0;   // staging slot is now free
            end

            if (clear)
                bitcounter <= 0;

            if (shift) begin
                rightshiftreg <= rightshiftreg >> 1;
                bitcounter    <= bitcounter + 1;
            end
        end

    end
end

//-------------------------------------------------------------------------
// State machine (combinational - note always @* not always @posedge clk)
//-------------------------------------------------------------------------
always @(*) begin
    // Defaults
    load      = 0;
    shift     = 0;
    clear     = 0;
    TxD       = 1;
    nextstate = state;

    case (state)
        0: begin // Idle
            if (staging_valid) begin
                nextstate = 1;
                load      = 1;   // load staging_reg → rightshiftreg on next baud tick
            end
        end

        1: begin // Transmitting
            if (bitcounter >= 10) begin
                // Transmission complete
                if (staging_valid) begin
                    // Another byte is waiting - reload immediately, no idle gap
                    nextstate = 1;
                    load      = 1;
                end else begin
                    nextstate = 0;
                    clear     = 1;
                end
            end else begin
                // Still shifting
                nextstate = 1;
                TxD       = rightshiftreg[0];
                shift     = 1;
            end
        end

        default: nextstate = 0;
    endcase
end

endmodule
