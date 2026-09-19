# Module 4 — Sequential Circuit Practice I: Shift Registers and Timing Verification

Practice module companion documentation. Covers building the four classical shift registers, the bidirectional and universal shift registers, and timing verification (clock-to-Q delay, latency, setup/hold checking, maximum clock frequency).

**Companion files:** `dff_t.v`, `shift_registers.v`, `shift_registers_tb.v`, `timing_tb.v`

**Tools:** Icarus Verilog + GTKWave, or AMD-Xilinx Vivado (XSim)

**Prerequisites:** Module 3 (flip-flops, setup/hold/clock-to-Q, synchronous design), Module 1 (testbenches)

---

## Table of Contents

- [Activity 0 — Essentials](#activity-0--essentials)
- [Activity 1 — Workspace and the Sequential Testbench Routine](#activity-1--workspace-and-the-sequential-testbench-routine)
- [Activity 2 — The PIPO Register](#activity-2--the-pipo-register)
- [Activity 3 — SIPO and SISO Registers](#activity-3--sipo-and-siso-registers)
- [Activity 4 — PISO, Bidirectional and Universal Registers](#activity-4--piso-bidirectional-and-universal-registers)
- [Activity 5 — Timing Verification](#activity-5--timing-verification)
- [Activity 6 — Regression, Waveforms and the Road to Hardware](#activity-6--regression-waveforms-and-the-road-to-hardware)
- [Command Reference](#command-reference)
- [Common Errors](#common-errors)
- [Glossary](#glossary)

---

## Activity 0 — Essentials

### 0.1 Registers and Their Modes

A **register** is a group of flip-flops sharing one clock, used to hold a word of data. Data may enter or leave the register in parallel (all bits at once) or in series (one bit per clock), giving four classical types:

| Type | Input | Output | Built in Activity |
|---|---|---|---|
| PIPO | Parallel | Parallel | 2 |
| SIPO | Serial | Parallel | 3 |
| SISO | Serial | Serial | 3 |
| PISO | Parallel | Serial | 4 |

A **shift register** is any register whose stages are chained so that data moves one position per clock.

### 0.2 The Flip-Flop with Visible Timing

A zero-delay flip-flop model cannot show the clock-to-output delay (`t_cq`) on a waveform. The flip-flop used throughout this module, `dff_t`, carries a parameter `TPD` that delays the update of `q` by a chosen number of nanoseconds, so `t_cq` can be seen on the waveform and measured with `$realtime`:

```verilog
module dff_t #(parameter TPD = 1.0)(input wire clk, rstn, d, output reg q);
    always @(posedge clk or negedge rstn)
        if (!rstn) q <= #TPD 1'b0;
        else       q <= #TPD d;   // intra-assignment delay: q changes TPD ns after the edge
endmodule
```

**Key Point:** `#TPD` is a **simulation model only** — synthesis ignores delays. It sits on the right-hand side of a non-blocking assignment (an intra-assignment delay), which schedules the update without blocking the rest of the block. Because outputs now change `TPD` ns after the edge, testbenches must wait longer than `TPD` before sampling — the `tick` task of this module waits 3 ns.

✓ **Checkpoint**
- [ ] You can name the four register types and their transfer modes.
- [ ] You can explain what `#TPD` does and why testbenches wait after the edge.

---

## Activity 1 — Workspace and the Sequential Testbench Routine

**Step 1.** Create a directory named `module4` and copy the four companion files into it.

**Step 2.** Open `shift_registers_tb.v` and locate the two tasks that script every test:

```verilog
always #5 clk = ~clk;                              // free-running 100 MHz clock
task tick;  begin @(posedge clk); #3; end endtask  // one clock, then wait past TPD
task reset; begin rstn = 0; #4; rstn = 1; #1; end endtask
```

Unlike combinational testbenches (Module 2), a sequential testbench must apply stimulus **in order**, clock by clock. Wrapping "one clock edge plus settling time" in a task makes scenarios read like a script: `reset; din = data; load = 1; tick; load = 0;`.

**Step 3.** Compile and run the functional testbench to confirm the toolchain:

```bash
# Icarus Verilog
iverilog -o sim dff_t.v shift_registers.v shift_registers_tb.v
vvp sim
```

```tcl
# Vivado XSim (batch)
xvlog dff_t.v shift_registers.v shift_registers_tb.v
xelab -debug typical shift_registers_tb -s sim
xsim sim -runall
```

**Troubleshooting**
- `"Unknown module type: dff_t"` — `dff_t.v` was not listed on the compile command.
- All outputs `x` — reset was not applied before the first tick.

✓ **Checkpoint**
- [ ] The functional testbench runs and prints PASS.
- [ ] You can explain what `tick` and `reset` do.

---

## Activity 2 — The PIPO Register

Four flip-flops capture `din` simultaneously on the clock edge when `load = 1`, and hold their value otherwise via feedback (`load ? din : q`) — the clock-enable idiom of Module 3. Four AND gates gate the outputs visible only while `oe = 1`.

```verilog
module pipo4 (input wire clk, rstn, load, oe, input wire [3:0] din,
              output wire [3:0] q, dout);
    wire [3:0] d = load ? din : q;        // hold when load = 0
    dff_t FA (.clk(clk), .rstn(rstn), .d(d[3]), .q(q[3]));
    dff_t FB (.clk(clk), .rstn(rstn), .d(d[2]), .q(q[2]));
    dff_t FC (.clk(clk), .rstn(rstn), .d(d[1]), .q(q[1]));
    dff_t FD (.clk(clk), .rstn(rstn), .d(d[0]), .q(q[0]));
    assign dout = q & {4{oe}};            // four AND gates
endmodule
```

**Stage 1 test:** for each data word, reset → load → tick → read `dout` with `oe = 1`, then again with `oe = 0`.

**Expected Output (verified)**
```
===== STAGE 1 : PIPO =====
din  -> dout (oe=1) | dout (oe=0)
1000 ->   1000      |   0000
0101 ->   0101      |   0000
1111 ->   1111      |   0000
0110 ->   0110      |   0000
1001 ->   1001      |   0000
```

**Troubleshooting**
- `dout` always `0000` — `oe` was not raised before reading.
- Register keeps changing after `load` returns to 0 — the hold path (`load ? din : q`) is missing.

✓ **Checkpoint**
- [ ] All five words are captured and gated correctly.
- [ ] You can explain how `load` implements a clock enable without a second clock.

> Record results in **Worksheet WS-1**.

---

## Activity 3 — SIPO and SISO Registers

Connecting Q of each stage to D of the next turns the PIPO register into a shift register: on every clock edge `q[3]` takes the serial input and every other stage takes its left neighbour. The bit entered first travels furthest, ending in `q[0]` after four clocks.

```verilog
module sipo4 (input wire clk, rstn, si, output wire [3:0] q, output wire so);
    dff_t FA (.clk(clk), .rstn(rstn), .d(si),    .q(q[3]));
    dff_t FB (.clk(clk), .rstn(rstn), .d(q[3]),  .q(q[2]));
    dff_t FC (.clk(clk), .rstn(rstn), .d(q[2]),  .q(q[1]));
    dff_t FD (.clk(clk), .rstn(rstn), .d(q[1]),  .q(q[0]));
    assign so = q[0];                     // serial output
endmodule
```

**Stage 2 test:** the loop presents `data[n][0]` first (the LSB), then bits 1, 2 and 3, one tick each.

**Expected Output (verified)**
```
===== STAGE 2 : SIPO (serial in, LSB first) =====
si on clocks 1-4 -> q[3:0]
0 0 0 1          -> 1000
1 0 1 0          -> 0101
1 1 1 1          -> 1111
0 1 1 0          -> 0110
1 0 0 1          -> 1001

===== STAGE 3 : SISO (serial in -> serial out, 4-clock delay) =====
si on clocks 1-4 -> so on clocks 5-8
0 0 0 1          -> 0 0 0 1
1 0 1 0          -> 1 0 1 0
1 1 1 1          -> 1 1 1 1
0 1 1 0          -> 0 1 1 0
1 0 0 1          -> 1 0 0 1
```

**Key Point:** Because the LSB enters first and travels to `q[0]`, the parallel word reads back in its natural order. Stage 3 shows the register acting as a **delay line**: the serial output reproduces the serial input exactly four clocks later — the common use of SISO in DSP, where a chain of such delays implements the z⁻¹ elements of a filter.

**Troubleshooting**
- Parallel word reversed — data entered MSB first instead of LSB first.
- Every stage holds the same value — all D inputs tied to `si` instead of to the previous stage.

✓ **Checkpoint**
- [ ] The five SIPO words and five SISO sequences match the expected output.
- [ ] You can state the latency of the SISO register in clock periods.

> Record results in **Worksheet WS-2**.

---

## Activity 4 — PISO, Bidirectional and Universal Registers

### 4.1 PISO: Synchronous Parallel Load

Parallel data is admitted through a multiplexer in front of each stage: `load = 1` captures `din`, `load = 0` shifts (takes the previous stage). Loading is **synchronous** — it happens on the clock edge like every other transfer, unlike older TTL designs which loaded through the flip-flops' asynchronous preset inputs.

```verilog
wire [3:0] d;
assign d[3] = load ? din[3] : 1'b0;   // shift in zeros
assign d[2] = load ? din[2] : q[3];
assign d[1] = load ? din[1] : q[2];
assign d[0] = load ? din[0] : q[1];
```

**Expected Output (verified)**
```
===== STAGE 4 : PISO (parallel load, serial out LSB first) =====
din  -> so on clocks 1-4
1000 ->  0 0 0 1
0101 ->  1 0 1 0
1111 ->  1 1 1 1
0110 ->  0 1 1 0
1001 ->  1 0 0 1
```

### 4.2 Bidirectional Register

The same multiplexer chooses between two neighbours: `dir = 1` selects the left neighbour (shift right, serial input `sir` enters at `q[3]`); `dir = 0` selects the right neighbour (shift left, serial input `sil` enters at `q[0]`).

```verilog
assign d[3] = dir ? sir : q[2];
assign d[2] = dir ? q[3] : q[1];
assign d[1] = dir ? q[2] : q[0];
assign d[0] = dir ? q[1] : sil;
```

**Expected Output (verified)**
```
===== STAGE 5 : BIDIRECTIONAL (right for 4 clocks, then left for 5) =====
clock dir in | q    direction
0     1   0  | 0000 right
1     1   1  | 1000 right
2     1   0  | 0100 right
3     1   1  | 1010 right
4     1   1  | 1101 right
5     0   1  | 1011 left
6     0   0  | 0110 left
7     0   0  | 1100 left
8     0   1  | 1001 left
9     0   1  | 0011 left
```

### 4.3 The Universal Shift Register in RTL

One component covering all four modes, written behaviourally (Template B) — this is the form used for synthesis.

| mode | operasi |
|---|---|
| 00 | hold |
| 01 | shift right (`sir` enters at `q[3]`) |
| 10 | shift left (`sil` enters at `q[0]`) |
| 11 | parallel load from `din` |

```verilog
module universal4 (input wire clk, rstn, input wire [1:0] mode, input wire sir, sil,
                    input wire [3:0] din, output reg [3:0] q);
    always @(posedge clk or negedge rstn)
        if (!rstn) q <= 4'b0000;
        else case (mode)
            2'b00: q <= q;               // hold
            2'b01: q <= {sir, q[3:1]};   // shift right
            2'b10: q <= {q[2:0], sil};   // shift left
            2'b11: q <= din;             // parallel load
        endcase
endmodule
```

**Expected Output (verified)**
```
===== STAGE 6 : UNIVERSAL REGISTER (RTL) =====
mode 11 load        -> q = 1011
mode 00 hold        -> q = 1011
mode 01 shift right -> q = 0101
mode 10 shift left  -> q = 1011
>> PASS: all shift registers behaved as expected.
```

**Key Point:** The structural registers and the RTL register describe the same hardware at two levels of abstraction. Synthesis of `universal4` produces precisely the multiplexer-per-stage structure of the PISO/bidirectional designs.

**Troubleshooting**
- PISO shifts out the wrong order — `so` must be `q[0]`; the LSB leaves first.
- Bidirectional shift left inserts 0 instead of `sil` — `d[0]` does not select `sil` when `dir = 0`.
- Universal register ignores `mode` — the `case` is outside the `else` branch, or uses `=` instead of `<=`.

✓ **Checkpoint**
- [ ] Stages 4, 5 and 6 all match the expected output.
- [ ] You can map each universal mode onto one of the structural registers.

> Record results in **Worksheet WS-3**.

---

## Activity 5 — Timing Verification

### 5.1 Measuring t_cq

Run the timing testbench:

```bash
iverilog -o simt dff_t.v shift_registers.v timing_tb.v && vvp simt
```

Part A instantiates two flip-flops with different `TPD` parameters and records, with `$realtime`, the instant of the clock edge and the instant each output changes.

**Expected Output (verified)**
```
===== PART A : CLOCK-TO-Q DELAY =====
edge at 15.0 ns : q1 changed at 16.0 ns -> t_cq = 1.0 ns (TPD = 1.0)
edge at 15.0 ns : q2 changed at 17.5 ns -> t_cq = 2.5 ns (TPD = 2.5)
```

In GTKWave: place a marker on the rising edge of `clk` at 15 ns and a second on the transition of `q1`; read the difference. Repeat for `q2`. (The testbench's own `t_edge`, `t_q1`, `t_q2` realtime traces give the same values directly, without manual markers.)

### 5.2 Measuring Latency

Part B injects a single `1` into the SISO register and counts clock edges until it reappears at the serial output.

**Expected Output (verified)**
```
===== PART B : SISO LATENCY =====
a 1-bit pulse entered on clock 1 appeared at the serial output on clock 4
-> latency of the 4-stage register = 4 clock periods
```

**Key Point:** Latency (clock periods from input to output) and clock-to-Q (nanoseconds from edge to output) are different quantities that beginners often confuse. Latency is a property of the **architecture** (four stages → four clocks) and is independent of clock frequency; `t_cq` is a property of the **flip-flop** and bounds the maximum clock frequency.

### 5.3 The Setup/Hold Checker

`setup_hold_checker` is a **simulation-only instrument**. It records the time of every change of its `d` input and of every rising clock edge, and reports a violation whenever `d` changes less than `T_SETUP` before an edge or less than `T_HOLD` after one.

```verilog
setup_hold_checker #(.T_SETUP(2.0), .T_HOLD(1.0)) CHK (.clk(clk), .d(d));
```

**Expected Output (verified)**
```
===== PART C : SETUP / HOLD CHECK (T_SETUP = 2 ns, T_HOLD = 1 ns) =====
clean stimulus: d changes 5 ns before every edge
violations so far = 0
bad stimulus (a): d changes 1 ns BEFORE the edge
!! SETUP violation at 115.0 ns : d changed 1.0 ns before the edge (need 2.0)
bad stimulus (b): d changes 0.5 ns AFTER the edge
!! HOLD violation at 115.5 ns : d changed 0.5 ns after the edge (need 1.0)
violations now = 2 (expected 2: one setup, one hold)
```

**Why it's needed:** A functional testbench only checks whether values are correct — it cannot detect that `d` changed too close to a clock edge, because behavioural simulation cannot model metastability (an analog, physical phenomenon). The checker turns this otherwise-invisible hazard into a visible report. Commercial simulators provide the equivalent service through `$setup`/`$hold` timing checks in `specify` blocks (IEEE 1364-2005); this checker is a portable, transparent stand-in.

**Step 3.** In `timing_tb.v`, find the two lines creating the violations (`#9` after the previous edge; `#0.4` after the edge). Change `#9` to `#7` and re-run: the setup violation disappears, since `d` now changes 3 ns before the edge.

### 5.4 Maximum Clock Frequency

Applies the Module 3 constraint $T \ge t_{cq} + t_{logic} + t_{setup}$ to the measured `t_cq`, a representative logic delay, and the checker's setup time.

**Expected Output (verified)**
```
===== PART D : MAXIMUM CLOCK FREQUENCY ESTIMATE =====
t_cq = 1.0 ns (measured), t_logic = 3.2 ns (given), t_setup = 2.0 ns (checker)
T_min = 1.0 + 3.2 + 2.0 = 6.2 ns -> f_max = 161.3 MHz
at 100 MHz (T = 10 ns) the slack is 10 - 6.2 = +3.8 ns (constraint met)
>> PASS: timing measurements and checks behaved as expected.
```

The universal register has almost no logic between stages (one multiplexer), so it is far from the limit at 100 MHz; a register followed by a ripple-carry adder would not be. Post-implementation timing reports in Vivado give the real values for a placed design.

**Troubleshooting**
- `t_cq` reads 0.0 — the flip-flop is not `dff_t`, or `TPD` was set to 0.
- Checker reports violations on the clean stimulus — `d` is changing at the edge; change it at `negedge` or mid-cycle.
- Latency measures 5 — the pulse was applied after the edge instead of before it.

✓ **Checkpoint**
- [ ] `t_cq` measured 1.0 ns and 2.5 ns for the two flip-flops.
- [ ] Latency measured 4 clock periods.
- [ ] Checker reported 0 violations for the clean stimulus and 2 for the bad one.
- [ ] You can compute `f_max` for a different `t_logic`.

> Record results in **Worksheet WS-4**.

---

## Activity 6 — Regression, Waveforms and the Road to Hardware

Re-run the complete suite in one pass:

```bash
iverilog -o s1 dff_t.v shift_registers.v shift_registers_tb.v && vvp s1 | grep ">>"
iverilog -o s2 dff_t.v shift_registers.v timing_tb.v && vvp s2 | grep ">>"
```

**Expected Output (verified) — two verdict lines**
```
>> PASS: all shift registers behaved as expected.
>> PASS: timing measurements and checks behaved as expected.
```

**Step 1.** Open `shift_registers_tb.vcd`, add `clk`, `si`, and the four bits of `qs` (Stage 2) to the wave pane; follow one `1`-bit as it moves from `q[3]` to `q[0]` across four clock edges — the visual form of shifting. Every transition occurs 1 ns after the edge.

**Step 2.** Add `qb` and `dir` (Stage 5) and locate the clock at which `dir` falls: the pattern reverses direction of travel.

**Hardware preview:** `universal4` is synthesisable as written. Wrapped in a board-level module mapping `mode`, `sir`, `sil`, `din` to switches, a debounced push-button to a single-step clock enable, and `q` to LEDs, it runs on the Basys3 exactly as simulated. As in Module 3: **the button never becomes the clock — it becomes an enable.**

✓ **Checkpoint**
- [ ] Both verdict lines read PASS from a clean directory.
- [ ] You can point to the shifting pattern and the direction reversal on the waveform.

---

## Command Reference

```bash
# ---------- run ----------
iverilog -o sim dff_t.v shift_registers.v <tb>.v && vvp sim     # Icarus
xvlog dff_t.v shift_registers.v <tb>.v ; xelab -debug typical <tb> -s s ; xsim s -runall   # XSim
gtkwave <tb>.vcd | xsim --gui s.wdb

# ---------- sequential testbench idioms ----------
always #5 clk = ~clk;                                # 100 MHz clock
task tick;  begin @(posedge clk); #3; end endtask    # one edge, then settle past TPD
task reset; begin rstn = 0; #4; rstn = 1; #1; end endtask
always @(posedge clk) t_edge = $realtime;            # time-stamp an edge
always @(q)           t_q    = $realtime;            # time-stamp an output change

# ---------- shift idioms (RTL) ----------
q <= {sir, q[3:1]};   # shift right, sir enters at the MSB
q <= {q[2:0], sil};   # shift left, sil enters at the LSB
q <= din;             # parallel load (synchronous)

# ---------- timing ----------
T >= t_cq + t_logic + t_setup     f_max = 1 / T     slack = T_clk - T
```

## Common Errors

| Symptom | Cause and remedy |
|---|---|
| All outputs `x` | Reset not applied before the first clock |
| Parallel word reversed | Serial data entered MSB first; enter LSB first |
| Every stage holds the same value | All D inputs tied to `si` instead of to the previous stage |
| Register changes when `load = 0` | Hold path (`load ? din : q`) missing in PIPO |
| Shift left inserts 0 | `d[0]` does not select `sil` when `dir = 0` |
| Sampled value is one clock late | Testbench samples before `TPD` has elapsed; wait after the edge |
| Checker flags the clean stimulus | `d` changed at the clock edge; change it at `negedge` |
| `t_cq` measures 0 | `TPD` parameter set to 0, or a zero-delay flip-flop used |
| `"Unknown module type: dff_t"` | `dff_t.v` missing from the compile command |

## Glossary

| Term | Definition |
|---|---|
| Shift register | A register whose stages are chained so that data moves one position per clock |
| PIPO / SIPO / SISO / PISO | Register types named by parallel or serial input and output |
| Universal shift register | A register offering hold, shift right, shift left and parallel load under a mode input |
| Clock enable | A condition that lets a flip-flop ignore a clock edge, in place of gating the clock |
| Latency | Number of clock periods from an input to its appearance at an output |
| Clock-to-output delay (`t_cq`) | Time from the clock edge to the change of a flip-flop output |
| Setup / hold time | Windows before / after the edge during which the data input must be stable |
| Timing checker | A simulation construct that reports setup/hold violations |
| Slack | Margin by which a timing path meets its constraint |

---

## Verification Notes

All four companion files were compiled and simulated with Icarus Verilog before publication. `shift_registers_tb` reports PASS across six stages (PIPO, SIPO, SISO and PISO with the five-word data set, the ten-clock bidirectional scenario, and the four universal modes); `timing_tb` reports PASS with `t_cq` measured at 1.0 ns and 2.5 ns, a SISO latency of 4 clock periods, and the setup/hold checker reporting 0 violations on the clean stimulus and exactly 2 on the deliberately bad one.

## References

1. M. M. Mano and M. D. Ciletti, *Digital Design: With an Introduction to the Verilog HDL*, 6th ed. Pearson, 2018. (Ch. 6: Registers and Counters.)
2. J. F. Wakerly, *Digital Design: Principles and Practices*, 5th ed. Pearson, 2018.
3. S. Palnitkar, *Verilog HDL: A Guide to Digital Design and Synthesis*, 2nd ed. Prentice Hall PTR, 2003.
4. C. E. Cummings, "Nonblocking Assignments in Verilog Synthesis, Coding Styles That Kill!", SNUG San Jose, 2000.
5. IEEE Std 1364-2005, *IEEE Standard for Verilog Hardware Description Language*. IEEE, 2006. (Section 15: Timing checks.)
6. AMD-Xilinx, *Vivado Design Suite User Guide: Logic Simulation* (UG900).
7. AMD-Xilinx, *UltraFast Design Methodology Guide for FPGAs and SoCs* (UG949).

---

*Based on Module 4 — Sequential Circuit Practice I: Shift Registers, prepared by Ika Candradewi, S.Si., M.Cs., Electronics and Instrumentation Study Programme, Universitas Gadjah Mada. First Edition — September 2026.*