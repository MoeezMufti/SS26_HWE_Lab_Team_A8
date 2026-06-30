library ieee;
use ieee.std_logic_1164.all;

-- Testbench for the 1-bit Full Subtractor
-- This testbench checks all possible a, b, and bin combinations.
entity full_subtractor_bhv_tb is
end entity full_subtractor_bhv_tb;

architecture bench of full_subtractor_bhv_tb is
    -- Internal signals connected to the full subtractor.
    signal a        : std_logic := '0';
    signal b        : std_logic := '0';
    signal bin      : std_logic := '0';
    signal diff     : std_logic;
    signal borrow   : std_logic;
    signal sim_done : boolean := false;
begin
    -- Unit Under Test (UUT): the full subtractor design.
    uut : entity work.full_subtractor_bhv
        port map (
            a      => a,
            b      => b,
            bin    => bin,
            diff   => diff,
            borrow => borrow
        );

    stimulus : process
        -- Applies one test case and checks diff and borrow.
        procedure check_case(
            constant a_in       : in std_logic;
            constant b_in       : in std_logic;
            constant bin_in     : in std_logic;
            constant exp_diff   : in std_logic;
            constant exp_borrow : in std_logic
        ) is
        begin
            -- Drive the inputs.
            a   <= a_in;
            b   <= b_in;
            bin <= bin_in;

            -- No clock is required because this is a combinational circuit.
            wait for 10 ns;

            assert diff = exp_diff
                report "Full subtractor DIFF failed for A=" & std_logic'image(a_in) &
                       " B=" & std_logic'image(b_in) &
                       " Bin=" & std_logic'image(bin_in) &
                       ". Expected " & std_logic'image(exp_diff) &
                       ", got " & std_logic'image(diff)
                severity error;

            assert borrow = exp_borrow
                report "Full subtractor BORROW failed for A=" & std_logic'image(a_in) &
                       " B=" & std_logic'image(b_in) &
                       " Bin=" & std_logic'image(bin_in) &
                       ". Expected " & std_logic'image(exp_borrow) &
                       ", got " & std_logic'image(borrow)
                severity error;
        end procedure;
    begin
        -- 100% input coverage for a full subtractor means testing all 2^3 cases.
        -- Truth table:
        -- A B Bin | Diff Borrow
        -- 0 0  0  |  0     0
        -- 0 0  1  |  1     1
        -- 0 1  0  |  1     1
        -- 0 1  1  |  0     1
        -- 1 0  0  |  1     0
        -- 1 0  1  |  0     0
        -- 1 1  0  |  0     0
        -- 1 1  1  |  1     1
        check_case('0', '0', '0', '0', '0');
        check_case('0', '0', '1', '1', '1');
        check_case('0', '1', '0', '1', '1');
        check_case('0', '1', '1', '0', '1');
        check_case('1', '0', '0', '1', '0');
        check_case('1', '0', '1', '0', '0');
        check_case('1', '1', '0', '0', '0');
        check_case('1', '1', '1', '1', '1');

        sim_done <= true;
        report "full_subtractor_bhv_tb completed successfully." severity note;
        wait;
    end process stimulus;
end architecture bench;
