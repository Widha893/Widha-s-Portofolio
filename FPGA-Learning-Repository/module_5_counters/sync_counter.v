module sync_mod8 (input wire clk, rstn, output wire [2:0] q); 
    wire t0 = 1'b1; 
    wire t1 = q[0]; 
    wire t2 = q[0] & q[1]; 
    dff_t F0 (.clk(clk), .rstn(rstn), .d(q[0] ^ t0), .q(q[0])); 
    dff_t F1 (.clk(clk), .rstn(rstn), .d(q[1] ^ t1), .q(q[1])); 
    dff_t F2 (.clk(clk), .rstn(rstn), .d(q[2] ^ t2), .q(q[2])); 
endmodule

module sync_mod6 (input wire clk, rstn, output wire [2:0] q); 
    wire d0 = ~q[0]; 
    wire d1 = (q[1] ^ q[0]) & ~q[2]; 
    wire d2 = (q[1] & q[0]) | (q[2] & ~q[0]); 
    dff_t F0 (.clk(clk), .rstn(rstn), .d(d0), .q(q[0])); 
    dff_t F1 (.clk(clk), .rstn(rstn), .d(d1), .q(q[1])); 
    dff_t F2 (.clk(clk), .rstn(rstn), .d(d2), .q(q[2])); 
endmodule

module sync_bcd (input wire clk, rstn, output wire [3:0] q); 
    wire t0 = 1'b1; 
    wire t1 = ~q[3] & q[0]; 
    wire t2 =  q[1] & q[0]; 
    wire t3 = (q[3] & q[0]) | (q[2] & q[1] & q[0]); 
    dff_t F0 (.clk(clk), .rstn(rstn), .d(q[0] ^ t0), .q(q[0])); 
    dff_t F1 (.clk(clk), .rstn(rstn), .d(q[1] ^ t1), .q(q[1])); 
    dff_t F2 (.clk(clk), .rstn(rstn), .d(q[2] ^ t2), .q(q[2])); 
    dff_t F3 (.clk(clk), .rstn(rstn), .d(q[3] ^ t3), .q(q[3])); 
endmodule