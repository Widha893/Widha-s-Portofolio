//==========================================================================
//  sr_latch.v  --  S-R latch (Module 1, section 2.a)
//
//  Characteristic equation :  Q(t+1) = S + R' Q(t)
//  Reference figures       :  Figure 1.2.a (symbol)
//                             Figure 1.2.b (NOR latch)
//                             Figure 1.2.d (cross-coupled NAND latch)
//  Reference tables        :  Table 1.1   (NOR latch, active HIGH)
//                             Table 1.1.a (NAND latch, active LOW)
//
//  NOTE ON THE FORBIDDEN STATE
//  The characteristic equation is only valid for the legal input
//  combinations.  For S = R = 1 the equation predicts Q = 1, but the NOR
//  latch actually drives BOTH outputs low (Table 1.1), which is why that
//  combination is called forbidden: Q and Q' are no longer complementary.
//==========================================================================
`timescale 1ns / 1ps


//--------------------------------------------------------------------------
//  Gate level -- cross-coupled NOR gates (Figure 1.2.b)
//  Drawing convention of the module: R feeds the upper gate whose output is
//  Q, and S feeds the lower gate whose output is Q'.
//--------------------------------------------------------------------------
module sr_latch_nor_gate (
    input  wire S,      // set,   active HIGH
    input  wire R,      // reset, active HIGH
    output wire Q,
    output wire QN      // Q' (complement of Q in every legal state)
);

    nor #1 g1 (Q , R, QN);
    nor #1 g2 (QN, S, Q );

endmodule


//--------------------------------------------------------------------------
//  Gate level -- cross-coupled NAND gates (Figure 1.2.d)
//  Here the inputs are ACTIVE LOW, so they are named S_N and R_N.
//  Forbidden combination: S_N = R_N = 0 (Table 1.1.a).
//--------------------------------------------------------------------------
module sr_latch_nand_gate (
    input  wire S_N,    // set,   active LOW
    input  wire R_N,    // reset, active LOW
    output wire Q,
    output wire QN
);

    nand #1 g1 (Q , S_N, QN);
    nand #1 g2 (QN, R_N, Q );

endmodule


//--------------------------------------------------------------------------
//  Behavioural model -- written directly from Table 1.1
//
//  The "hold" case is deliberately left out of the if-chain so that the
//  synthesiser infers a latch, which is exactly what this circuit is.
//--------------------------------------------------------------------------
module sr_latch (
    input  wire S,
    input  wire R,
    output reg  Q,
    output wire QN
);

    // In the forbidden state a NOR latch pulls both outputs low, so QN is
    // not simply ~Q there.
    assign QN = (S & R) ? 1'b0 : ~Q;

    always @* begin
        if      (S & R) Q = 1'b0;   // forbidden: both outputs go low
        else if (S)     Q = 1'b1;   // set
        else if (R)     Q = 1'b0;   // reset
        // else        hold: Q keeps its previous value
    end

endmodule
