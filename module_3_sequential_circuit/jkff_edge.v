//==========================================================================
//  jkff_edge.v  --  Edge-triggered J-K flip-flop (Module 1, section 10)
//
//  Characteristic equation :  Q(t+1) = J Q(t)' + K' Q(t)
//  Reference figures       :  Figure 1.22   (block diagram and circuit)
//                             Figure 1.23   (timing diagram)
//                             Figure 1.18.e (negative-edge version)
//  Reference tables        :  Table 1.14, 1.10.a
//
//  As stated in the module, this flip-flop uses an edge-triggered D
//  flip-flop internally.  The gate network in front of it computes
//      D = J Q' + K' Q
//  so that the D flip-flop stores the required next state.  Because the
//  D flip-flop samples only at the clock edge, this circuit does not
//  suffer from 1s catching.
//==========================================================================
`timescale 1ns / 1ps


//--------------------------------------------------------------------------
//  Gate level -- input logic plus an edge-triggered D flip-flop
//  (Figure 1.22 b)
//--------------------------------------------------------------------------
module jkff_edge_gate (
    input  wire J,
    input  wire K,
    input  wire CLK,
    output wire Q,
    output wire QN
);

    wire k_n;               // K'
    wire a1, a2;            // J Q'   and   K' Q
    wire d;                 // D = J Q' + K' Q

    not #1 g0 (k_n, K);
    and #1 g1 (a1, J  , QN);
    and #1 g2 (a2, k_n, Q );
    or #1  g3 (d , a1 , a2);

    d_ff_gate u_dff (.D(d), .CLK(CLK), .Q(Q), .QN(QN));

endmodule


//--------------------------------------------------------------------------
//  Gate level -- negative-edge-triggered version (Figure 1.18.e)
//--------------------------------------------------------------------------
module jkff_negedge_gate (
    input  wire J,
    input  wire K,
    input  wire CLK,
    output wire Q,
    output wire QN
);

    wire k_n, a1, a2, d;

    not #1 g0 (k_n, K);
    and #1 g1 (a1, J  , QN);
    and #1 g2 (a2, k_n, Q );
    or #1  g3 (d , a1 , a2);

    d_ff_neg_gate u_dff (.D(d), .CLK(CLK), .Q(Q), .QN(QN));

endmodule


//--------------------------------------------------------------------------
//  Behavioural model, positive edge (Table 1.14)
//--------------------------------------------------------------------------
module jkff_edge (
    input  wire J,
    input  wire K,
    input  wire CLK,
    output reg  Q,
    output wire QN
);

    assign QN = ~Q;

    always @(posedge CLK) begin
        Q <= (J & ~Q) | (~K & Q);       // Q(t+1) = J Q' + K' Q
    end

endmodule
