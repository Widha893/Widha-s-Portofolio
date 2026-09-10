`timescale 1ns / 1ps

module comb_system_tb;
    reg din;
    reg [1:0] sel;
    reg [1:0] code;
    reg en;
    
    wire dout;
    wire [3:0] channel;
    wire [1:0] code_back;
    wire valid;
    
    integer i;
    integer err = 0; 

    comb_system DUT (
        .din(din),
        .sel(sel),
        .code(code),
        .en(en),
        .dout(dout),
        .channel(channel),
        .code_back(code_back),
        .valid(valid)
    );

    initial begin
        $dumpfile("comb_system_tb.vcd");
        $dumpvars(0, comb_system_tb);
        
        $display("===== ROUND TRIPS: demux->mux and decoder->encoder (64 cases) =====");
        
        for (i = 0; i < 64; i = i + 1) begin
            {din, sel, code, en} = i[5:0];
            #10;

            if (dout !== din) begin
                err = err + 1;
                $display(" !! Link 1 ERROR: din=%b, tapi dout=%b", din, dout);
            end
            
            if (din == 1'b1 && channel !== (4'b0001 << sel)) begin
                err = err + 1;
                $display(" !! Link 1 ERROR: channel salah saat din=1, sel=%b, channel=%b", sel, channel);
            end else if (din == 1'b0 && channel !== 4'b0000) begin
                err = err + 1;
                $display(" !! Link 1 ERROR: channel tidak nol saat din=0, channel=%b", channel);
            end

            if (en == 1'b1 && (code_back !== code || valid !== 1'b1)) begin
                err = err + 1;
                $display(" !! Link 2 ERROR: en=1, code=%b, tapi code_back=%b, valid=%b", code, code_back, valid);
            end
            
            if (en == 1'b0 && valid !== 1'b0) begin
                err = err + 1;
                $display(" !! Link 2 ERROR: en=0, tapi valid=%b", valid);
            end
        end
        
        if (err == 0) begin
            $display("Link 1: dout equalled din on every case (demux -> mux).");
            $display("Link 2: code_back equalled code whenever en = 1 (decoder -> encoder).\n");
            $display(">> PASS: both round trips behaved as expected.");
        end else begin
            $display("\n>> FAIL: Ditemukan %0d error pada sistem kombinasi.", err);
        end
        
        $finish;
    end
endmodule