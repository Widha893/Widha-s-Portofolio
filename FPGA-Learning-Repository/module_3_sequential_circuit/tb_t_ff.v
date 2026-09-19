`timescale 1ns / 1ps

module tb_t_ff;
    reg CLK;
    wire Q, QN;
    integer err, transitions, n;
    reg previous_q;

    t_ff DUT (.CLK(CLK), .Q(Q), .QN(QN));

    initial begin
        err = 0;
        transitions = 0;
        CLK = 0;

        // Supplied T FF has no reset, so initialise Q in the testbench.
        force DUT.Q = 1'b0;
        #1;
        release DUT.Q;

        $display("===== T FLIP-FLOP: DIVIDE BY TWO =====");
        $display("PULSE | Q(t) Q(t+1)");
        $display("------+------------");

        for (n = 1; n <= 8; n = n + 1) begin
            previous_q = Q;
            CLK = 1; #1;
            $display("  %0d   |  %b     %b", n, previous_q, Q);
            if (Q !== previous_q) transitions = transitions + 1;
            else err = err + 1;
            CLK = 0; #1;
        end

        if (transitions != 8) err = err + 1;

        $display("");
        if (err == 0)
            $display(">> PASS: one Q change per pulse; f(Q)=f(CLK)/2.");
        else
            $display(">> FAIL: %0d T-FF errors.", err);
        $finish;
    end
endmodule
