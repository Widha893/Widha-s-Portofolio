`timescale 1ns / 1ps
//======================================================================
//  shift_registers_tb.v  --  Functional verification of all registers
//----------------------------------------------------------------------
//  Test data (from the laboratory manual): 1000, 0101, 1111, 0110, 1001
//  Stage 1 PIPO   : load, then read through the output enable
//  Stage 2 SIPO   : shift in LSB-first, read the parallel word
//  Stage 3 SISO   : the serial output reproduces the serial input, delayed
//  Stage 4 PISO   : load in parallel, shift out LSB-first
//  Stage 5 BIDIR  : the 10-clock scenario of the manual (right, then left)
//  Stage 6 UNIVERSAL : the four modes of the RTL register
//======================================================================
module shift_registers_tb;
    reg clk = 0, rstn = 1;
    always #5 clk = ~clk;                       // 100 MHz
    integer i, n, err = 0;
    reg [3:0] data [0:4];
    reg [3:0] expect_v, seri;

    // PIPO
    reg load = 0, oe = 0;  reg [3:0] din = 0;  wire [3:0] qp, dp;
    pipo4 UP (.clk(clk), .rstn(rstn), .load(load), .oe(oe), .din(din), .q(qp), .dout(dp));
    // SIPO / SISO
    reg si = 0;  wire [3:0] qs;  wire sos, so_siso;
    sipo4 US (.clk(clk), .rstn(rstn), .si(si), .q(qs), .so(sos));
    siso4 UO (.clk(clk), .rstn(rstn), .si(si), .so(so_siso));
    // PISO
    reg pload = 0;  wire [3:0] qi;  wire soi;
    piso4 UI (.clk(clk), .rstn(rstn), .load(pload), .din(din), .q(qi), .so(soi));
    // BIDIR
    reg dir = 1, sir = 0, sil = 0;  wire [3:0] qb;
    bidir4 UB (.clk(clk), .rstn(rstn), .dir(dir), .sir(sir), .sil(sil), .q(qb));
    // UNIVERSAL
    reg [1:0] mode = 0;  wire [3:0] qu;
    universal4 UU (.clk(clk), .rstn(rstn), .mode(mode), .sir(sir), .sil(sil), .din(din), .q(qu));

    task tick;  begin @(posedge clk); #3; end endtask   // wait past TPD before sampling
    task reset; begin rstn = 0; #4; rstn = 1; #1; end endtask

    // bidirectional scenario (manual, Table IV)
    reg       tdir [0:9];  reg tin [0:9];  reg [3:0] tq [0:9];

    initial begin
        $dumpfile("shift_registers_tb.vcd"); $dumpvars(0, shift_registers_tb);
        data[0]=4'b1000; data[1]=4'b0101; data[2]=4'b1111; data[3]=4'b0110; data[4]=4'b1001;

        $display("");
        $display("  ===== STAGE 1 : PIPO =====");
        $display("  din  -> dout (oe=1) | dout (oe=0)");
        for (n = 0; n < 5; n = n + 1) begin
            reset; din = data[n]; load = 1; tick; load = 0; oe = 1; #1;
            $write("  %b ->   %b        |", data[n], dp);
            if (dp !== data[n]) begin err=err+1; $display(" !! wrong"); end
            oe = 0; #1; $display("   %b", dp);
            if (dp !== 4'b0000) begin err=err+1; $display("   !! oe=0 must blank the output"); end
        end

        $display("");
        $display("  ===== STAGE 2 : SIPO (serial in, LSB first) =====");
        $display("  si on clocks 1-4 -> q[3:0]");
        for (n = 0; n < 5; n = n + 1) begin
            reset;
            for (i = 0; i <= 3; i = i + 1) begin si = data[n][i]; tick; end   // LSB first
            $display("     %b %b %b %b      ->  %b", data[n][0], data[n][1], data[n][2], data[n][3], qs);
            if (qs !== data[n]) begin err=err+1; $display("   !! expected %b", data[n]); end
        end

        $display("");
        $display("  ===== STAGE 3 : SISO (serial in -> serial out, 4-clock delay) =====");
        $display("  si on clocks 1-4 -> so on clocks 5-8");
        for (n = 0; n < 5; n = n + 1) begin
            reset;
            for (i = 0; i <= 3; i = i + 1) begin si = data[n][i]; tick; end
            si = 0;
            for (i = 0; i <= 3; i = i + 1) begin seri[i] = so_siso; tick; end
            $display("     %b %b %b %b      ->   %b %b %b %b", data[n][0], data[n][1], data[n][2], data[n][3],
                     seri[0], seri[1], seri[2], seri[3]);
            if (seri !== data[n]) begin err=err+1; $display("   !! serial output differs from serial input"); end
        end

        $display("");
        $display("  ===== STAGE 4 : PISO (parallel load, serial out LSB first) =====");
        $display("  din  -> so on clocks 1-4");
        for (n = 0; n < 5; n = n + 1) begin
            reset; din = data[n]; pload = 1; tick; pload = 0;
            for (i = 0; i <= 3; i = i + 1) begin seri[i] = soi; tick; end
            $display("  %b ->  %b %b %b %b", data[n], seri[0], seri[1], seri[2], seri[3]);
            if (seri !== data[n]) begin err=err+1; $display("   !! expected %b", data[n]); end
        end

        $display("");
        $display("  ===== STAGE 5 : BIDIRECTIONAL (right for 4 clocks, then left for 5) =====");
        tdir[0]=1; tin[0]=0; tq[0]=4'b0000;
        tdir[1]=1; tin[1]=1; tq[1]=4'b1000;   tdir[2]=1; tin[2]=0; tq[2]=4'b0100;
        tdir[3]=1; tin[3]=1; tq[3]=4'b1010;   tdir[4]=1; tin[4]=1; tq[4]=4'b1101;
        tdir[5]=0; tin[5]=1; tq[5]=4'b1011;   tdir[6]=0; tin[6]=0; tq[6]=4'b0110;
        tdir[7]=0; tin[7]=0; tq[7]=4'b1100;   tdir[8]=0; tin[8]=1; tq[8]=4'b1001;
        tdir[9]=0; tin[9]=1; tq[9]=4'b0011;
        reset;
        $display("  clock dir in | q      direction");
        for (n = 0; n <= 9; n = n + 1) begin
            dir = tdir[n]; sir = tin[n]; sil = tin[n];
            if (n > 0) tick;
            $display("    %0d    %b   %b | %b   %s", n, dir, tin[n], qb, dir ? "right" : "left");
            if (qb !== tq[n]) begin err=err+1; $display("   !! expected %b", tq[n]); end
        end

        $display("");
        $display("  ===== STAGE 6 : UNIVERSAL REGISTER (RTL) =====");
        reset; din = 4'b1011; mode = 2'b11; tick;  $display("  mode 11 load        -> q = %b", qu);
        if (qu !== 4'b1011) begin err=err+1; $display("   !! load"); end
        mode = 2'b00; tick;                        $display("  mode 00 hold        -> q = %b", qu);
        if (qu !== 4'b1011) begin err=err+1; $display("   !! hold"); end
        mode = 2'b01; sir = 0; tick;               $display("  mode 01 shift right -> q = %b", qu);
        if (qu !== 4'b0101) begin err=err+1; $display("   !! right"); end
        mode = 2'b10; sil = 1; tick;               $display("  mode 10 shift left  -> q = %b", qu);
        if (qu !== 4'b1011) begin err=err+1; $display("   !! left"); end

        $display("");
        if (err == 0) $display("  >> PASS: all shift registers behaved as expected.");
        else          $display("  >> FAIL: %0d mismatch(es).", err);
        $display("");
        $finish;
    end
endmodule
