`timescale 1ns/1ps
module decoder_tb;

    reg [1:0] a1;
    reg [2:0] a2;

    reg en1;
    reg en2;

    wire [3:0] y1_case;
    wire [3:0] y1_shift;
    wire [7:0] y2_case;
    wire [7:0] y2_shift;

    decoder2to4_shift U_2TO4_SHIFT(.a(a1), .en(en1), .y(y1_shift));
    decoder2to4_case U_2TO4_CASE(.a(a1), .en(en1), .y(y1_case));
    decoder3to8_shift U__3TO8_SHIFT(.a(a2), .en(en2), .y(y2_shift));
    decoder3to8_case U__3TO8_CASE(.a(a2), .en(en2), .y(y2_case));

    integer i, err;
    initial begin
        err = 0;
        $dumpfile("decoder_tb.vcd");
        $dumpvars(0, decoder_tb);

        $display("===== 2-to-4 DECODER (8 combinations) =====");
        $display("en a1 a0 | y3 y2 y1 y0");
        $display("---------+-------------");

        for (i = 0; i < 8; i = i + 1) begin
            {a1, en1} = i[2:0];
            #2;

            if (y1_case !== (en1 ? (4'b0001 << a1) : 4'b0000)) begin
                err = err + 1;
                $display("  !! decoder 2-to-4 mismatch at en=%b a=%b", 
                    en1, 
                    a1);
            end

            if (en1 && (y1_case[3] + y1_case[2] + y1_case[1] + y1_case[0]) != 1) begin
                err = err + 1;
                $display("  !! decoder 2-to-4 one-hot property violation at en=%b a=%b", 
                    en1, 
                    a1);
            end

            if (y1_case !== y1_shift) begin
                err = err + 1;
                $display("  !! decoder 2-to-4 style mismatch at en=%b a=%b : shift=%b while case=%b",
                    en1, 
                    a1, 
                    y1_shift, 
                    y1_case);
            end

            $display("%b  %b  %b  | %b  %b  %b  %b ", 
                    en1,
                    a1[1],
                    a1[0],
                    y1_case[3],
                    y1_case[2],
                    y1_case[1],
                    y1_case[0]);
        end

        $display("");
        $display("===== 3-to-8 DECODER (16 combinations) =====");
        $display("en a2a1a0 | y (case) | y (shift)");
        $display("----------+----------+----------");
        for (i = 0; i < 16; i = i + 1) begin
            {a2, en2} = i[3:0];
            #2;

            if (y2_shift !== (en2 ? (8'b0000_0001 << a2) : 8'b0000_0000)) begin
                err = err + 1;
                $display("  !! decoder 3-to-8 mismatch at en=%b a=%b", 
                    en2, 
                    a2);
            end

            if (en2 && (y2_shift[7] + y2_shift[6] + y2_shift[5] + y2_shift[4] +
                        y2_shift[3] + y2_shift[2] + y2_shift[1] + y2_shift[8]) != 1) begin
                err = err + 1;
                $display("  !! decoder 3-to-8 one-hot property violation at en=%b a=%b", 
                    en2, 
                    a2);
            end

            if (y2_case !== y2_shift) begin
                err = err + 1;
                $display("  !! decoder 3-to-8 style mismatch at en=%b a=%b : shift=%b while case=%b",
                    en2, 
                    a2, 
                    y2_shift, 
                    y2_case);
            end

            $display("%b   %b%b%b   | %b%b%b%b%b%b%b%b | %b%b%b%b%b%b%b%b",
                    en2,
                    a2[2],
                    a2[1],
                    a2[0],
                    y2_case[7],
                    y2_case[6],
                    y2_case[5],
                    y2_case[4],
                    y2_case[3],
                    y2_case[2],
                    y2_case[1],
                    y2_case[0],
                    y2_shift[7],
                    y2_shift[6],
                    y2_shift[5],
                    y2_shift[4],
                    y2_shift[3],
                    y2_shift[2],
                    y2_shift[1],
                    y2_shift[0]);
        end

        if (err == 0)
            $display("\n>> PASS: all DECODER tests behaved as expected.");
        
        else
            $display("\n>> FAIL: %0d mismatch(es) detected.", err);

        $finish;
    end
endmodule