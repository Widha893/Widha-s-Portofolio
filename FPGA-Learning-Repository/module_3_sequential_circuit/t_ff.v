//==========================================================================
//  t_ff.v  --  T (toggle) flip-flop (Module 1, section 11)
//
//  Characteristic equation :  Q(t+1) = Q(t)'
//  Reference figures       :  Figure 1.24 a (T FF from a D flip-flop)
//                             Figure 1.24 b (T FF from a J-K flip-flop)
//
//  This is the unconditional toggle: the flip-flop complements its state
//  at every active clock edge.  Because the output changes once per full
//  clock pulse, the frequency at Q is half the clock frequency, which is
//  what makes it the basic element of a binary counter (Figure 1.20.d).
//==========================================================================
`timescale 1ns / 1ps


//--------------------------------------------------------------------------
//  Gate level -- a D flip-flop with D tied to Q' (Figure 1.24 a)
//--------------------------------------------------------------------------
module t_ff_gate (
    input  wire CLK,
    output wire Q,
    output wire QN
);

    d_ff_gate u_dff (.D(QN), .CLK(CLK), .Q(Q), .QN(QN));

endmodule


//--------------------------------------------------------------------------
//  Gate level -- a J-K flip-flop with J = K = 1 (Figure 1.24 b)
//--------------------------------------------------------------------------
module t_ff_from_jk_gate (
    input  wire CLK,
    output wire Q,
    output wire QN
);

    jkff_edge_gate u_jk (.J(1'b1), .K(1'b1), .CLK(CLK), .Q(Q), .QN(QN));

endmodule


//--------------------------------------------------------------------------
//  Behavioural model
//--------------------------------------------------------------------------
module t_ff (
    input  wire CLK,
    output reg  Q,
    output wire QN
);

    assign QN = ~Q;

    always @(posedge CLK) begin
        Q <= ~Q;                // Q(t+1) = Q(t)'
    end

endmodule
