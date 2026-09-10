module comb_system (
    input wire din,
    input wire [1:0] sel, code,
    input wire en,
    output wire dout,
    output wire [3:0] channel,
    output wire [1:0] code_back,
    output wire valid
);
    demux1to4 DM (.din(din), .sel(sel), .y(channel));
    mux4to1 MX (.data(channel), .sel(sel), .y(dout));
    wire [3:0] onehot; // link 2
    decoder2to4_shift DC (.a(code), .en(en), .y(onehot));
    priority_encoder4to2 PE (.d(onehot), .y(code_back), .valid(valid));
endmodule