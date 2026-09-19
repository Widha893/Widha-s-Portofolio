`timescale 1ns / 1ps

module tb_srff_ms;
    reg S, R, C;
    wire Q, QN;
    integer err;
    reg q_before;

    srff_ms DUT (.S(S), .R(R), .C(C), .Q(Q), .QN(QN));

    task apply_case;
        input test_s, test_r, expected_q;
        begin
            S = test_s;
            R = test_r;
            q_before = Q;

            C = 1;
            #3;
            if (Q !== q_before) begin
                err = err + 1;
                $display("!! Q changed while C=1");
            end

            C = 0;
            #1;
            $display("%b %b |   %b  |    %b", S, R, q_before, Q);
            if (Q !== expected_q)
                err = err + 1;
            #2;
        end
    endtask

    initial begin
        err = 0;
        S = 0; R = 1; C = 1;

        // Known initial state: reset on the first falling edge.
        #3 C = 0; #1;

        $display("===== SR MASTER-SLAVE TRUTH TABLE =====");
        $display("S R | Q(t) | Q(after falling edge)");
        $display("----+------+----------------------");
        apply_case(0, 0, 0); // hold zero
        apply_case(1, 0, 1); // set
        apply_case(0, 0, 1); // hold one
        apply_case(0, 1, 0); // reset

        // Forbidden state: behavioral model deliberately produces X.
        S = 1; R = 1; q_before = Q;
        C = 1; #3;
        if (Q !== q_before) err = err + 1;
        C = 0; #1;
        $display("1 1 |   %b  |    %b (forbidden)", q_before, Q);
        if ((Q !== 1'bx) || (QN !== 1'bx))
            err = err + 1;

        $display("");
        if (err == 0)
            $display(">> PASS: output changes on falling edge, not while C=1.");
        else
            $display(">> FAIL: %0d SR master-slave errors.", err);
        $finish;
    end
endmodule
