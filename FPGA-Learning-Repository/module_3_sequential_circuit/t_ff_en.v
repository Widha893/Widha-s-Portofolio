//==========================================================================
//  t_ff_en.v  --  T flip-flop with enable (Module 1, section 11)
//
//  Characteristic equation :  Q(t+1) = T Q(t)' + T' Q(t)  =  T (xor) Q(t)
//  Reference figures       :  Figure 1.24 c (T FF using an XOR gate)
//                             Figure 1.24 d (T FF from a J-K FF, J = K = T)
//                             Figure 1.25   (T FF with enable)
//                             Figure 1.26   (functional behaviour)
//  Reference table         :  Table 1.15, 1.16
//
//  The T input decides what happens at the active clock edge:
//      T = 0  ->  the state is held
//      T = 1  ->  the state is complemented
//  In the module this input is also referred to as the enable, because it
//  is what enables the toggling action.
//==========================================================================
`timescale 1ns / 1ps


//--------------------------------------------------------------------------
//  Gate level -- a D flip-flop driven by an XOR gate (Figure 1.24 c)
//--------------------------------------------------------------------------
module t_ff_en_gate (
    input  wire T,
    input  wire CLK,
    output wire Q,
    output wire QN
);

    wire d;                 // D = T xor Q

    xor #1 g0 (d, T, Q);

    d_ff_gate u_dff (.D(d), .CLK(CLK), .Q(Q), .QN(QN));

endmodule


//--------------------------------------------------------------------------
//  Gate level -- a J-K flip-flop with J = K = T (Figure 1.24 d)
//--------------------------------------------------------------------------
module t_ff_en_from_jk_gate (
    input  wire T,
    input  wire CLK,
    output wire Q,
    output wire QN
);

    jkff_edge_gate u_jk (.J(T), .K(T), .CLK(CLK), .Q(Q), .QN(QN));

endmodule


//--------------------------------------------------------------------------
//  Behavioural model (Table 1.16)
//--------------------------------------------------------------------------
module t_ff_en (
    input  wire T,
    input  wire CLK,
    output reg  Q,
    output wire QN
);

    assign QN = ~Q;

    always @(posedge CLK) begin
        Q <= (T & ~Q) | (~T & Q);       // Q(t+1) = T Q' + T' Q
    end

endmodule
