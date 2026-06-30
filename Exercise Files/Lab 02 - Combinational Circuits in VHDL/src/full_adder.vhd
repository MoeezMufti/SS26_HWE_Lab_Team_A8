-- ============================================================
-- File        : full_adder.vhd
-- Lab         : Lab 02 - Exercise 01
-- Description : 1-bit full adder using two half adders as
--               components. This is structural modelling.
--
-- Idea:
--   First half adder  : A + B
--   Second half adder : partial sum + Cin
--   Final carry       : carry1 OR carry2
-- ============================================================

library ieee;
use ieee.std_logic_1164.all;

entity full_adder is
    port (
        A    : in  std_logic;
        B    : in  std_logic;
        Cin  : in  std_logic;
        S    : out std_logic;
        Cout : out std_logic
    );
end entity full_adder;

architecture structural of full_adder is
    signal partial_sum : std_logic;
    signal carry_1     : std_logic;
    signal carry_2     : std_logic;
begin
    -- First half adder adds the two main input bits.
    HA1 : entity work.half_adder
        port map (
            A     => A,
            B     => B,
            SUM   => partial_sum,
            CARRY => carry_1
        );

    -- Second half adder adds the carry-in to the partial sum.
    HA2 : entity work.half_adder
        port map (
            A     => partial_sum,
            B     => Cin,
            SUM   => S,
            CARRY => carry_2
        );

    -- A carry is generated if either half adder generated a carry.
    Cout <= carry_1 or carry_2;
end architecture structural;
