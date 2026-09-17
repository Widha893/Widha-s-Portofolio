`timescale 1ns/1ps

module tb_mealy_1011_detector;
    reg clk, rst, X;
    wire Z;

    mealy_1011_detector uut (.clk(clk), .rst(rst), .X(X), .Z(Z));

    always #5 clk = ~clk;

    task apply_x(input b);
        begin
            X = b;
            @(posedge clk);
            #1;
            $display("t=%0t | Q1Q0=%b%b | X=%b | Z=%b", $time, uut.Q1, uut.Q0, X, Z);
        end
    endtask

    initial begin
        clk = 0; rst = 1; X = 0;
        #10; rst = 0;

        // Urutan: 1 0 1 1 0 1 1 -> uji overlap
        apply_x(1); // A0->A1
        apply_x(0); // A1->A2
        apply_x(1); // A2->A3
        apply_x(1); // A3->A1, Z HARUS 1 di baris ini
        apply_x(0); // A1->A2
        apply_x(1); // A2->A3
        apply_x(1); // A3->A1, Z HARUS 1 lagi (overlap)

        #20; $finish;
    end

    initial begin
        $dumpfile("mealy_1011.vcd");
        $dumpvars(0, tb_mealy_1011_detector);
    end
endmodule