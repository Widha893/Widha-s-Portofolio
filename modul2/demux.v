module demux1to2 (
    input wire din,
    input wire sel,
    output reg [1:0] y
);

    always @(*) begin
        y = 2'b00;
        case (sel)
            1'b0: y[0] = din;
            1'b1: y[1] = din;
        endcase
    end
endmodule

module demux1to4 (
    input wire din,
    input wire [1:0] sel,
    output reg [3:0] y
);
    always @(*) begin
        y = 4'b0000; // default first: every output defined
        case (sel)
            2'b00: y[0] = din; // then override the selected output
            2'b01: y[1] = din;
            2'b10: y[2] = din;
            2'b11: y[3] = din;
            default: y = 4'b0000;
        endcase
    end
endmodule