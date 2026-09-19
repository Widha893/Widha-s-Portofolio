module counter_00_60 (
    input  wire       clk,    // system clock
    input  wire       rstn,   // asynchronous reset, active low
    input  wire       en,     // count enable
    output reg  [3:0] ones,   // ones digit, 0..9
    output reg  [3:0] tens,   // tens digit, 0..6
    output wire       tc      // terminal count: currently at 60
);
    assign tc = en & (tens == 4'd6) & (ones == 4'd0);

    always @(posedge clk or negedge rstn) begin
        if (!rstn) begin
            ones <= 4'd0;
            tens <= 4'd0;
        end
        else if (en) begin
            if (tens == 4'd6 && ones == 4'd0) begin // already 60 -> back to 00
                ones <= 4'd0;
                tens <= 4'd0;
            end
            else if (ones == 4'd9) begin             // ones full -> carry to tens
                ones <= 4'd0;
                tens <= tens + 4'd1;
            end
            else begin                               // ordinary increment
                ones <= ones + 4'd1;
            end
        end
    end
endmodule