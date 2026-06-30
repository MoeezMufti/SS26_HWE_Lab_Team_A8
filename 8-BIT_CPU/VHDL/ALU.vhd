-- =============================================================================
--  File        : ALU.vhd
--  Entity      : ALU
--  Project     : 8-bit CPU  (Digital Technology, SS 2026)
--  Description : Arithmetic and Logic Unit. Combinational block. Takes the
--                accumulator (input_a), a second operand (input_b) and the
--                opcode, and produces the 8-bit result plus the status flags
--                (carry, zero, overflow).
--  Style       : Behavioural, single combinational process driven by a
--                case statement on the opcode (lecture: "CASE-Statement ...
--                usually a multiplexer function"). Variables are used for the
--                intermediate result, as in the parity_calculator example.
--  Notes       : Temp is 9 bits wide so the 9th bit captures the carry out of
--                an 8-bit add/subtract. Opcodes come from CPU_Package.
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;          -- unsigned arithmetic for add/sub

use work.CPU_Package.all;          -- OP_* opcode constants

entity ALU is
    port (
        input_a       : in  std_logic_vector(7 downto 0);
        input_b       : in  std_logic_vector(7 downto 0);
        opcode        : in  std_logic_vector(3 downto 0);

        result        : out std_logic_vector(7 downto 0);
        carry_flag    : out std_logic;
        zero_flag     : out std_logic;
        overflow_flag : out std_logic
    );
end entity;

architecture behavioral of ALU is
begin

    -- pure combinational logic: every input is in the sensitivity list
    alu_logic : process(input_a, input_b, opcode)
        variable temp     : unsigned(8 downto 0);   -- 9 bits -> keeps carry out
        variable r        : std_logic_vector(7 downto 0);
        variable carry    : std_logic;
        variable overflow : std_logic;
    begin
        -- default values (avoid latches: every path assigns these)
        r        := input_a;
        carry    := '0';
        overflow := '0';

        case opcode is

            -- ---- load operations: result is just the second operand ----
            when OP_LOAD_IMMEDIATE =>
                r := input_b;

            when OP_LOAD_MEMORY =>
                r := input_b;

            -- ---- addition (input_a + input_b) ----
            when OP_ADD_MEMORY =>
                temp  := ('0' & unsigned(input_a)) + ('0' & unsigned(input_b));
                r     := std_logic_vector(temp(7 downto 0));
                carry := temp(8);
                -- signed overflow: operands same sign, result different sign
                if (input_a(7) = input_b(7)) and (r(7) /= input_a(7)) then
                    overflow := '1';
                end if;

            -- ---- subtraction (input_a - input_b) ----
            when OP_SUB_MEMORY =>
                temp  := ('0' & unsigned(input_a)) - ('0' & unsigned(input_b));
                r     := std_logic_vector(temp(7 downto 0));
                carry := temp(8);                    -- borrow indicator
                -- signed overflow: operands different sign, result sign wrong
                if (input_a(7) /= input_b(7)) and (r(7) /= input_a(7)) then
                    overflow := '1';
                end if;

            -- ---- bitwise logic ----
            when OP_AND_MEMORY =>
                r := input_a and input_b;

            when OP_OR_MEMORY =>
                r := input_a or input_b;

            when OP_XOR_MEMORY =>
                r := input_a xor input_b;

            when OP_NOT_ACC =>
                r := not input_a;

            when OP_CLEAR =>
                r := (others => '0');

            -- ---- everything else (NOP, OUT, STORE, JUMP, HALT): pass ACC ----
            when others =>
                r := input_a;

        end case;

        -- drive the outputs from the local variables
        result        <= r;
        carry_flag    <= carry;
        overflow_flag <= overflow;

        -- zero flag is set when the result is all zeros
        if r = "00000000" then
            zero_flag <= '1';
        else
            zero_flag <= '0';
        end if;

    end process;

end architecture;
