`timescale 1ns / 1ps
//======================================================================
//  shift_registers.v  --  PIPO, SIPO, SISO, PISO, bidirectional, universal
//----------------------------------------------------------------------
//  Module 4 : Sequential Circuit Practice I
//
//  Bit convention : q[3] is the leftmost stage (QA), q[0] the rightmost
//                   (QD). "Shift right" moves data QA -> QB -> QC -> QD.
//  Serial data     : entered least-significant bit first.
//  The structural registers are built from dff_t (clock-to-Q = TPD);
//  universal4 is the behavioural (RTL) form used for synthesis.
//======================================================================

//---------------------------------------------------------- PIPO
module pipo4 (
    input  wire       clk, rstn,
    input  wire       load,             // capture din on the next edge
    input  wire       oe,               // output enable
    input  wire [3:0] din,
    output wire [3:0] q,
    output wire [3:0] dout
);
    wire [3:0] d = load ? din : q;      // hold when load = 0
    dff_t FA (.clk(clk), .rstn(rstn), .d(d[3]), .q(q[3]));
    dff_t FB (.clk(clk), .rstn(rstn), .d(d[2]), .q(q[2]));
    dff_t FC (.clk(clk), .rstn(rstn), .d(d[1]), .q(q[1]));
    dff_t FD (.clk(clk), .rstn(rstn), .d(d[0]), .q(q[0]));
    assign dout = q & {4{oe}};          // four AND gates
endmodule

//---------------------------------------------------------- SIPO
module sipo4 (
    input  wire       clk, rstn,
    input  wire       si,               // serial input
    output wire [3:0] q,
    output wire       so                // serial output = q[0]
);
    dff_t FA (.clk(clk), .rstn(rstn), .d(si),   .q(q[3]));
    dff_t FB (.clk(clk), .rstn(rstn), .d(q[3]), .q(q[2]));
    dff_t FC (.clk(clk), .rstn(rstn), .d(q[2]), .q(q[1]));
    dff_t FD (.clk(clk), .rstn(rstn), .d(q[1]), .q(q[0]));
    assign so = q[0];
endmodule

//---------------------------------------------------------- SISO
module siso4 (
    input  wire clk, rstn, si,
    output wire so
);
    wire [3:0] q;
    sipo4 U (.clk(clk), .rstn(rstn), .si(si), .q(q), .so(so));   // same chain, serial out only
endmodule

//---------------------------------------------------------- PISO
module piso4 (
    input  wire       clk, rstn,
    input  wire       load,             // 1: parallel load, 0: shift out
    input  wire [3:0] din,
    output wire [3:0] q,
    output wire       so
);
    // a 2:1 multiplexer in front of every flip-flop selects load or shift
    wire [3:0] d;
    assign d[3] = load ? din[3] : 1'b0;   // shift in zeros
    assign d[2] = load ? din[2] : q[3];
    assign d[1] = load ? din[1] : q[2];
    assign d[0] = load ? din[0] : q[1];
    dff_t FA (.clk(clk), .rstn(rstn), .d(d[3]), .q(q[3]));
    dff_t FB (.clk(clk), .rstn(rstn), .d(d[2]), .q(q[2]));
    dff_t FC (.clk(clk), .rstn(rstn), .d(d[1]), .q(q[1]));
    dff_t FD (.clk(clk), .rstn(rstn), .d(d[0]), .q(q[0]));
    assign so = q[0];
endmodule

//---------------------------------------------------------- bidirectional
module bidir4 (
    input  wire       clk, rstn,
    input  wire       dir,              // 1: shift right, 0: shift left
    input  wire       sir,              // serial input for shift right (enters at q[3])
    input  wire       sil,              // serial input for shift left  (enters at q[0])
    output wire [3:0] q
);
    wire [3:0] d;
    assign d[3] = dir ? sir  : q[2];
    assign d[2] = dir ? q[3] : q[1];
    assign d[1] = dir ? q[2] : q[0];
    assign d[0] = dir ? q[1] : sil;
    dff_t FA (.clk(clk), .rstn(rstn), .d(d[3]), .q(q[3]));
    dff_t FB (.clk(clk), .rstn(rstn), .d(d[2]), .q(q[2]));
    dff_t FC (.clk(clk), .rstn(rstn), .d(d[1]), .q(q[1]));
    dff_t FD (.clk(clk), .rstn(rstn), .d(d[0]), .q(q[0]));
endmodule

//---------------------------------------------------------- universal (RTL)
//  mode 00 hold | 01 shift right (sir enters at MSB) | 10 shift left | 11 load
module universal4 (
    input  wire       clk, rstn,
    input  wire [1:0] mode,
    input  wire       sir, sil,
    input  wire [3:0] din,
    output reg  [3:0] q
);
    always @(posedge clk or negedge rstn)
        if (!rstn) q <= 4'b0000;
        else case (mode)
            2'b00: q <= q;
            2'b01: q <= {sir, q[3:1]};
            2'b10: q <= {q[2:0], sil};
            2'b11: q <= din;
        endcase
endmodule
