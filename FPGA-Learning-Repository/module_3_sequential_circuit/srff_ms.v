//==========================================================================
//  srff_ms.v  --  Master-slave S-R flip-flop (Module 1, section 6)
//
//  Characteristic equation :  Q(t+1) = S + R' Q(t)
//  Reference figures       :  Figure 1.14 (clocked S-R flip-flop)
//                             Figure 1.15 (master-slave S-R flip-flop)
//                             Figure 1.16 (timing diagram)
//  Reference tables        :  Table 1.6, 1.6.a, 1.7, 1.8
//
//  This flip-flop is PULSE triggered, not edge triggered.  The master
//  follows S and R during the whole interval in which C = 1, and the value
//  reaches the output only when C returns to 0.  For that reason S and R
//  must be held steady throughout the high phase of C; otherwise a short
//  pulse can be caught by the master (see the 1s-catching demonstration in
//  the J-K master-slave testbench).
//==========================================================================
`timescale 1ns / 1ps


//--------------------------------------------------------------------------
//  Gate level -- a clocked S-R latch, used as master and as slave
//  (the circuit inside the dashed box of Figure 1.14 b)
//--------------------------------------------------------------------------
module sr_latch_clocked_gate (
    input  wire S,
    input  wire R,
    input  wire C,
    output wire Q,
    output wire QN
);

    wire s_n, r_n;

    nand #1 g1 (s_n, S, C);
    nand #1 g2 (r_n, R, C);

    nand #1 g3 (Q , s_n, QN);
    nand #1 g4 (QN, r_n, Q );

endmodule


//--------------------------------------------------------------------------
//  Gate level -- master-slave arrangement (Figure 1.15 b)
//  The master works while C = 1, the slave while C = 0.
//--------------------------------------------------------------------------
module srff_ms_gate (
    input  wire S,
    input  wire R,
    input  wire C,
    output wire Q,
    output wire QN
);

    wire c_n;
    wire qm, qmn;

    not #1 g0 (c_n, C);

    sr_latch_clocked_gate master (.S(S),   .R(R),   .C(C),   .Q(qm), .QN(qmn));
    sr_latch_clocked_gate slave  (.S(qm),  .R(qmn), .C(c_n), .Q(Q),  .QN(QN) );

endmodule


//--------------------------------------------------------------------------
//  Behavioural model (Table 1.8)
//
//  The output changes on the falling edge of C.  Written from the
//  characteristic equation Q(t+1) = S + R' Q(t), with the forbidden
//  combination S = R = 1 flagged as undefined.
//--------------------------------------------------------------------------
module srff_ms (
    input  wire S,
    input  wire R,
    input  wire C,
    output reg  Q,
    output wire QN
);

    assign QN = ~Q;

    always @(negedge C) begin
        if (S & R) Q <= 1'bx;               // forbidden
        else       Q <= S | (~R & Q);       // Q(t+1) = S + R' Q(t)
    end

endmodule
