`timescale 1ns / 1ps

module tb_jkff_ms();

    reg J_7476, K_7476, CLK_7476, PRE_N, CLR_N;
    wire Q_7476, QN_7476;

    jkff_ms_7476 uut_7476 (
        .J(J_7476), .K(K_7476), .CLK(CLK_7476),
        .PRE_N(PRE_N), .CLR_N(CLR_N),
        .Q(Q_7476), .QN(QN_7476)
    );

    reg J_gate, K_gate, C_gate;
    wire Q_gate, QN_gate;

    jkff_ms_gate uut_gate (
        .J(J_gate), .K(K_gate), .C(C_gate),
        .Q(Q_gate), .QN(QN_gate)
    );

    initial begin
        CLK_7476 = 1; C_gate = 1;
        forever begin
            #5 CLK_7476 = ~CLK_7476;
               C_gate   = ~C_gate;
        end
    end

    initial begin
        $dumpfile("tb_jkff_ms.vcd");
        $dumpvars(0, tb_jkff_ms);

        $display("===== ASYNC PRESET, CLEAR & RACE CONDITION =====");
        $display("PRE_N CLR_N CLK J K | Q QN | Mode");
        J_7476 = 0; K_7476 = 0;
        
        PRE_N = 0; CLR_N = 1; #10;
        $display("  %b     %b    X  X X | %b  %b | Preset (asynchronous)", PRE_N, CLR_N, Q_7476, QN_7476);

        PRE_N = 1; CLR_N = 0; #10;
        $display("  %b     %b    X  X X | %b  %b | Clear (asynchronous)", PRE_N, CLR_N, Q_7476, QN_7476);
        
        PRE_N = 0; CLR_N = 0; #10;
        $display("  %b     %b    X  X X | %b  %b | Forbidden (Race Condition)", PRE_N, CLR_N, Q_7476, QN_7476);

        PRE_N = 1; CLR_N = 0; #5;
        PRE_N = 1; CLR_N = 1; #5;

        $display("\n===== TOGGLE MODE (DIVIDE BY TWO) =====");
        $display("PRE_N CLR_N CLK J K | Q QN | Mode");
        J_7476 = 1; K_7476 = 1; 
        
        @(negedge CLK_7476); #1;
        $display("  %b     %b    F  %b %b | %b  %b | Toggle", PRE_N, CLR_N, J_7476, K_7476, Q_7476, QN_7476);
        @(negedge CLK_7476); #1;
        $display("  %b     %b    F  %b %b | %b  %b | Toggle", PRE_N, CLR_N, J_7476, K_7476, Q_7476, QN_7476);
        @(negedge CLK_7476); #1;
        $display("  %b     %b    F  %b %b | %b  %b | Toggle", PRE_N, CLR_N, J_7476, K_7476, Q_7476, QN_7476);

        $display("\n===== 1s CATCHING (GATE LEVEL) =====");
        $display("CLK J K | Q | Event Description");
        
        J_gate = 0; K_gate = 1; 
        @(negedge C_gate); #2; 
        $display(" %b  %b %b | %b | Initial state (Reset)", C_gate, J_gate, K_gate, Q_gate);
        
        J_gate = 0; K_gate = 0; 
        
        wait(C_gate == 1); 
        #1;
        J_gate = 1;      
        $display(" %b  %b %b | %b | Narrow pulse applied to J while CLK is HIGH", C_gate, J_gate, K_gate, Q_gate);
        #2;
        J_gate = 0;        
        $display(" %b  %b %b | %b | Narrow pulse removed from J before CLK falls", C_gate, J_gate, K_gate, Q_gate);
        
        wait(C_gate == 0); 
        #2;               
        $display(" %b  %b %b | %b | After falling edge (1s caught by master!)", C_gate, J_gate, K_gate, Q_gate);

        $display("\nSimulation complete.");
        $finish;
    end

endmodule