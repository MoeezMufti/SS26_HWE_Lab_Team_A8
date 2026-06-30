-- =============================================================================
--  File        : ALU_tb.vhd
--  Entity      : ALU_tb
--  Project     : 8-bit CPU  (Digital Technology, SS 2026)
--  Description : Self-checking unit testbench for the (combinational) ALU.
--                Exercises every operation and the carry / zero / overflow
--                flags. No clock is needed because the ALU is combinational;
--                the stimulus applies inputs, waits for the logic to settle,
--                and checks the result and flags.
--  Style       : Lecture testbench skeleton (combinational variant).
--  Notes       : Opcode constants are taken from CPU_Package.
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.CPU_Package.all;

entity ALU_tb is
end entity;

architecture bench of ALU_tb is

    signal input_a       : std_logic_vector(7 downto 0) := (others => '0');
    signal input_b       : std_logic_vector(7 downto 0) := (others => '0');
    signal opcode        : std_logic_vector(3 downto 0) := (others => '0');
    signal result        : std_logic_vector(7 downto 0);
    signal carry_flag    : std_logic;
    signal zero_flag     : std_logic;
    signal overflow_flag : std_logic;

    -- applies one operation and checks result + the three flags
    procedure do_check
        (signal a, b   : out std_logic_vector(7 downto 0);
         signal op     : out std_logic_vector(3 downto 0);
         signal res    : in  std_logic_vector(7 downto 0);
         signal c, z, v : in std_logic;
         in_a, in_b : in std_logic_vector(7 downto 0);
         in_op      : in std_logic_vector(3 downto 0);
         exp_res    : in std_logic_vector(7 downto 0);
         exp_c, exp_z, exp_v : in std_logic;
         tag : in string) is
    begin
        a  <= in_a;
        b  <= in_b;
        op <= in_op;
        wait for 10 ns;                        -- let combinational logic settle
        assert (res = exp_res) and (c = exp_c) and (z = exp_z) and (v = exp_v)
            report tag & " FAIL : got res=" & integer'image(to_integer(unsigned(res)))
                 & " c=" & std_logic'image(c)
                 & " z=" & std_logic'image(z)
                 & " v=" & std_logic'image(v)
            severity error;
        if (res = exp_res) and (c = exp_c) and (z = exp_z) and (v = exp_v) then
            report tag & " PASS" severity note;
        end if;
    end procedure;

begin

    uut : entity work.ALU
        port map (
            input_a       => input_a,
            input_b       => input_b,
            opcode        => opcode,
            result        => result,
            carry_flag    => carry_flag,
            zero_flag     => zero_flag,
            overflow_flag => overflow_flag
        );

    stimulus : process
    begin
        --        a        b       opcode             res   c   z   v   tag
        do_check(input_a, input_b, opcode, result, carry_flag, zero_flag, overflow_flag,
                 x"00", x"05", OP_LOAD_IMMEDIATE, x"05", '0','0','0', "load_imm");

        do_check(input_a, input_b, opcode, result, carry_flag, zero_flag, overflow_flag,
                 x"03", x"02", OP_ADD_MEMORY,     x"05", '0','0','0', "add");

        do_check(input_a, input_b, opcode, result, carry_flag, zero_flag, overflow_flag,
                 x"FF", x"01", OP_ADD_MEMORY,     x"00", '1','1','0', "add_carry_zero");

        do_check(input_a, input_b, opcode, result, carry_flag, zero_flag, overflow_flag,
                 x"7F", x"01", OP_ADD_MEMORY,     x"80", '0','0','1', "add_overflow");

        do_check(input_a, input_b, opcode, result, carry_flag, zero_flag, overflow_flag,
                 x"05", x"03", OP_SUB_MEMORY,     x"02", '0','0','0', "sub");

        do_check(input_a, input_b, opcode, result, carry_flag, zero_flag, overflow_flag,
                 x"04", x"04", OP_SUB_MEMORY,     x"00", '0','1','0', "sub_zero");

        do_check(input_a, input_b, opcode, result, carry_flag, zero_flag, overflow_flag,
                 x"0F", x"3C", OP_AND_MEMORY,     x"0C", '0','0','0', "and");

        do_check(input_a, input_b, opcode, result, carry_flag, zero_flag, overflow_flag,
                 x"0F", x"30", OP_OR_MEMORY,      x"3F", '0','0','0', "or");

        do_check(input_a, input_b, opcode, result, carry_flag, zero_flag, overflow_flag,
                 x"FF", x"0F", OP_XOR_MEMORY,     x"F0", '0','0','0', "xor");

        do_check(input_a, input_b, opcode, result, carry_flag, zero_flag, overflow_flag,
                 x"0F", x"00", OP_NOT_ACC,        x"F0", '0','0','0', "not");

        do_check(input_a, input_b, opcode, result, carry_flag, zero_flag, overflow_flag,
                 x"AB", x"00", OP_CLEAR,          x"00", '0','1','0', "clear");

        report "ALU_tb done." severity note;
        wait;
    end process;

end architecture;
