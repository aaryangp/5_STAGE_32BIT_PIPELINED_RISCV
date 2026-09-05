# RV32I Pipelined Processor

A 5-stage pipelined RISC-V (RV32I) CPU implemented in Verilog, built up incrementally from a verified single-cycle design: full classic pipeline (IF/ID/EX/MEM/WB), EX-stage data forwarding, load-use hazard stalling, static branch prediction with misprediction recovery, and unconditional jumps (JAL/JALR). Every stage of this was implemented and then verified against Icarus Verilog (`iverilog`/`vvp`) simulation traces before moving on to the next.

[View the interactive version →][https://claude.ai/code/artifact/64c820fa-0fbb-416c-b3ac-fe3e7a324c95]

## Status

| Feature | Status |
|---|---|
| Single-cycle RV32I (base ISA) | ✅ Done, verified |
| 5-stage pipeline (IF/ID/EX/MEM/WB) | ✅ Done, verified |
| EX-stage data forwarding (RAW hazards) | ✅ Done, verified |
| Load-use hazard detection + stall | ✅ Done, verified |
| Control hazards: static branch prediction + flush | ✅ Done, verified |
| Jumps: JAL / JALR | ✅ Done, verified |

## Architecture


        IF                ID                 EX                MEM                WB
   ┌──────────┐      ┌──────────┐      ┌───────────┐      ┌───────────┐      ┌──────────┐
   │   PC     │      │ Register │      │    ALU     │      │   Data    │      │ Register │
   │   +      │─────▶│  File +  │─────▶│    +       │─────▶│  Memory   │─────▶│  Write   │
   │ I-Memory │      │ Control  │      │ Forwarding │      │           │      │   Mux    │
   └──────────┘      └──────────┘      └───────────┘      └───────────┘      └──────────┘
        │                  │                  │                  │
        └── IF/ID ─────────┘── ID/EX ─────────┘── EX/MEM ────────┘── MEM/WB


Cross-cutting hazard units sit alongside the datapath rather than inside any one stage:

- **Forwarding unit** (EX stage) — resolves most RAW data hazards without stalling, by feeding EX/MEM and MEM/WB results back into the ALU inputs instead of the (possibly stale) register-file read.
- **Hazard detection unit** (ID/EX boundary) — catches the one case forwarding *can't* fix (load-use), and stalls the pipeline for exactly one cycle.
- **Branch predictor** (ID stage) — a static "always predict not-taken" predictor; its guess rides along with the instruction until EX/MEM resolves the real outcome.
- **Misprediction / flush logic** (MEM stage) — compares the real outcome to the prediction and, on a mismatch, redirects the PC and simultaneously flushes IF/ID, ID/EX, and EX/MEM in the same cycle.

## Repository layout

top.v                   -- top-level module wiring every stage and pipeline register together
testbench1.v            -- testbench: per-cycle trace + final register-value checks

# Pipeline registers
IF_ID.v             -- IF -> ID  (supports stall + flush)
ID_EX.v             -- ID -> EX  (supports flush; carries all control + operands + rs1/rs2/rd)
EX_MEM.v            -- EX -> MEM (supports flush; carries resolved branch/jump outcome + target)
MEM_WB.v            -- MEM -> WB

# Datapath
PC.v                    -- program counter (supports stall, for load-use hazards)
PC_adder.v              -- PC+4 adder (reused for the JAL/JALR link value too)
instruction_memory.v    -- instruction ROM
register_bank.v         -- register file (with same-cycle write-through bypass, see below)
immedgenerator.v        -- immediate decoder for all instruction formats (I/S/B/J-type)
mux.v / mux3.v          -- generic 2:1 / 3:1 muxes
ALU_unit.v              -- the ALU itself
ALU_control.v           -- ALUOp+funct3+funct7 -> ALU operation decode
branch_adder.v          -- PC + immediate adder, for branches and JAL
data_memory.v           -- data RAM
and.v                   -- 1-bit AND gate, used for the branch/jump PC-redirect condition

# Control / hazard logic
controlunit.v            -- main instruction decoder (all control signals)
forwarding_unit.v        -- EX-stage RAW hazard forwarding logic
hazard_detection_unit.v  -- load-use hazard detector (drives the stall)
branch_predictor.v       -- static not-taken branch predictor

# Test programs
program.hex                  -- current test program (JAL/JALR)
program_hazards_test.hex     -- earlier regression test (forwarding + load-use stall + branch)

# Reference / archive
top_orig.v, testbench1_orig.v -- the original, unmodified single-cycle implementation

## Instructions currently supported

**Base RV32I:**

- Arithmetic/logic (R-type): ADD, SUB, AND, OR, XOR, SLT, SLL, SRL, SRA
- Arithmetic/logic (I-type immediate): ADDI, SLTI, ANDI, ORI, XORI, SLLI, SRLI, SRAI
- Memory: LW, SW
- Conditional branches: BEQ, BNE, BLT, BGE
- Unconditional jumps: JAL, JALR

**Not yet implemented:** SLTU, BLTU`/`BGEU`, `LUI`/`AUIPC`, `LB/LH/LBU/LHU/SB/SH` (byte/half-word memory access — only word-aligned `LW`/`SW` exist today), CSR instructions, and traps/exceptions.

**RV32M (in progress):** the ALU and control-decode logic for MUL, MULH, MULHSU, MULHU, DIV, DIVU, REM, REMU are implemented — including the RISC-V spec's required behavior for division by zero and the signed-overflow edge case (`INT_MIN / -1`) — but a dedicated test program and full simulation run haven't been completed yet.

## How data hazards are handled

Two different mechanisms cover two different classes of RAW hazard, and the split matters:

1. **EX-stage forwarding** — when an instruction's result is available in EX/MEM or MEM/WB by the time a later instruction needs it in EX, the forwarding unit routes that value directly into the ALU instead of the register file's (stale) output. This covers producers 1 and 2 instructions ahead of the consumer.
2. **Register-file same-cycle bypass** — a subtler case: a producer exactly 3 instructions ahead of its consumer has its write-back land on the *same clock edge* as the consumer's register read. That's invisible to EX-stage forwarding (it only looks at EX/MEM and MEM/WB, not the register file itself), and Verilog's nonblocking-assignment semantics would otherwise resolve the read to the pre-write value. register_bank.v adds an explicit combinational write-through (if writing this cycle to the register being read, return the value being written) to fix this.
3. **Load-use stall** — when forwarding *can't* work at all: a lw immediately followed by an instruction that needs its result. At the point forwarding would need the value, EX/MEM.ALU_Result for a load is still just the memory *address*, not the loaded data (that only exists after MEM completes). hazard_detection_unit.v detects this exact pattern and stalls the pipeline for one cycle (holding PC and IF/ID, bubbling ID/EX) so the load's result becomes available through the normal MEM/WB forwarding path by the time the consumer re-enters EX.

## How control hazards are handled

The predictor is deliberately simple — it always predicts **not taken** — so no new IF-stage hardware was needed (the PC already defaults to PC+4). The real outcome is computed in EX/resolved in MEM and compared against the prediction:

verilog
misprediction = (Branch | Jump) && (actual_outcome != predicted_taken);

On a misprediction, three things happen on the same clock edge: the PC is redirected to the correct target, and **IF/ID, ID/EX, and EX/MEM are all flushed simultaneously** — every instruction that was fetched down the wrong path gets turned into a bubble before it can do any damage (write a register, redirect the PC again, etc.). This costs exactly 3 cycles per misprediction.

Jumps (JAL/JALR) reuse this exact mechanism: they're modeled as branches that are *unconditionally* taken, which — combined with the always-not-taken predictor — means every jump is a guaranteed misprediction today. It's correct, just not yet optimized (a jump-aware predictor or early jump resolution in ID would remove this cost; noted as a possible improvement below).

## Building and running

Requires [Icarus Verilog](https://steveicarus.github.io/iverilog/):

bash
iverilog -o sim testbench1.v
vvp sim


This prints a per-cycle trace of every pipeline stage (PC, instruction, control signals, forwarding selects, stall/misprediction flags, ALU results) followed by a final register-value check against the expected results for whichever program is currently loaded via `` `include ``/instruction memory initialization.

To run the earlier hazard-focused regression test instead of the current JAL/JALR program, swap `program_hazards_test.hex` in as the instruction memory's $readmemh source.

- Finish and verify RV32M (multiply/divide).
- Special-case jumps in the branch predictor (always-taken) to remove their guaranteed 3-cycle misprediction penalty.
- Add LUI/AUIPC, SLTU/BLTU/BGEU, and byte/half-word loads and stores for fuller RV32I coverage.
- CSR instructions and basic trap/exception handling.
- A GCC/toolchain-generated C program as a test input, once memory-mapped I/O or a syscall convention exists to observe program output.
