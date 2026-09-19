`timescale 1ns/1ps
module mux_tb;

    reg a1;
    reg b1;
    reg sel1;
    reg [3:0] data;
    reg [1:0] sel4;

    wire y_assign;
    wire y_ifelse;
    wire y4;

    mux2to1_a U_A (.a(a1), .b(b1), .sel(sel1), .y(y_assign));
    mux2to1_b U_B (.a(a1), .b(b1), .sel(sel1), .y(y_ifelse));
    mux4to1 U_4 (.data(data), .sel(sel4), .y(y4));

    integer i, err;
    initial begin 
        err = 0;
        $dumpfile("mux_tb.vcd");
        $dumpvars(0, mux_tb);

        $display("===== STAGE 1 : 2:1 MUX (assign vs if-else) =====");
        $display("sel a b | y_assign y_ifelse | ref");
        $display("--------+-------------------+-----");
        for (i = 0; i < 8; i = i + 1) begin
            {sel1, a1, b1} = i[2:0];
            #2;
            if (y_assign !== y_ifelse || y_assign !== (sel1 ? b1 : a1)) begin
                err = err + 1;
                $display("  !! mismatch at sel=%b a=%b b=%b", sel1, a1, b1);
            end
            $display(" %b %b %b |    %b        %b    |  %b",
                       sel1, a1, b1, y_assign, y_ifelse, (sel1 ? b1 : a1));
        end

        $display("");
        $display("===== STAGE 2 : basic 4:1 MUX (d = 1010) =====");
        $display("sel | d[3..0] | y");
        $display("----+---------+---");
        data = 4'b1010;
        for (i = 0; i < 4; i = i + 1) begin
            sel4 = i[1:0];
            #2;
            if (y4 !== data[sel4]) begin
                err = err + 1;
                $display("  !! mismatch at sel=%b", sel4);
            end
            $display(" %b  |  %b   | %b", sel4, data, y4);
        end

        $display("");
        $display("===== STAGE 3 : exhaustive 4:1 MUX (64 combinations) =====");
        for (i = 0; i < 64; i = i + 1) begin
            {sel4, data} = i[5:0];
            #2;
            if (y4 !== data[sel4]) begin
                err = err + 1;
                $display("  !! d=%b sel=%b : y=%b expected %b", data, sel4, y4, data[sel4]);
            end
        end
        $display("64 combinations checked against the reference y = d[sel].");

        if (err == 0)
            $display("\n>> PASS: all MUX tests behaved as expected.");
        else
            $display("\n>> FAIL: %0d mismatch(es) detected.", err);

        $finish;
    end
endmodule