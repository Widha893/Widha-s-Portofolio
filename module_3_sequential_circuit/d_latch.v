//==========================================================================
//  d_latch.v  --  D latch (Module 1, section 2.b)
//
//  Characteristic equation :  Q(t+1) = D          (while C = 1)
//  Reference figures       :  Figure 1.5   (NAND circuit)
//                             Figure 1.6   (block symbol)
//                             Figure 1.5.c (hold mode / transparent mode)
//  Reference table         :  Table 1.2
//
//  The control input C is ACTIVE HIGH: the latch is transparent while
//  C = 1 and holds its value while C = 0.  It has no forbidden state,
//  because the inverter in the D path guarantees that the internal S and R
//  signals are always opposite.
//==========================================================================
`timescale 1ns / 1ps


//--------------------------------------------------------------------------
//  Gate level -- NAND gates with an inverter in the D path (Figure 1.5)
//--------------------------------------------------------------------------
module d_latch_gate (
    input  wire D,
    input  wire C,      // enable / clock, active HIGH
    output wire Q,
    output wire QN
);

    wire d_n;           // complement of D
    wire s_n, r_n;      // active-low set / reset for the internal NAND latch

    not #1  g0 (d_n, D);
    nand #1 g1 (s_n, D  , C);
    nand #1 g2 (r_n, d_n, C);

    nand #1 g3 (Q , s_n, QN);
    nand #1 g4 (QN, r_n, Q );

endmodule


//--------------------------------------------------------------------------
//  Gate level -- the simplest D latch, without any control signal
//  (Figure 1.5.a, Table 1.2.a).  Q always follows D.
//--------------------------------------------------------------------------
module d_latch_nocontrol_gate (
    input  wire D,
    output wire Q,
    output wire QN
);

    wire d_n;

    not #1  g0 (d_n, D);
    nand #1 g1 (Q , d_n, QN);   // D' acts as the active-low SET
    nand #1 g2 (QN, D  , Q );   // D  acts as the active-low RESET

endmodule


//--------------------------------------------------------------------------
//  Behavioural model (Table 1.2)
//--------------------------------------------------------------------------
module d_latch (
    input  wire D,
    input  wire C,
    output reg  Q,
    output wire QN
);

    assign QN = ~Q;

    always @* begin
        if (C) Q = D;       // transparent; no else -> latch is inferred
    end

endmodule
