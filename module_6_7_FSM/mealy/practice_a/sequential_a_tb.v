`timescale 1ns/1ps

module tb_mealy_fsm_AB;

    reg clk, rst, X;
    wire Z;

    mealy_fsm_AB uut (
        .clk(clk),
        .rst(rst),
        .X(X),
        .Z(Z)
    );

    always #5 clk = ~clk;

    // Fungsi bantu untuk nama state (biar gampang dibaca)
    function [15:0] state_name;
        input a, b;
        begin
            case ({a,b})
                2'b00: state_name = "P ";
                2'b01: state_name = "Q ";
                2'b11: state_name = "R ";
                2'b10: state_name = "S ";
            endcase
        end
    endfunction

    initial begin
        clk = 0; rst = 1; X = 0;
        #10;
        rst = 0;

        // Urutan input untuk menelusuri P->Q->R->S->P dan memicu Z=1 di state S
        apply_x(1'b0); // P -> Q
        apply_x(1'b1); // Q -> R
        apply_x(1'b1); // R -> S
        apply_x(1'b0); // S -> Q, Z harus 1 di sini (state S, X=0)
        apply_x(1'b1); // Q -> R
        apply_x(1'b1); // R -> S
        apply_x(1'b1); // S -> P

        #20;
        $finish;
    end

    task apply_x(input x_val);
        begin
            X = x_val;
            @(posedge clk);
            #1;
            $display("t=%0t | State=%s | X=%b | Z=%b", $time, state_name(uut.A, uut.B), X, Z);
        end
    endtask

    initial begin
        $dumpfile("mealy_fsm.vcd");
        $dumpvars(0, tb_mealy_fsm_AB);
    end

endmodule