module test;
    reg [7:0] memory [0:15];  // 16 bytes

    initial begin
        $readmemb("data.txt", memory);
        $display("First value: %b", memory[0]);
    end
endmodule