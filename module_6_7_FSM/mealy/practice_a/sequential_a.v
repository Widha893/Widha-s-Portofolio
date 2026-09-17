module mealy_fsm_AB (
    input  wire clk,
    input  wire rst,   // reset asynchronous, active high -> ke state P (A=0,B=0)
    input  wire X,
    output wire Z
);

    reg A, B;
    wire D_A, D_B;

    // Persamaan next-state hasil K-map (sudah diberikan di soal)
    assign D_A = B & X;
    assign D_B = (~X) | (~A & B & X);

    // Output logic (Mealy: bergantung state DAN input)
    assign Z = A & (~B) & (~X);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            A <= 1'b0;
            B <= 1'b0;
        end else begin
            A <= D_A;
            B <= D_B;
        end
    end

endmodule