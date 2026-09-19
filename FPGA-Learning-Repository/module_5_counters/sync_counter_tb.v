`timescale 1ns/1ps

 module sync_counter_tb;
    reg clk = 0;
    reg rstn;

    wire [2:0] q8;
    wire [2:0] q6;
    wire [3:0] qb; 

    always #5 clk = ~clk;

    sync_mod8 U6 (.clk(clk), .rstn(rstn), .q(q8));
    sync_mod6 U8 (.clk(clk), .rstn(rstn), .q(q6));
    sync_bcd UB (.clk(clk), .rstn(rstn), .q(qb));

    task reset;
        begin
            @(negedge clk);
            rstn = 0;
            #2;
            rstn = 1;
        end
    endtask;

    task tick;
        begin
            @(posedge clk);
            #5;
        end
    endtask;

    integer i;
    initial begin
        $dumpfile("sync_counter_tb.vcd"); 
        $dumpvars(0, sync_counter_tb);
        $display("===== STAGE 1 : SYNCHRONOUS COUNTERS =====");
        $display("clock | mod-8 | mod-6 |  BCD");
        reset();

        for (i = 0; i <= 12; i = i + 1) begin
            $display(" %3d  |  %b  |  %b  | %b (%0d)", i, q8, q6, qb, qb);
            tick();
        end

        $display("\n===== STAGE 2 : MOD-6 RECOVERY FROM UNUSED STATES =====");

        // ---- force state 110 (q2 q1 q0) ----
        force U6.F2.q = 1'b1;
        force U6.F1.q = 1'b1;
        force U6.F0.q = 1'b0;
        #1;
        release U6.F2.q;
        release U6.F1.q;
        release U6.F0.q;
        tick();
        $display("110 -> %b", q6);

        // ---- force state 111 ----
        force U6.F2.q = 1'b1;
        force U6.F1.q = 1'b1;
        force U6.F0.q = 1'b1;
        #1;
        release U6.F2.q;
        release U6.F1.q;
        release U6.F0.q;
        tick();
        $display("111 -> %b", q6);

        $display("both unused states return to the legal sequence within one clock");
        $finish;
    end
 endmodule