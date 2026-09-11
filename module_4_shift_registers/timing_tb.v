`timescale 1ns / 1ps
//======================================================================
//  timing_tb.v  --  Timing verification of the shift-register elements
//----------------------------------------------------------------------
//  Part A : measure the clock-to-Q delay of dff_t (TPD = 1.0 and 2.5 ns)
//  Part B : measure the latency of the 4-stage SISO register (4 clocks)
//  Part C : setup/hold checker -- a clean stimulus reports 0 violations,
//           a deliberately bad stimulus reports one setup and one hold
//  Part D : estimate the maximum clock frequency from measured t_cq and
//           given t_logic / t_setup  (T >= t_cq + t_logic + t_setup)
//======================================================================
module timing_tb;
    reg clk = 0, rstn = 1, d = 0, si = 0;
    always #5 clk = ~clk;                       // 100 MHz, period 10 ns
    wire q1, q2, so;
    integer err = 0, i, edges;
    realtime t_edge, t_q1, t_q2;

    dff_t #(.TPD(1.0)) F1 (.clk(clk), .rstn(rstn), .d(d), .q(q1));
    dff_t #(.TPD(2.5)) F2 (.clk(clk), .rstn(rstn), .d(d), .q(q2));
    siso4              S  (.clk(clk), .rstn(rstn), .si(si), .so(so));

    // checker on the d input of F1 : T_SETUP = 2 ns, T_HOLD = 1 ns
    setup_hold_checker #(.T_SETUP(2.0), .T_HOLD(1.0)) CHK (.clk(clk), .d(d));

    always @(posedge clk) t_edge = $realtime;
    always @(q1) t_q1 = $realtime;
    always @(q2) t_q2 = $realtime;

    initial begin
        $dumpfile("timing_tb.vcd"); $dumpvars(0, timing_tb);
        $timeformat(-9, 1, " ns", 8);
        rstn = 0; #2; rstn = 1;

        // ---------------- Part A ----------------
        $display("");
        $display("  ===== PART A : CLOCK-TO-Q DELAY =====");
        @(negedge clk); d = 1;                   // change d mid-cycle (safe)
        @(posedge clk); #4;                      // wait for both outputs
        $display("   edge at %t : q1 changed at %t  ->  t_cq = %0.1f ns  (TPD = 1.0)", t_edge, t_q1, t_q1 - t_edge);
        $display("   edge at %t : q2 changed at %t  ->  t_cq = %0.1f ns  (TPD = 2.5)", t_edge, t_q2, t_q2 - t_edge);
        if ((t_q1 - t_edge) != 1.0 || (t_q2 - t_edge) != 2.5) begin err = err + 1; $display("   !! t_cq wrong"); end

        // ---------------- Part B ----------------
        $display("");
        $display("  ===== PART B : SISO LATENCY =====");
        @(negedge clk); si = 1; @(negedge clk); si = 0;     // one-clock-wide pulse
        edges = 1;                                          // the pulse was captured on 1 edge
        while (so !== 1'b1 && edges < 20) begin @(posedge clk); #3; edges = edges + 1; end
        $display("   a 1-bit pulse entered on clock 1 appeared at the serial output on clock %0d", edges);
        $display("   -> latency of the 4-stage register = %0d clock periods", edges);
        if (edges !== 4) begin err = err + 1; $display("   !! latency should be 4"); end

        // ---------------- Part C ----------------
        $display("");
        $display("  ===== PART C : SETUP / HOLD CHECK  (T_SETUP = 2 ns, T_HOLD = 1 ns) =====");
        $display("   clean stimulus: d changes 5 ns before every edge");
        for (i = 0; i < 4; i = i + 1) begin @(negedge clk); d = ~d; end
        @(posedge clk); #1;
        $display("   violations so far = %0d", CHK.violations);
        if (CHK.violations !== 0) begin err = err + 1; $display("   !! clean stimulus must not violate"); end

        $display("   bad stimulus (a): d changes 1 ns BEFORE the edge");
        @(posedge clk); #9; d = ~d;                          // 1 ns before next rising edge
        @(posedge clk); #0.1;
        $display("   bad stimulus (b): d changes 0.5 ns AFTER the edge");
        #0.4; d = ~d;                                        // 0.5 ns after the edge
        #2;
        $display("   violations now = %0d  (expected 2: one setup, one hold)", CHK.violations);
        if (CHK.violations !== 2) begin err = err + 1; $display("   !! checker should report exactly 2"); end

        // ---------------- Part D ----------------
        $display("");
        $display("  ===== PART D : MAXIMUM CLOCK FREQUENCY ESTIMATE =====");
        $display("   t_cq = 1.0 ns (measured), t_logic = 3.2 ns (given), t_setup = 2.0 ns (checker)");
        $display("   T_min = 1.0 + 3.2 + 2.0 = 6.2 ns  ->  f_max = %0.1f MHz", 1000.0/6.2);
        $display("   at 100 MHz (T = 10 ns) the slack is 10 - 6.2 = +3.8 ns  (constraint met)");

        $display("");
        if (err == 0) $display("  >> PASS: timing measurements and checks behaved as expected.");
        else          $display("  >> FAIL: %0d problem(s).", err);
        $display("");
        $finish;
    end
endmodule
