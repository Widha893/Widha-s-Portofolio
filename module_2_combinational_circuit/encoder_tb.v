`timescale 1ns / 1ps

module encoder_tb;

    reg [3:0] d;          
    wire [1:0] y;         
    wire valid;
    
    integer i;
    integer err = 0;      
    
    reg [1:0] ref_y;
    reg ref_valid;

    priority_encoder4to2 DUT (
        .d(d), 
        .y(y), 
        .valid(valid)
    );

    initial begin
        $dumpfile("encoder_tb.vcd"); // Untuk melihat waveform nanti
        $dumpvars(0, encoder_tb);

        $display("===== STAGE 2 : PRIORITY ENCODER (all 16 inputs) =====");
        $display("d3 d2 d1 d0 | y valid");
        $display("------------+---------");
        
        for (i = 0; i < 16; i = i + 1) begin
            d = i[3:0];
            #10;
            ref_valid = |d;
            
            if (d[3])      ref_y = 2'd3;
            else if (d[2]) ref_y = 2'd2;
            else if (d[1]) ref_y = 2'd1;
            else           ref_y = 2'd0;
            
            $display(" %b  %b  %b  %b | %b    %b", d[3], d[2], d[1], d[0], y, valid);
            
            if (y !== ref_y || valid !== ref_valid) begin
                err = err + 1;
                $display(" !! ERROR: Untuk input %b, dapat y=%b (seharusnya %b), valid=%b (seharusnya %b)", 
                        d, 
                        y, 
                        ref_y, 
                        valid, 
                        ref_valid);
            end
        end
        
        $display("----------------------");
        
        if (err == 0) 
            $display(">> PASS: all ENCODER tests behaved as expected.");
        else 
            $display(">> FAIL: %0d error(s) found.", err);
            
        $finish; 
    end
endmodule