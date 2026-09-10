module priority_encoder4to2 (
    input wire [3:0] d,
    output reg [1:0] y,
    output reg valid // 1 when at least one input is active
);
    always @(*) begin
    valid = 1'b1;
    casez (d)
        4'b1???: y = 2'd3; // highest priority: d3
        4'b01??: y = 2'd2;
        4'b001?: y = 2'd1;
        4'b0001: y = 2'd0;
        default: begin y = 2'd0; valid = 1'b0; end // no input active
    endcase
    end
endmodule