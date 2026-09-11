`timescale 1ns/1ps
module d_latch_tb;

    reg D_G;
    reg C_G;
    reg D;
    reg C;
    reg D_N;

    wire Q_G;
    wire QN_G;
    wire Q;
    wire QN;
    wire Q_N;
    wire QN_N;

    d_latch_gate DL_G (
        .D(D_G),
        .C(C_G),
        .Q(Q_G),
        .QN(QN_G)
    );

    d_latch DL (
        .D(D),
        .C(C),
        .Q(Q),
        .QN(QN)
    );

    d_latch_nocontrol_gate DL_N (
        .D(D_N),
        .Q(Q_N),
        .QN(QN_N)
    );

    initial begin
        $dumpfile("d_latch_tb.vcd");
        $dumpvars(0, d_latch_tb);

        $display("====Gate level D latch with control signal====");
        $display(" C  D | Q QN ");
        $display("------+------");
        C_G = 1;
        D_G = 0; #5;
        $display(" %b %b  | %b %b", C_G, D_G, Q_G, QN_G);

        D_G = 1; #5;
        $display(" %b %b  | %b %b", C_G, D_G, Q_G, QN_G);

        $display("");
        $display("====Gate level D latch without control signal====");
        $display("   D  | Q QN ");
        $display("------+------");
        D_N = 0; #5;
        $display("   %b  | %b %b", D_N, Q_N, QN_N);

        D_N = 1; #5;
        $display("   %b  | %b %b", D_N, Q_N, QN_N);

        $display("");
        $display("====Behavioural D latch====");
        $display(" C  D | Q QN ");
        $display("------+------");
        C = 1;
        D = 0; #5;
        $display(" %b %b  | %b %b", C, D, Q, QN);

        D = 1; #5;
        $display(" %b %b  | %b %b", C, D, Q, QN);
    end
endmodule