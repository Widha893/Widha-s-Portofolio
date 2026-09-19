module moore_1011_detector (
    input  wire clk,
    input  wire rst,     // reset asynchronous, active high
    input  wire w,       // input serial bit
    output wire z         // output: 1 saat pola 1011 terdeteksi
);

    // Encoding state pakai Gray code (Q2 Q1 Q0)
    localparam S0 = 3'b000; // belum ada progres
    localparam S1 = 3'b001; // sudah "1"
    localparam S2 = 3'b011; // sudah "10"
    localparam S3 = 3'b010; // sudah "101"
    localparam S4 = 3'b110; // sudah "1011" -> output 1

    reg [2:0] state, next_state;

    // Next-state logic (kombinasional)
    always @(*) begin
        case (state)
            S0: next_state = w ? S1 : S0;
            S1: next_state = w ? S1 : S2;
            S2: next_state = w ? S3 : S2;
            S3: next_state = w ? S4 : S3;
            S4: next_state = w ? S1 : S2;
            default: next_state = S0; // handle unused/don't-care states
        endcase
    end

    // State register (3 D flip-flop)
    always @(posedge clk or posedge rst) begin
        if (rst)
            state <= S0;
        else
            state <= next_state;
    end

    // Output logic (Moore: hanya bergantung state)
    assign z = (state == S4);

endmodule