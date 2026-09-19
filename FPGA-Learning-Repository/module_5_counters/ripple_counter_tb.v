`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/14/2026 02:53:27 PM
// Design Name: 
// Module Name: ripple_counter_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module ripple_counter_tb;


reg clk;
reg rst;


wire [2:0] q;



// DUT

ripple_counter DUT(

    .clk(clk),
    .rst(rst),
    .q(q)

);



// clock 10 ns

always #5 clk = ~clk;



initial begin


    clk = 0;
    rst = 1;


    // reset
    #10;

    rst = 0;



    // run counter
    #100;


    $finish;


end



// tampilkan hasil

always @(q)
begin

    $display(
        "Time=%0t | Q=%b | Decimal=%0d",
        $time,
        q,
        q
    );

end



endmodule
