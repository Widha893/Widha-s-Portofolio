`timescale 1ns/1ps

module tb_moore_1011_detector;

    reg clk;
    reg rst;
    reg w;
    wire z;

    // Instansiasi DUT (Device Under Test)
    moore_1011_detector uut (
        .clk(clk),
        .rst(rst),
        .w(w),
        .z(z)
    );

    // Generate clock, periode 10ns
    always #5 clk = ~clk;

    initial begin
        // Inisialisasi
        clk = 0;
        rst = 1;
        w   = 0;
        #10;
        rst = 0;

        // Test urutan: 1 0 1 1 0 1 1 (ada overlap 1011 di posisi 4 dan cek overlap lagi)
        // Setiap bit dikirim 1 clock cycle
        send_bit(1'b1);
        send_bit(1'b0);
        send_bit(1'b1);
        send_bit(1'b1);   // -> di sini seharusnya z=1 (pola 1011 pertama terdeteksi)
        send_bit(1'b0);
        send_bit(1'b1);
        send_bit(1'b1);   // -> cek overlap kedua

        #20;
        $finish;
    end

    task send_bit(input b);
        begin
            w = b;
            @(posedge clk);
            #1; // beri jeda kecil supaya z sempat update sebelum dicetak
            $display("Time=%0t | w=%b | state=%b | z=%b", $time, w, uut.state, z);
        end
    endtask

    // Dump waveform untuk dilihat di GTKWave/simulator
    initial begin
        $dumpfile("moore_1011.vcd");
        $dumpvars(0, tb_moore_1011_detector);
    end

endmodule