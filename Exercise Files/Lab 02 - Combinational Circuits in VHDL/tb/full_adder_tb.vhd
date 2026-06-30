-- ============================================================
-- File        : full_adder_tb.vhd
-- Lab         : Lab 02 - Exercise 01
-- Description : Testbench for the structural 1-bit full adder.
--               All 8 input combinations are tested, so the
--               truth table has 100% coverage.
-- ============================================================

library ieee;
use ieee.std_logic_1164.all;

entity full_adder_tb is
end entity full_adder_tb;

architecture bench of full_adder_tb is
    signal A    : std_logic := '0';
    signal B    : std_logic := '0';
    signal Cin  : std_logic := '0';
    signal S    : std_logic;
    signal Cout : std_logic;
begin
    uut : entity work.full_adder
        port map (
            A    => A,
            B    => B,
            Cin  => Cin,
            S    => S,
            Cout => Cout
        );

    stimulus : process
        procedure apply_and_check(
            constant a_in      : in std_logic;
            constant b_in      : in std_logic;
            constant cin_in    : in std_logic;
            constant exp_s     : in std_logic;
            constant exp_cout  : in std_logic
        ) is
        begin
            A   <= a_in;
            B   <= b_in;
            Cin <= cin_in;
            wait for 10 ns;

            assert (S = exp_s and Cout = exp_cout)
                report "Full adder failed for A=" & std_logic'image(a_in) &
                       ", B=" & std_logic'image(b_in) &
                       ", Cin=" & std_logic'image(cin_in)
                severity error;
        end procedure;
    begin
        -- Complete full adder truth table.
        apply_and_check('0', '0', '0', '0', '0');
        apply_and_check('0', '0', '1', '1', '0');
        apply_and_check('0', '1', '0', '1', '0');
        apply_and_check('0', '1', '1', '0', '1');
        apply_and_check('1', '0', '0', '1', '0');
        apply_and_check('1', '0', '1', '0', '1');
        apply_and_check('1', '1', '0', '0', '1');
        apply_and_check('1', '1', '1', '1', '1');

        report "full_adder_tb: all test cases passed." severity note;
        wait;
    end process stimulus;
end architecture bench;
