-- ============================================================
-- File        : BCD_adder.vhd
-- Lab         : Lab 02 - Exercise 04
-- Description : 1-digit BCD adder using the 4-bit ripple carry
--               adder from Exercise 02.
--
-- BCD rule:
--   First add A + B + Cin.
--   If the binary sum is greater than 9 or a carry is produced,
--   add 6 (0110) to correct the result back into BCD format.
-- ============================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity BCD_adder is
    port (
        A    : in  std_logic_vector(3 downto 0);
        B    : in  std_logic_vector(3 downto 0);
        Cin  : in  std_logic;
        Sum  : out std_logic_vector(3 downto 0);
        Cout : out std_logic
    );
end entity BCD_adder;

architecture structural of BCD_adder is
    signal binary_sum      : std_logic_vector(3 downto 0);
    signal binary_carry    : std_logic;
    signal correction      : std_logic_vector(3 downto 0);
    signal corrected_sum   : std_logic_vector(3 downto 0);
    signal correction_cout : std_logic;
    signal needs_fix       : std_logic;
begin
    -- Step 1: normal 4-bit binary addition.
    ADD_FIRST : entity work.CR_adder
        generic map (
            WIDTH => 4
        )
        port map (
            A    => A,
            B    => B,
            Cin  => Cin,
            S    => binary_sum,
            Cout => binary_carry
        );

    -- Correction is needed for decimal values 10 to 19.
    needs_fix <= '1' when (binary_carry = '1' or unsigned(binary_sum) > 9) else '0';

    -- Add 6 only when the first result is not a valid BCD digit.
    correction <= "0110" when needs_fix = '1' else "0000";

    -- Step 2: add the BCD correction value.
    ADD_CORRECTION : entity work.CR_adder
        generic map (
            WIDTH => 4
        )
        port map (
            A    => binary_sum,
            B    => correction,
            Cin  => '0',
            S    => corrected_sum,
            Cout => correction_cout
        );

    Sum  <= corrected_sum;

    -- Cout is the decimal carry to the next BCD digit.
    Cout <= needs_fix;
end architecture structural;
