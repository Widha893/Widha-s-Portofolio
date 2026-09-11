`timescale 1ns / 1ps

module tb_jkff_edge();

    // Testbench signals
    reg J;
    reg K;
    reg CLK;
    
    wire Q;
    wire QN;

    jkff_edge uut (
        .J(J),
        .K(K),
        .CLK(CLK),
        .Q(Q),
        .QN(QN)
    );

    initial begin
        CLK = 0;
        forever #5 CLK = ~CLK;
    end

    initial begin
        $dumpfile("tb_jkff_edge.vcd");
        $dumpvars(0, tb_jkff_edge);

        J = 0; K = 0;
        
        $display("===== JK CHARACTERISTIC TABLE =====");
        $display("J K | Q(t+1)");
        
        #12;
        J = 1; K = 0; 
        @(posedge CLK); #1; 
        $display("%b %b |   %b   (set)", J, K, Q);
        
        J = 0; K = 0; 
        @(posedge CLK); #1;
        $display("%b %b |   %b   (hold)", J, K, Q);
        
        J = 0; K = 1; 
        @(posedge CLK); #1;
        $display("%b %b |   %b   (reset)", J, K, Q);
        
        J = 1; K = 1; 
        @(posedge CLK); #1;
        $display("%b %b |   %b   (toggle)", J, K, Q);
        
        J = 1; K = 1; 
        @(posedge CLK); #1;
        $display("%b %b |   %b   (toggle)", J, K, Q);


        $display("\n===== VERIFYING NO 1s CATCHING =====");
        
        J = 0; K = 1;
        @(posedge CLK); #1;
        $display("Initial state Q = %b", Q);
        
        J = 0; K = 0;
        
        wait(CLK == 1);   
        #1; 
        J = 1;             
        $display("-> Narrow pulse applied to J while CLK is HIGH");
        #2;
        J = 0;             
        $display("-> Narrow pulse removed from J while CLK is HIGH");
        
        @(posedge CLK); #1; 
        $display("After next clock edge, Q = %b (Expected: 0, pulse was ignored)", Q);

        $display("\nSimulation complete.");
        $finish;
    end

endmodule