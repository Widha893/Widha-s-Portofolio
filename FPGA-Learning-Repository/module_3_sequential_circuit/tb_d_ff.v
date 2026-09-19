`timescale 1ns / 1ps

module tb_d_ff;
    reg D, CLK;
    wire Q, QN;
    reg D_PCE, EN, PRE_N, CLR_N;
    wire Q_PCE, QN_PCE;
    integer err;

    d_ff DUT_EDGE (.D(D), .CLK(CLK), .Q(Q), .QN(QN));

    d_ff_pce DUT_PCE (
        .D(D_PCE), .EN(EN), .CLK(CLK),
        .PRE_N(PRE_N), .CLR_N(CLR_N),
        .Q(Q_PCE), .QN(QN_PCE)
    );

    always #5 CLK = ~CLK;

    task check_edge;
        input expected_q;
        begin
            #1;
            $display("rise %b | %b  %b", D, Q, QN);
            if ((Q !== expected_q) || (QN !== ~expected_q))
                err = err + 1;
        end
    endtask

    task check_pce;
        input expected_q, expected_qn;
        begin
            #1;
            $display("  %b     %b   | %b  %b", PRE_N, CLR_N, Q_PCE, QN_PCE);
            if ((Q_PCE !== expected_q) || (QN_PCE !== expected_qn))
                err = err + 1;
        end
    endtask

    initial begin
        err = 0;
        CLK = 0; D = 0;
        D_PCE = 0; EN = 1; PRE_N = 1; CLR_N = 1;

        $display("===== D FLIP-FLOP: EDGE TRUTH TABLE =====");
        $display("EDGE D | Q QN");
        $display("-------+-----");
        @(posedge CLK); check_edge(0);

        $display("");
        $display("===== THREE D CHANGES BETWEEN RISING EDGES =====");
        #1 D = 1; #1;
        $display("t=%0t D=%b CLK=%b Q=%b (hold)", $time, D, CLK, Q);
        if (Q !== 0) err = err + 1;
        #1 D = 0; #1;
        $display("t=%0t D=%b CLK=%b Q=%b (hold)", $time, D, CLK, Q);
        if (Q !== 0) err = err + 1;
        #1 D = 1; #1;
        $display("t=%0t D=%b CLK=%b Q=%b (hold)", $time, D, CLK, Q);
        if (Q !== 0) err = err + 1;

        @(posedge CLK); check_edge(1); // only final D=1 is stored
        @(negedge CLK); D = 0;
        @(posedge CLK); check_edge(0);

        $display("");
        $display("===== ASYNCHRONOUS PRESET/CLEAR =====");
        $display("PRE_N CLR_N | Q QN | MODE");
        $display("------------+------+-----------");
        EN = 0;
        CLR_N = 0; check_pce(0, 1); // clear without clock
        CLR_N = 1;
        PRE_N = 0; check_pce(1, 0); // preset without clock
        CLR_N = 0; check_pce(1, 1); // forbidden

        $display("");
        if (err == 0)
            $display(">> PASS: edge sampling and asynchronous controls verified.");
        else
            $display(">> FAIL: %0d D-FF errors.", err);
        $finish;
    end
endmodule
