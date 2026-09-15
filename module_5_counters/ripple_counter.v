`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/14/2026 02:52:59 PM
// Design Name: 
// Module Name: ripple_counter
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


//====================================================
// T Flip-Flop
// Toggle FF: setiap clock, Q berubah kebalikannya
//====================================================

module t_ff(
    input wire clk,
    input wire rst,
    output reg q
);


always @(posedge clk or posedge rst)
begin

    if(rst)
        q <= 1'b0;

    else
        q <= ~q;

end


endmodule



//====================================================
// 3-bit Ripple Counter
//====================================================

module ripple_counter(

    input wire clk,
    input wire rst,

    output wire [2:0] q

);


// First flip flop
dff_t FF0 (
    .clk(clk),
    .rstn(rst),
    .d(~q[0]),
    .q(q[0])
);


// Second flip flop
dff_t FF1 (
    .clk(~q[0]),
    .rstn(rst),
    .d(~q[1]),
    .q(q[1])
);


// Third flip flop
dff_t FF2 (
    .clk(~q[1]),
    .rstn(rst),
    .d(~q[2]),
    .q(q[2])
);


endmodule