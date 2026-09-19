`timescale 1ns / 1ps
//======================================================================
//  dff_t.v  --  D flip-flop with a modelled clock-to-Q delay, and a
//               behavioural setup/hold checker
//----------------------------------------------------------------------
//  Module 4 : Sequential Circuit Practice I
//
//  dff_t              : rising-edge D flip-flop, asynchronous active-low
//                       reset, clock-to-Q delay TPD (ns). The delay makes
//                       timing VISIBLE and MEASURABLE in the waveform.
//  setup_hold_checker : watches a data input relative to the clock edge
//                       and reports every setup or hold violation. It is
//                       a simulation-only instrument (never synthesised).
//======================================================================

module dff_t #(
    parameter TPD = 1.0                 // clock-to-Q delay in ns
)(
    input  wire clk, rstn, d,
    output reg  q
);
    always @(posedge clk or negedge rstn)
        if (!rstn) q <= #TPD 1'b0;
        else       q <= #TPD d;          // intra-assignment delay
endmodule


module setup_hold_checker #(
    parameter real T_SETUP = 2.0,       // ns before the edge: d must be stable
    parameter real T_HOLD  = 1.0        // ns after the edge:  d must stay stable
)(
    input wire clk, d
);
    realtime t_d   = -1.0e9;            // time of the last change of d
    realtime t_clk = -1.0e9;            // time of the last rising clock edge
    integer  violations = 0;

    always @(d) begin
        t_d = $realtime;
        if (t_clk >= 0 && (t_d - t_clk) < T_HOLD) begin
            violations = violations + 1;
            $display("   !! HOLD  violation at %0t : d changed %0.1f ns after the edge (need %0.1f)",
                     $realtime, t_d - t_clk, T_HOLD);
        end
    end

    always @(posedge clk) begin
        t_clk = $realtime;
        if (t_d >= 0 && (t_clk - t_d) < T_SETUP) begin
            violations = violations + 1;
            $display("   !! SETUP violation at %0t : d changed %0.1f ns before the edge (need %0.1f)",
                     $realtime, t_clk - t_d, T_SETUP);
        end
    end
endmodule
