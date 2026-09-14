`timescale 1ns / 1ps

module rtl_counter_tb;

    // Shared clock and reset
    reg clk;
    reg rstn;

    // Modulo-10 counter signals
    reg        en_mod;
    wire [3:0] q_mod;
    wire       tc;

    // Up/down counter signals
    reg        en_ud;
    reg        down;
    wire [2:0] q_ud;

    integer errors;

    // =========================================================
    // DUT 1: Modulo-10 counter
    // =========================================================
    rtl_modn #(
        .N (10),
        .W (4)
    ) DUT_MOD10 (
        .clk  (clk),
        .rstn (rstn),
        .en   (en_mod),
        .q    (q_mod),
        .tc   (tc)
    );

    // =========================================================
    // DUT 2: 3-bit up/down counter
    // =========================================================
    rtl_updown3 DUT_UPDOWN (
        .clk  (clk),
        .rstn (rstn),
        .en   (en_ud),
        .down (down),
        .q    (q_ud)
    );

    // 100 MHz clock: period = 10 ns
    always #5 clk = ~clk;

    // Wait for one rising clock edge
    task tick;
    begin
        @(posedge clk);
        #1;
    end
    endtask

    // Reset both counters
    task reset;
    begin
        rstn = 1'b0;
        #2;
        rstn = 1'b1;
        #1;
    end
    endtask

    // Count and check the modulo-10 counter
    task step_mod;
        input [3:0] expected_q;
        input       expected_tc;
    begin
        tick;

        if ((q_mod !== expected_q) ||
            (tc !== expected_tc)) begin

            $display(
                "\nERROR MOD10: expected q=%0d tc=%0b, got q=%0d tc=%0b",
                expected_q, expected_tc, q_mod, tc
            );

            errors = errors + 1;
        end

        if (tc)
            $write("%0d* ", q_mod);
        else
            $write("%0d ", q_mod);
    end
    endtask

    // Check that modulo-10 counter holds
    task hold_mod;
        input [3:0] expected_q;
    begin
        tick;

        if ((q_mod !== expected_q) || (tc !== 1'b0)) begin
            $display(
                "\nERROR MOD10 HOLD: expected q=%0d tc=0, got q=%0d tc=%0b",
                expected_q, q_mod, tc
            );

            errors = errors + 1;
        end

        $write("%0d ", q_mod);
    end
    endtask

    // Count and check the up/down counter
    task step_updown;
        input [2:0] expected_q;
    begin
        tick;

        if (q_ud !== expected_q) begin
            $display(
                "\nERROR UP/DOWN: expected q=%0d, got q=%0d",
                expected_q, q_ud
            );

            errors = errors + 1;
        end

        $write("%0d ", q_ud);
    end
    endtask

    // =========================================================
    // Main simulation
    // =========================================================
    initial begin
        clk    = 1'b0;
        rstn   = 1'b1;
        en_mod = 1'b0;
        en_ud  = 1'b0;
        down   = 1'b0;
        errors = 0;

        // Initial reset
        reset;

        // Check reset values
        if ((q_mod !== 4'd0) || (q_ud !== 3'd0)) begin
            $display("ERROR: reset failed.");
            errors = errors + 1;
        end

        // =====================================================
        // STAGE 4: MODULO-10 COUNTER
        // =====================================================
        $display("");
        $display("===== STAGE 4 : RTL MODULO-10 WITH ENABLE =====");

        en_mod = 1'b1;

        $write("en=1 : ");

        step_mod(4'd1, 1'b0);
        step_mod(4'd2, 1'b0);
        step_mod(4'd3, 1'b0);
        step_mod(4'd4, 1'b0);
        step_mod(4'd5, 1'b0);
        step_mod(4'd6, 1'b0);
        step_mod(4'd7, 1'b0);
        step_mod(4'd8, 1'b0);
        step_mod(4'd9, 1'b1);
        step_mod(4'd0, 1'b0);
        step_mod(4'd1, 1'b0);

        $display("(* = terminal count)");

        // Disable counter: q must remain 1
        en_mod = 1'b0;

        $write("en=0 : ");

        hold_mod(4'd1);
        hold_mod(4'd1);
        hold_mod(4'd1);

        $display("(holds)");

        // =====================================================
        // STAGE 5: UP/DOWN COUNTER
        // =====================================================
        reset;

        en_ud = 1'b1;
        down  = 1'b0;

        $display("");
        $display("===== STAGE 5 : RTL UP/DOWN COUNTER =====");

        // Count upward
        $write("up   : ");

        step_updown(3'd1);
        step_updown(3'd2);
        step_updown(3'd3);
        step_updown(3'd4);
        step_updown(3'd5);
        step_updown(3'd6);
        step_updown(3'd7);
        step_updown(3'd0);

        $display("");

        // Count downward
        down = 1'b1;

        $write("down : 0 ");

        step_updown(3'd7);
        step_updown(3'd6);
        step_updown(3'd5);

        $display("(wraps 0 -> 7)");

        // Verify enable/hold for up/down counter
        en_ud = 1'b0;
        tick;

        if (q_ud !== 3'd5) begin
            $display("ERROR UP/DOWN HOLD: expected 5, got %0d", q_ud);
            errors = errors + 1;
        end

        // =====================================================
        // Final result
        // =====================================================
        $display("");

        if (errors == 0)
            $display(">> PASS: all counters behaved as expected.");
        else
            $display(">> FAIL: %0d error(s) detected.", errors);

        $finish;
    end

endmodule