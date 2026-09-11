`timescale 1ns / 1ps

module tb_t_ff_en;
    reg T, CLK;
    wire Q, QN;
    integer err;
    reg previous_q;

    t_ff_en DUT (.T(T), .CLK(CLK), .Q(Q), .QN(QN));

    task apply_t;
        input test_t, expected_q;
        begin
            T = test_t;
            previous_q = Q;
            CLK = 1; #1;
            $display("%b |   %b  |    %b", T, previous_q, Q);
            if (Q !== expected_q) err = err + 1;
            CLK = 0; #1;
        end
    endtask

    initial begin
        err = 0;
        T = 0; CLK = 0;

        // Supplied enabled T FF has no reset.
        force DUT.Q = 1'b0;
        #1;
        release DUT.Q;

        $display("===== T FLIP-FLOP WITH ENABLE =====");
        $display("T | Q(t) | Q(t+1) | MODE");
        $display("--+------+---------+--------");
        apply_t(0, 0); // hold zero
        apply_t(1, 1); // toggle to one
        apply_t(0, 1); // hold one
        apply_t(1, 0); // toggle to zero
        apply_t(1, 1); // toggle to one
        apply_t(0, 1); // hold one

        $display("");
        if (err == 0)
            $display(">> PASS: T=0 holds; T=1 toggles.");
        else
            $display(">> FAIL: %0d enabled T-FF errors.", err);
        $finish;
    end
endmodule
