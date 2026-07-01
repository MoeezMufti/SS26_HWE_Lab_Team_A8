# 8-BIT CPU (VHDL)

A small single-accumulator 8-bit CPU written in VHDL for the *Hardware Engineering* course (SS 2026).

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

# PCB Design

Used Altium Designer for the schematics and the final PCB product. The iCE40-UP5K package was used for simplicity purposes. For the development board, the components used can be found in the BOM, including an oscillator, a JTAG programming header, 2x power regulators for 3.3V and 1.2V, 4x 7-segment displays for bit display and a driver for synchronous use. For user interface: 2x buttons for reset and set and a 4-position DIP switch for switching various modes defined in the VHDL. The FPGA itself is powered through both the 3.3V and 1.2V, while the 3.3V is driven to the rest of the board through the 3V3-Plane layer. 

## Layers

There are only 4 layers in total for this design: 

1. Top Layer
2. GND Plane
3. 3V3 Plane
4. Bottom Layer

for the sake of simplicity. A seperate layer for the 7-segment driver was considered but in the end the idea to drop 4 displays was adopted, resulting in a smaller form-factor and easier tracing.


