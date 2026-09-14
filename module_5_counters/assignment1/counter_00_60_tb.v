`timescale 1ns/1ps

module counter_00_60_tb;
    reg clk = 0, rstn, en;
    wire [3:0] ones, tens;
    wire tc;
    integer errors = 0;
    integer i, n, value;

    // 100 MHz-style clock, period doesn't matter functionally here
    always #5 clk = ~clk;

    counter_00_60 DUT (
        .clk(clk), .rstn(rstn), .en(en),
        .ones(ones), .tens(tens), .tc(tc)
    );

    task tick;
        begin
            @(posedge clk); #1;
        end
    endtask

    task reset;
        begin
            @(negedge clk); rstn = 0; #2; rstn = 1;
        end
    endtask

    // advance the counter (en must be 1) until tens*10+ones == target
    task run_to(input integer target);
        begin
            while ((tens*10 + ones) !== target) tick();
        end
    endtask

    initial begin
        $dumpfile("counter_00_60_tb.vcd");
        $dumpvars(0, counter_00_60_tb);

        en = 1;

        $display("===== STAGE 1 : RESET =====");
        reset();
        $display(" after reset : %02d", tens*10 + ones);

        $display("\n===== STAGE 2 : TWO COMPLETE CYCLES (122 counts) =====");
        n = 0;
        for (i = 1; i <= 122; i = i + 1) begin
            tick();
            n = (n + 1) % 61;
            value = tens*10 + ones;
            if (value !== n) begin
                errors = errors + 1;
                $display("  !! count %0d : read %0d, expected %0d", i, value, n);
            end
            if (ones > 9 || tens > 6) begin
                errors = errors + 1;
                $display("  !! output is not valid BCD : tens=%0d ones=%0d", tens, ones);
            end
        end
        $display(" 122 counts matched the reference (n+1) mod 61; all outputs valid BCD.");

        $display("\n===== STAGE 3 : CRITICAL TRANSITIONS =====");
        run_to(9);
        tick();
        $display(" 09 -> %02d", tens*10 + ones);
        run_to(59);
        tick();
        $display(" 59 -> %02d", tens*10 + ones);
        tick();
        $display(" 60 -> %02d", tens*10 + ones);

        $display("\n===== STAGE 4 : ENABLE = 0 HOLDS THE COUNT =====");
        run_to(5);
        $display(" value before holding : %02d", tens*10 + ones);
        en = 0;
        for (i = 0; i < 4; i = i + 1) tick();
        $display(" after 4 clocks with en=0 : %02d", tens*10 + ones);
        en = 1;
        tick();
        $display(" after en=1 again : %02d", tens*10 + ones);

        $display("\n===== STAGE 5 : TERMINAL COUNT =====");
        run_to(60);
        $display(" value = %02d, tc = %b", tens*10 + ones, tc);
        tick();
        $display(" one clock later = %02d, tc = %b", tens*10 + ones, tc);

        if (errors == 0)
            $display("\n>> PASS: the 00-60 counter meets its specification.");
        else
            $display("\n>> FAIL: %0d error(s) found.", errors);

        $finish;
    end
endmodule