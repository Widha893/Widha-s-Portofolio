//==========================================================================
//  jkff_ms.v  --  J-K master-slave flip-flop (Module 1, section 9)
//
//  Characteristic equation :  Q(t+1) = J Q(t)' + K' Q(t)
//  Reference figures       :  Figure 1.19   (NAND circuit)
//                             Figure 1.20   (block diagram and circuit)
//                             Figure 1.20.d (frequency divider)
//                             Figure 1.20.e (IC 7476 pin assignment)
//                             Figure 1.21   (1s catching / 0s catching)
//  Reference tables        :  Table 1.12, 1.13, 1.13.a
//
//  Three feedback paths are present, exactly as described in the module:
//    * the flip-flop feedback of the master section,
//    * the flip-flop feedback of the slave section,
//    * the toggle feedback, in which the slave outputs Q and Q' are
//      returned to the 3-input NAND gates at the input of the master.
//  It is the toggle feedback that turns J = K = 1 into a toggle instead of
//  the forbidden state of the S-R flip-flop.
//==========================================================================
`timescale 1ns / 1ps


//--------------------------------------------------------------------------
//  Gate level (Figure 1.19)
//--------------------------------------------------------------------------
module jkff_ms_gate (
    input  wire J,
    input  wire K,
    input  wire C,
    output wire Q,
    output wire QN
);

    wire c_n;
    wire s_n, r_n;          // master input gates (active low)
    wire qm, qmn;           // master outputs
    wire sm_n, rm_n;        // slave input gates (active low)

    not #1 g0 (c_n, C);

    // Master input gates: 3 inputs each, including the toggle feedback
    nand #1 g1 (s_n, J, C, QN);
    nand #1 g2 (r_n, K, C, Q );

    // Master latch
    nand #1 g3 (qm , s_n, qmn);
    nand #1 g4 (qmn, r_n, qm );

    // Slave input gates, enabled while C = 0
    nand #1 g5 (sm_n, qm , c_n);
    nand #1 g6 (rm_n, qmn, c_n);

    // Slave latch
    nand #1 g7 (Q , sm_n, QN);
    nand #1 g8 (QN, rm_n, Q );

endmodule


//--------------------------------------------------------------------------
//  Behavioural model (Table 1.13)
//  The output changes on the falling edge of C.
//--------------------------------------------------------------------------
module jkff_ms (
    input  wire J,
    input  wire K,
    input  wire C,
    output reg  Q,
    output wire QN
);

    assign QN = ~Q;

    always @(negedge C) begin
        Q <= (J & ~Q) | (~K & Q);       // Q(t+1) = J Q' + K' Q
    end

endmodule


//--------------------------------------------------------------------------
//  Behavioural model of one half of a 7476 / 74LS76, that is, a J-K
//  master-slave flip-flop with asynchronous preset and clear, both ACTIVE
//  LOW (Figure 1.20.e, Table 1.13.a).
//--------------------------------------------------------------------------
module jkff_ms_7476 (
    input  wire J,
    input  wire K,
    input  wire CLK,
    input  wire PRE_N,          // asynchronous preset, active LOW
    input  wire CLR_N,          // asynchronous clear,  active LOW
    output reg  Q,
    output wire QN
);

    // In the forbidden state both outputs are high, so QN is not ~Q there.
    assign QN = (~PRE_N & ~CLR_N) ? 1'b1 : ~Q;

    always @(negedge CLK or negedge PRE_N or negedge CLR_N) begin
        if (!PRE_N && !CLR_N) Q <= 1'b1;                // forbidden
        else if (!PRE_N)      Q <= 1'b1;                // preset
        else if (!CLR_N)      Q <= 1'b0;                // clear
        else                  Q <= (J & ~Q) | (~K & Q); // synchronous
    end

endmodule
