`timescale 1ns / 1ps
// Testbench for top_seq_mult

module tb_seq_mult;
    reg        clk = 0;
    reg        btnC = 0, btnU = 0;
    reg  [7:0] sw = 0;
    wire [15:0] led;
    wire [3:0] an;
    wire [6:0] seg;
    wire       dp;

    top_seq_mult #(.REFRESH_DIV(2)) dut (
        .clk(clk), .btnC(btnC), .btnU(btnU), .sw(sw),
        .led(led), .an(an), .seg(seg), .dp(dp));

    always #5 clk = ~clk;   // 100 MHz

    // set A and B, press start, wait for done
    task multiply(input [3:0] a, input [3:0] b);
        begin
            sw = {a, b};
            #20 btnC = 1; #30 btnC = 0;
            wait (led[15] == 1);
            #100;
        end
    endtask

    initial begin
        $dumpfile("tb_seq_mult.vcd");
        $dumpvars(0, tb_seq_mult);
        btnU = 1; #30; btnU = 0;
        multiply(4'd3,  4'd5);    // 15
        multiply(4'd7,  4'd6);    // 42
        multiply(4'd9,  4'd0);    // 0
        multiply(4'd12, 4'd11);   // 132
        multiply(4'd15, 4'd15);   // 225
        $finish;
    end
endmodule
