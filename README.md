# 8-bit CPU (VHDL)

A small single-accumulator 8-bit CPU written in VHDL for the *Digital Technology* course (SS 2026).

**Status:** RTL core complete and verified in simulation (7 testbenches, 53 checks, 0 failures). FPGA board integration (Nexys A7) is in progress — see [Roadmap](#roadmap).

## Architecture

```
CPU_Top (structural)
├── Program_Counter       4-bit PC (increment / jump)
├── Memory_Unit           4 program ROMs + 16-byte data RAM
├── Instruction_Register  8-bit instruction latch
├── Control_Unit          fetch/decode/execute FSM (three-process)
├── ALU                   combinational arithmetic + logic, with flags
└── Accumulator           8-bit working register
```

8-bit datapath, 16-byte address space. Async reset, synchronous `Clock_Enable` on every register (for single-stepping), VHDL-2008.

## Instruction format

One byte: upper nibble = opcode, lower nibble = operand/address. Opcodes are defined in `CPU_Package.vhd`:

`NOP LOAD_IMMEDIATE LOAD_MEMORY STORE_MEMORY ADD_MEMORY SUB_MEMORY AND_MEMORY OR_MEMORY XOR_MEMORY NOT_ACC JUMP JUMP_IF_ZERO JUMP_IF_CARRY OUT CLEAR HALT`

## Demo programs

Selected by the `Program_Select` input:

| Sel | Demonstrates | Output |
|:---:|---|:---:|
| `00` | arithmetic + load/store + output | `04` |
| `01` | 8-bit datapath (`0F + 01 = 10`) | `10` |
| `10` | logic operations | `0F` |
| `11` | conditional jump on zero flag | `07` |

## Build & simulate

**Vivado:** add `src/` as design sources and `sim/` as simulation sources, set a testbench as *Top*, Run Behavioral Simulation, then `run -all`.

**GHDL** (analyse `CPU_Package.vhd` first):

```sh
ghdl -a --std=08 src/*.vhd sim/CPU_Top_tb.vhd
ghdl -e --std=08 CPU_Top_tb
ghdl -r --std=08 CPU_Top_tb --stop-time=60us
```

Each testbench is self-checking and prints `PASS` lines to the console.

## Files

`src/` holds the 8 design files; `sim/` holds the 7 testbenches.
`Control_Unit_V2.vhd` is a two-process alternative kept for reference only — **do not add it to the build** (duplicate entity with `Control_Unit.vhd`).

## Roadmap

- [x] CPU core RTL + testbenches (all passing)
- [ ] FPGA board top level (`Nexys_A7_Top.vhd`)
- [x] Clock divider + debounced single-step button
- [x] Seven-segment display driver
- [ ] Constraints file (`.xdc`)
- [ ] On-board demonstration
