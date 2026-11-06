`timescale 1ns / 1ps

// Q1: 4-bit x 4-bit SEQUENTIAL (shift-and-add) multiplier
// Shift-and-add core: one partial product per clock, 4 clocks
module seq_mult_core (
    input  wire       clk,
    input  wire       reset,
    input  wire       start,  
    input  wire [3:0] a,
    input  wire [3:0] b,
    output reg  [7:0] product = 0,
    output reg        done = 0
);
    reg [7:0] mcand = 0;   
    reg [3:0] mplier = 0;  
    reg [2:0] steps = 0;  

    always @(posedge clk) begin
        if (reset) begin
            product <= 0; mcand <= 0; mplier <= 0; steps <= 0; done <= 0;
        end else if (start) begin           // load
            product <= 0;
            mcand   <= {4'b0, a};
            mplier  <= b;
            steps   <= 3'd4;
            done    <= 0;
        end else if (steps != 0) begin      // add and shift
            if (mplier[0]) product <= product + mcand;
            mcand  <= mcand << 1;
            mplier <= mplier >> 1;
            steps  <= steps - 1;
            if (steps == 1) done <= 1;
        end
    end
endmodule

module top_seq_mult #(parameter integer REFRESH_DIV = 100_000) (
    input  wire        clk,
    input  wire        btnC,      // start
    input  wire        btnU,      // reset
    input  wire [7:0]  sw,
    output wire [15:0] led,
    output wire [3:0]  an,
    output wire [6:0]  seg,
    output wire        dp
);
    // turn the start button into a single 1-clock pulse
    reg [2:0] btn_sync = 0;
    always @(posedge clk) btn_sync <= {btn_sync[1:0], btnC};
    wire start = btn_sync[1] & ~btn_sync[2];

    wire [7:0]  product;
    wire        done;
    wire [15:0] bcd;

    seq_mult_core u_mult (
        .clk(clk), .reset(btnU), .start(start),
        .a(sw[7:4]), .b(sw[3:0]), .product(product), .done(done));

    bin2bcd_12bit u_bcd (.bin({4'b0, product}), .bcd(bcd));
    seven_seg_driver #(.REFRESH_DIV(REFRESH_DIV)) u_disp (
        .clk(clk), .bcd(bcd), .an(an), .seg(seg));

    assign led = {done, 7'b0, product};
    assign dp  = 1'b1;
endmodule


// Display parts (from Lab 7)
// 12-bit binary -> 16-bit BCD (double dabble)

module bin2bcd_12bit (
    input  wire [11:0] bin,
    output wire [15:0] bcd
);
    function [15:0] dabble(input [11:0] b);
        integer i;
        begin
            dabble = 0;
            for (i = 11; i >= 0; i = i - 1) begin
                if (dabble[3:0]   >= 5) dabble[3:0]   = dabble[3:0]   + 3;
                if (dabble[7:4]   >= 5) dabble[7:4]   = dabble[7:4]   + 3;
                if (dabble[11:8]  >= 5) dabble[11:8]  = dabble[11:8]  + 3;
                if (dabble[15:12] >= 5) dabble[15:12] = dabble[15:12] + 3;
                dabble = {dabble[14:0], b[i]};
            end
        end
    endfunction
    assign bcd = dabble(bin);
endmodule

// 4-digit 7-segment driver (anodes/cathodes active-low)
module seven_seg_driver #(parameter integer REFRESH_DIV = 100_000) (
    input  wire        clk,
    input  wire [15:0] bcd,
    output reg  [3:0]  an,
    output wire [6:0]  seg
);
    reg [31:0] prescale = 0;
    reg [1:0]  sel = 0;
    always @(posedge clk) begin
        if (prescale == REFRESH_DIV - 1) begin
            prescale <= 0;  sel <= sel + 1;
        end else
            prescale <= prescale + 1;
    end

    reg [3:0] digit;
    always @(*) begin
        case (sel)
            2'd0: begin an = 4'b1110; digit = bcd[3:0];   end
            2'd1: begin an = 4'b1101; digit = bcd[7:4];   end
            2'd2: begin an = 4'b1011; digit = bcd[11:8];  end
            2'd3: begin an = 4'b0111; digit = bcd[15:12]; end
        endcase
    end

    function [6:0] seg_lut(input [3:0] d);
        case (d)                    //  gfedcba
            4'd0:    seg_lut = 7'b1000000;
            4'd1:    seg_lut = 7'b1111001;
            4'd2:    seg_lut = 7'b0100100;
            4'd3:    seg_lut = 7'b0110000;
            4'd4:    seg_lut = 7'b0011001;
            4'd5:    seg_lut = 7'b0010010;
            4'd6:    seg_lut = 7'b0000010;
            4'd7:    seg_lut = 7'b1111000;
            4'd8:    seg_lut = 7'b0000000;
            4'd9:    seg_lut = 7'b0010000;
            default: seg_lut = 7'b1111111;
        endcase
    endfunction
    assign seg = seg_lut(digit);
endmodule
