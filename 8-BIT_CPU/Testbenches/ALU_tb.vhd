-- =============================================================================
--  File        : ALU_tb.vhd
--  Entity      : ALU_tb
--  Project     : 8-bit CPU  (Digital Technology, SS 2026)
--  Description : Unit testbench for the ALU.
--
--                The ALU is combinational, so there is no clock here. We simply
--                apply a set of inputs (Input_A, Input_B, Opcode), wait a moment
--                for the logic to settle, and compare the Result and the three
--                flags (Carry, Zero, Overflow) against hand-calculated values.
--
--                We test at least one case of every operation, plus the tricky
--                flag cases:
--                  - add that produces a carry and a zero result (FF + 01)
--                  - add that produces signed overflow (7F + 01)
--                  - subtract down to zero (sets the zero flag)
--
--  Notes       : Opcode names come from CPU_Package, so the test reads the same
--                way as the ALU and control unit.
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.CPU_Package.all;

entity ALU_tb is
end entity ALU_tb;

architecture bench of ALU_tb is

    signal Input_A       : std_logic_vector(7 downto 0) := (others => '0');
    signal Input_B       : std_logic_vector(7 downto 0) := (others => '0');
    signal Opcode        : std_logic_vector(3 downto 0) := (others => '0');
    signal Result        : std_logic_vector(7 downto 0);
    signal Carry_Flag    : std_logic;
    signal Zero_Flag     : std_logic;
    signal Overflow_Flag : std_logic;

    -- One procedure applies an operation and checks the result and all three
    -- flags at once. It keeps the long list of test cases below very compact.
    procedure do_check
        (signal   a, b      : out std_logic_vector(7 downto 0);
         signal   op        : out std_logic_vector(3 downto 0);
         signal   res       : in  std_logic_vector(7 downto 0);
         signal   c, z, v   : in  std_logic;
         constant in_a, in_b : in std_logic_vector(7 downto 0);
         constant in_op     : in std_logic_vector(3 downto 0);
         constant exp_res   : in std_logic_vector(7 downto 0);
         constant exp_c, exp_z, exp_v : in std_logic;
         constant Tag       : in string) is
    begin
        a  <= in_a;
        b  <= in_b;
        op <= in_op;
        wait for 10 ns;            -- give the combinational logic time to settle

        assert (res = exp_res) and (c = exp_c) and (z = exp_z) and (v = exp_v)
            report Tag & " FAIL : result=" & integer'image(to_integer(unsigned(res)))
                 & " carry=" & std_logic'image(c)
                 & " zero="  & std_logic'image(z)
                 & " ovf="   & std_logic'image(v)
            severity error;

        if (res = exp_res) and (c = exp_c) and (z = exp_z) and (v = exp_v) then
            report Tag & " PASS" severity note;
        end if;
    end procedure;

begin

    uut : entity work.ALU
        port map (
            Input_A       => Input_A,
            Input_B       => Input_B,
            Opcode        => Opcode,
            Result        => Result,
            Carry_Flag    => Carry_Flag,
            Zero_Flag     => Zero_Flag,
            Overflow_Flag => Overflow_Flag
        );

    stimulus : process
    begin
        -- LOAD passes Input_B straight through to the result.
        do_check(Input_A, Input_B, Opcode, Result, Carry_Flag, Zero_Flag, Overflow_Flag,
                 x"00", x"05", OP_LOAD_IMMEDIATE, x"05", '0','0','0', "load_immediate");

        -- Plain addition, no carry, no overflow.
        do_check(Input_A, Input_B, Opcode, Result, Carry_Flag, Zero_Flag, Overflow_Flag,
                 x"03", x"02", OP_ADD_MEMORY,     x"05", '0','0','0', "add_simple");

        -- FF + 01 wraps to 00: result is zero (zero flag) and there is a carry.
        do_check(Input_A, Input_B, Opcode, Result, Carry_Flag, Zero_Flag, Overflow_Flag,
                 x"FF", x"01", OP_ADD_MEMORY,     x"00", '1','1','0', "add_carry_and_zero");

        -- 7F + 01 = 80. Two positives gave a "negative" result, so signed overflow.
        do_check(Input_A, Input_B, Opcode, Result, Carry_Flag, Zero_Flag, Overflow_Flag,
                 x"7F", x"01", OP_ADD_MEMORY,     x"80", '0','0','1', "add_signed_overflow");

        -- Plain subtraction.
        do_check(Input_A, Input_B, Opcode, Result, Carry_Flag, Zero_Flag, Overflow_Flag,
                 x"05", x"03", OP_SUB_MEMORY,     x"02", '0','0','0', "sub_simple");

        -- Equal operands subtract to zero, so the zero flag is set.
        do_check(Input_A, Input_B, Opcode, Result, Carry_Flag, Zero_Flag, Overflow_Flag,
                 x"04", x"04", OP_SUB_MEMORY,     x"00", '0','1','0', "sub_to_zero");

        -- Bitwise operations.
        do_check(Input_A, Input_B, Opcode, Result, Carry_Flag, Zero_Flag, Overflow_Flag,
                 x"0F", x"3C", OP_AND_MEMORY,     x"0C", '0','0','0', "and");

        do_check(Input_A, Input_B, Opcode, Result, Carry_Flag, Zero_Flag, Overflow_Flag,
                 x"0F", x"30", OP_OR_MEMORY,      x"3F", '0','0','0', "or");

        do_check(Input_A, Input_B, Opcode, Result, Carry_Flag, Zero_Flag, Overflow_Flag,
                 x"FF", x"0F", OP_XOR_MEMORY,     x"F0", '0','0','0', "xor");

        do_check(Input_A, Input_B, Opcode, Result, Carry_Flag, Zero_Flag, Overflow_Flag,
                 x"0F", x"00", OP_NOT_ACC,        x"F0", '0','0','0', "not");

        -- CLEAR forces the result to 00, which also sets the zero flag.
        do_check(Input_A, Input_B, Opcode, Result, Carry_Flag, Zero_Flag, Overflow_Flag,
                 x"AB", x"00", OP_CLEAR,          x"00", '0','1','0', "clear");

        report "ALU_tb finished." severity note;
        wait;
    end process stimulus;

end architecture bench;
