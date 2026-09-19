`timescale 1ns / 1ps

module rtl_modn #(parameter N = 10, parameter W = 4)(
 input wire clk, rstn, en,
 output reg [W-1:0] q,
 output wire tc // terminal count
);
 always @(posedge clk or negedge rstn)
 if (!rstn) q <= {W{1'b0}};
 else if (en) begin
 if (q == N-1) q <= {W{1'b0}}; // wrap
 else q <= q + 1'b1;
 end
 assign tc = en & (q == N-1);
endmodule
module rtl_updown3 (input wire clk, rstn, en, down, output reg [2:0] q);
 always @(posedge clk or negedge rstn)
 if (!rstn) q <= 3'd0;
 else if (en) q <= down ? q - 1'b1 : q + 1'b1; // wraps in both directions
endmodule
