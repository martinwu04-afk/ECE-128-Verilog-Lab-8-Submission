`timescale 1ns / 1ps

// Testbench for top_comb_mult

module tb_comb_mult;
    reg        clk = 0;
    reg  [7:0] sw = 0;
    wire [15:0] led;
    wire [3:0] an;
    wire [6:0] seg;
    wire       dp;

    top_comb_mult #(.REFRESH_DIV(2)) dut (
        .clk(clk), .sw(sw), .led(led), .an(an), .seg(seg), .dp(dp));

    always #5 clk = ~clk;

    initial begin
        $dumpfile("tb_comb_mult.vcd");
        $dumpvars(0, tb_comb_mult);
        sw = {4'd3,  4'd5};  #100;   // 15
        sw = {4'd7,  4'd6};  #100;   // 42
        sw = {4'd9,  4'd0};  #100;   // 0
        sw = {4'd12, 4'd11}; #100;   // 132
        sw = {4'd15, 4'd15}; #100;   // 225
        $finish;
    end
endmodule
