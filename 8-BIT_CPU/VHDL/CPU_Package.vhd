-- =============================================================================
--  File        : CPU_Package.vhd
--  Package     : CPU_Package
--  Project     : 8-bit CPU  (Digital Technology, SS 2026)
--  Description : Shared design unit. Holds the opcode constants and the
--                control-unit state type so they can be referenced from every
--                entity of the CPU (instead of repeating magic numbers).
--  Style       : Package declaration only. A package body is not required here
--                because the package contains constants and a type, but no
--                subprogram implementations (lecture: Packages and Libraries).
--  Notes       : Constants use UPPER_CASE (lecture constant convention, e.g.
--                "constant BUS_WIDTH"). Type and enum literals use
--                lowercase_with_underscores.
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;

package CPU_Package is

    -- -------------------------------------------------------------------------
    -- Instruction format (8 bit):
    --   bits 7..4 : opcode   (one of the OP_* constants below)
    --   bits 3..0 : operand  (immediate value or memory address)
    -- The opcode is a 4-bit field, so 16 operations are possible.
    -- -------------------------------------------------------------------------
    constant OP_NOP            : std_logic_vector(3 downto 0) := "0000";
    constant OP_LOAD_IMMEDIATE : std_logic_vector(3 downto 0) := "0001";
    constant OP_LOAD_MEMORY    : std_logic_vector(3 downto 0) := "0010";
    constant OP_STORE_MEMORY   : std_logic_vector(3 downto 0) := "0011";
    constant OP_ADD_MEMORY     : std_logic_vector(3 downto 0) := "0100";
    constant OP_SUB_MEMORY     : std_logic_vector(3 downto 0) := "0101";
    constant OP_AND_MEMORY     : std_logic_vector(3 downto 0) := "0110";
    constant OP_OR_MEMORY      : std_logic_vector(3 downto 0) := "0111";
    constant OP_XOR_MEMORY     : std_logic_vector(3 downto 0) := "1000";
    constant OP_NOT_ACC        : std_logic_vector(3 downto 0) := "1001";
    constant OP_JUMP           : std_logic_vector(3 downto 0) := "1010";
    constant OP_JUMP_IF_ZERO   : std_logic_vector(3 downto 0) := "1011";
    constant OP_JUMP_IF_CARRY  : std_logic_vector(3 downto 0) := "1100";
    constant OP_OUT            : std_logic_vector(3 downto 0) := "1101";
    constant OP_CLEAR          : std_logic_vector(3 downto 0) := "1110";
    constant OP_HALT           : std_logic_vector(3 downto 0) := "1111";

    -- -------------------------------------------------------------------------
    -- Control-unit state type. Enumerated type, exactly as taught for
    -- Finite-State Machines (e.g. "type state is (S0, S1, S2);").
    --   st_fetch   : load instruction from ROM into IR, increment PC
    --   st_decode  : split instruction into opcode/operand (settle time)
    --   st_execute : perform the operation
    --   st_halt    : stop, stay here until reset
    -- -------------------------------------------------------------------------
    type cpu_state_type is (st_fetch, st_decode, st_execute, st_halt);

end package;
