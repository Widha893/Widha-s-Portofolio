//==========================================================================
//  d_ff.v  --  Edge-triggered D flip-flop (Module 1, section 4)
//
//  Characteristic equation :  Q(t+1) = D         (at the active clock edge)
//  Reference figures       :  Figure 1.8  (positive edge, master-slave)
//                             Figure 1.9  (timing behaviour)
//                             Figure 1.11 (negative edge)
//                             Figure 1.12 (with preset and clear)
//                             Figure 1.13 (with enable)
//  Reference tables        :  Table 1.3, 1.4, 1.4.a, 1.5
//
//  The circuit is a pair of D latches.  The master is transparent while
//  CLK = 0 and the slave while CLK = 1, so the output can only change at
//  the RISING edge of CLK.
//==========================================================================
`timescale 1ns / 1ps


//--------------------------------------------------------------------------
//  Gate level -- master-slave pair of D latches (Figure 1.8 b)
//--------------------------------------------------------------------------
module d_ff_gate (
    input  wire D,
    input  wire CLK,
    output wire Q,
    output wire QN
);

    wire clk_n;         // inverted clock for the master
    wire qm, qmn;       // master outputs

    not #1 g0 (clk_n, CLK);

    d_latch_gate master (.D(D),  .C(clk_n), .Q(qm), .QN(qmn));
    d_latch_gate slave  (.D(qm), .C(CLK),   .Q(Q),  .QN(QN));

endmodule


//--------------------------------------------------------------------------
//  Gate level -- negative-edge-triggered version (Figure 1.11 b).
//  Only the clock is inverted with respect to the circuit above.
//--------------------------------------------------------------------------
module d_ff_neg_gate (
    input  wire D,
    input  wire CLK,
    output wire Q,
    output wire QN
);

    wire clk_n;
    wire qm, qmn;

    not #1 g0 (clk_n, CLK);

    d_latch_gate master (.D(D),  .C(CLK),   .Q(qm), .QN(qmn));
    d_latch_gate slave  (.D(qm), .C(clk_n), .Q(Q),  .QN(QN));

endmodule


//--------------------------------------------------------------------------
//  Behavioural model, positive edge (Table 1.3)
//--------------------------------------------------------------------------
module d_ff (
    input  wire D,
    input  wire CLK,
    output reg  Q,
    output wire QN
);

    assign QN = ~Q;

    always @(posedge CLK) begin
        Q <= D;                 // Q(t+1) = D
    end

endmodule


//--------------------------------------------------------------------------
//  Behavioural model with asynchronous preset and clear, both ACTIVE LOW
//  (Figure 1.12, Table 1.4.a), and a synchronous enable (Figure 1.13,
//  Table 1.5).
//
//  PRE_N = CLR_N = 0 is the forbidden combination (race condition): both
//  outputs are driven to 1 and the final state after the inputs are
//  released cannot be predicted.
//--------------------------------------------------------------------------
module d_ff_pce (
    input  wire D,
    input  wire EN,             // synchronous enable, active HIGH
    input  wire CLK,
    input  wire PRE_N,          // asynchronous preset, active LOW
    input  wire CLR_N,          // asynchronous clear,  active LOW
    output reg  Q,
    output wire QN
);

    // In the forbidden state both outputs are high, so QN is not ~Q there.
    assign QN = (~PRE_N & ~CLR_N) ? 1'b1 : ~Q;

    always @(posedge CLK or negedge PRE_N or negedge CLR_N) begin
        if (!PRE_N && !CLR_N) Q <= 1'b1;    // forbidden, both outputs high
        else if (!PRE_N)      Q <= 1'b1;    // asynchronous preset
        else if (!CLR_N)      Q <= 1'b0;    // asynchronous clear
        else if (EN)          Q <= D;       // synchronous operation
        // else                hold
    end

endmodule
