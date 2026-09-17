module mealy_1011_detector (
    input  wire clk,
    input  wire rst,
    input  wire X,
    output wire Z
);
    reg Q1, Q0;

    wire D1 = (~Q1 & Q0 & ~X) | (Q1 & ~Q0 & ~X) | (Q1 & Q0 & X);
    wire D0 = (~Q1 & Q0) | (Q1 & ~Q0) | (~Q0 & X);

    assign Z = Q1 & ~Q0 & X;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            Q1 <= 1'b0;
            Q0 <= 1'b0;
        end else begin
            Q1 <= D1;
            Q0 <= D0;
        end
    end
endmodule