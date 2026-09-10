module decoder2to4_case(
    input wire [1:0] a,
    input wire en,
    output reg [3:0] y
);
    always @(*) begin
        if (en)
            case(a)
                2'b00: y = 4'b0001;
                2'b01: y = 4'b0010;
                2'b10: y = 4'b0100;
                2'b11: y = 4'b1000;
                default: y = 4'b0000;
            endcase
        else
            y = 4'b0000;
    end
endmodule

module decoder2to4_shift(
    input wire [1:0] a,
    input wire en,
    output wire [3:0] y
);
    assign y = {4{en}} & (4'b0001 << a);
endmodule

module decoder3to8_shift(
    input wire [2:0] a,
    input wire en,
    output wire [7:0] y
);
    assign y = {8{en}} & (8'b0000_0001 << a);
endmodule

module decoder3to8_case(
    input wire [2:0] a,
    input wire en,
    output reg [7:0] y
);
    always @(*) begin
        if (en)
            case(a)
                3'b000: y = 8'b0000_0001;
                3'b001: y = 8'b0000_0010;
                3'b010: y = 8'b0000_0100;
                3'b011: y = 8'b0000_1000;
                3'b100: y = 8'b0001_0000;
                3'b101: y = 8'b0010_0000;
                3'b110: y = 8'b0100_0000;
                3'b111: y = 8'b1000_0000;
                default: y = 8'b0000_0000;
            endcase
        else
            y = 8'b0000_0000;
    end
endmodule