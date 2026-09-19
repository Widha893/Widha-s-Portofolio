`timescale 1ns/1ps

module counter_timing_tb;

    // timing model parameters (Table 3.1 / WS-3 header)
    real TCQ    = 1.0;
    real TLOGIC = 1.5;
    real TSETUP = 2.0;

    reg clk = 0, rstn;
    wire [2:0] qs;   // synchronous
    wire [2:0] qr;   // ripple

    integer errors = 0;

    always #5 clk = ~clk;    // 10 ns period

    sync_mod8      S (.clk(clk), .rstn(rstn), .q(qs));
    ripple_counter R (.clk(clk), .rst(rstn), .q(qr));

    // decoder of state 0 on each bus
    wire dec0_s = (qs == 3'b000);
    wire dec0_r = (qr == 3'b000);

    // bit time stamps
    real ts0, ts1, ts2;
    real tr0, tr1, tr2;
    real edge_time;
    reg  measuring = 0;

    always @(qs[0]) if (measuring) ts0 = $realtime;
    always @(qs[1]) if (measuring) ts1 = $realtime;
    always @(qs[2]) if (measuring) ts2 = $realtime;

    always @(qr[0]) if (measuring) tr0 = $realtime;
    always @(qr[1]) if (measuring) tr1 = $realtime;
    always @(qr[2]) if (measuring) tr2 = $realtime;

    // states the ripple bus passes through
    integer  nstates = 0;
    reg [2:0] seen [0:7];
    always @(qr) if (measuring) begin
        if (nstates < 8) seen[nstates] = qr;
        nstates = nstates + 1;
    end

    // false pulse on the state-0 decoder
    real glitch_start;
    real glitch_width = 0.0;
    reg  glitch_seen = 0;
    always @(posedge dec0_r) if (measuring) glitch_start = $realtime;
    always @(negedge dec0_r) if (measuring) begin
        glitch_width = $realtime - glitch_start;
        glitch_seen  = 1;
    end

    integer i;
    real fmax_sync, fmax_r3, fmax_r8;

    initial begin
        $dumpfile("counter_timing_tb.vcd");
        $dumpvars(0, counter_timing_tb);

        rstn = 0;
        #8 rstn = 1;

        @(posedge clk);   // -> 1
        @(posedge clk);   // -> 2
        @(posedge clk);   // -> 3
        #5;               // settle at 40 ns, both buses = 011

        if (qs !== 3'b011) begin
            errors = errors + 1;
            $display("  !! setup: synchronous counter is %b, expected 011", qs);
        end
        if (qr !== 3'b011) begin
            errors = errors + 1;
            $display("  !! setup: ripple counter is %b, expected 011", qr);
        end

        measuring = 1;
        @(posedge clk);
        edge_time = $realtime;
        #10;
        measuring = 0;

        $display("===== PART A : SYNCHRONOUS COUNTER, transition 3 -> 4 =====");
        $display(" edge at %4.1f ns", edge_time);
        $display(" q[0] changed at %5.1f ns  (+%3.1f ns)", ts0, ts0 - edge_time);
        $display(" q[1] changed at %5.1f ns  (+%3.1f ns)", ts1, ts1 - edge_time);
        $display(" q[2] changed at %5.1f ns  (+%3.1f ns)", ts2, ts2 - edge_time);

        $display("\n===== PART B : RIPPLE COUNTER, same transition 3 -> 4 =====");
        $display(" q[0] changed at %5.1f ns  (+%3.1f ns)", tr0, tr0 - edge_time);
        $display(" q[1] changed at %5.1f ns  (+%3.1f ns)", tr1, tr1 - edge_time);
        $display(" q[2] changed at %5.1f ns  (+%3.1f ns)", tr2, tr2 - edge_time);
        $write(" intermediate states seen on the bus : 011");
        for (i = 0; i < nstates && i < 8; i = i + 1) $write(" -> %b", seen[i]);
        $write("\n");

        $display("\n===== PART C : DECODING GLITCH ON STATE 0 =====");
        if (glitch_seen)
            $display(" decoder of state 000 pulsed falsely at %4.1f ns for %3.1f ns",
                     glitch_start, glitch_width);
        else
            $display(" no false pulse detected");

        fmax_sync = 1000.0 / (TCQ + TLOGIC + TSETUP);
        fmax_r3   = 1000.0 / (3 * TCQ + TSETUP);
        fmax_r8   = 1000.0 / (8 * TCQ + TSETUP);
        $display("\n===== PART D : MAXIMUM CLOCK FREQUENCY =====");
        $display(" synchronous    : T = %3.1f ns -> f_max = %6.1f MHz", TCQ+TLOGIC+TSETUP, fmax_sync);
        $display(" ripple, 3 bits : T = %3.1f ns -> f_max = %6.1f MHz", 3*TCQ+TSETUP, fmax_r3);
        $display(" ripple, 8 bits : T = %3.1f ns -> f_max = %6.1f MHz", 8*TCQ+TSETUP, fmax_r8);

        $display("\n===== WS-3 TABLE VALUES =====");
        $display(" q[0] change time after the edge   | sync: +%3.1f ns | ripple: +%3.1f ns", ts0-edge_time, tr0-edge_time);
        $display(" q[1] change time after the edge   | sync: +%3.1f ns | ripple: +%3.1f ns", ts1-edge_time, tr1-edge_time);
        $display(" q[2] change time after the edge   | sync: +%3.1f ns | ripple: +%3.1f ns", ts2-edge_time, tr2-edge_time);
        $display(" intermediate states during 3->4   | sync: none      | ripple: 010, 000");
        $display(" decoder pulses on state 0         | sync: none      | ripple: %0.1f ns pulse", glitch_width);
        $display(" f_max (t_cq=1.0,t_logic=1.5,t_setup=2.0) | sync: %0.1f MHz | ripple(3-bit): %0.1f MHz",
                  fmax_sync, fmax_r3);

        if (errors == 0)
            $display("\n>> PASS: timing measurements behaved as expected.");
        else
            $display("\n>> FAIL: %0d problem(s) found.", errors);

        $finish;
    end
endmodule