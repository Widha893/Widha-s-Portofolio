`timescale 1ns/1ps
module demux_tb;

    reg din2;
    reg sel2;
    reg din4;
    reg [1:0] sel4;

    wire [1:0] y2;
    wire [3:0] y4;

    demux1to2 U_2(.din(din2), .sel(sel2), .y(y2));
    demux1to4 U_4(.din(din4), .sel(sel4), .y(y4));

    integer i, err;
    initial begin
        err = 0;
        $dumpfile("demux_tb.vcd");
        $dumpvars(0, demux_tb);

        $display("===== 1-to-2 DEMUX (4 combinations) =====");
        $display("sel din | y1 y0");
        $display("--------+------");
        for (i = 0; i < 4; i = i + 1) begin
            {sel2, din2} = i[1:0];
            #2;
            if (y2 !== (din2 ? (2'b01 << sel2) : 2'b0) ) begin
                err = err + 1;
                $display("  !! mismatch at sel=%b din=%b", sel2, din2);
            end
            $display(" %b   %b  |  %b  %b", sel2, din2, y2[1], y2[0]);
        end

        $display("");
        $display("===== 1-to-4 DEMUX (8 combinations) =====");
        $display("sel din | y3 y2 y1 y0");
        $display("--------+------------");
        for (i = 0; i < 8; i = i + 1) begin
            {sel4, din4} = i[2:0];
            #2;
            if (y4 !== (din4 ? (4'b0001 << sel4) : 4'b0000)) begin
                err = err + 1;
                $display("  !! mismatch at sel=%b din=%b", sel4, din4);
            end
            $display("%b   %b  |  %b  %b  %b  %b", sel4, din4, y4[3], y4[2], y4[1], y4[0]);
        end

        if (err == 0)
            $display("\n>> PASS: all DEMUX tests behaved as expected.");

        else
            $display("\n>> FAIL: %0d mismatch(es) detected.", err);

        $finish;
    end
endmodule
