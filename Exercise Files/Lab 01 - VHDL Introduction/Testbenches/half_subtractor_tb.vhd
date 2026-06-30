library ieee;
use ieee.std_logic_1164.all;

-- Testbench for the 1-bit Half Subtractor
-- This tests all possible combinations of a and b.
entity half_subtractor_tb is
end entity half_subtractor_tb;

architecture bench of half_subtractor_tb is
    -- Internal signals for the testbench.
    signal a        : std_logic := '0';
    signal b        : std_logic := '0';
    signal diff     : std_logic;
    signal borrow   : std_logic;
    signal sim_done : boolean := false;
begin
    -- Unit Under Test (UUT): the half subtractor design.
    uut : entity work.half_subtractor
        port map (
            a      => a,
            b      => b,
            diff   => diff,
            borrow => borrow
        );

    stimulus : process
        -- Helper procedure to apply inputs and compare outputs with expected values.
        procedure check_case(
            constant a_in       : in std_logic;
            constant b_in       : in std_logic;
            constant exp_diff   : in std_logic;
            constant exp_borrow : in std_logic
        ) is
        begin
            a <= a_in;
            b <= b_in;
            wait for 10 ns;

            assert diff = exp_diff
                report "Half subtractor DIFF failed for A=" & std_logic'image(a_in) &
                       " B=" & std_logic'image(b_in) &
                       ". Expected " & std_logic'image(exp_diff) &
                       ", got " & std_logic'image(diff)
                severity error;

            assert borrow = exp_borrow
                report "Half subtractor BORROW failed for A=" & std_logic'image(a_in) &
                       " B=" & std_logic'image(b_in) &
                       ". Expected " & std_logic'image(exp_borrow) &
                       ", got " & std_logic'image(borrow)
                severity error;
        end procedure;
    begin
        -- 100% input coverage for a half subtractor means testing all 2^2 cases.
        -- Truth table:
        -- A B | Diff Borrow
        -- 0 0 |  0     0
        -- 0 1 |  1     1
        -- 1 0 |  1     0
        -- 1 1 |  0     0
        check_case('0', '0', '0', '0');
        check_case('0', '1', '1', '1');
        check_case('1', '0', '1', '0');
        check_case('1', '1', '0', '0');

        sim_done <= true;
        report "half_subtractor_tb completed successfully." severity note;
        wait;
    end process stimulus;
end architecture bench;
