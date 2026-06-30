library ieee;
use ieee.std_logic_1164.all;

-- Testbench for the 1-bit Full Adder
-- This testbench checks every possible input combination, so it gives 100% input coverage.
entity full_adder_bhv_tb is
end entity full_adder_bhv_tb;

architecture bench of full_adder_bhv_tb is
    -- Internal signals used to drive and observe the full adder.
    signal a        : std_logic := '0';
    signal b        : std_logic := '0';
    signal cin      : std_logic := '0';
    signal sum      : std_logic;
    signal carry    : std_logic;
    signal sim_done : boolean := false;
begin
    -- Unit Under Test (UUT): the full adder design file.
    uut : entity work.full_adder_bhv
        port map (
            a     => a,
            b     => b,
            cin   => cin,
            sum   => sum,
            carry => carry
        );

    stimulus : process
        -- This procedure applies one test case and checks the expected outputs.
        procedure check_case(
            constant a_in      : in std_logic;
            constant b_in      : in std_logic;
            constant cin_in    : in std_logic;
            constant exp_sum   : in std_logic;
            constant exp_carry : in std_logic
        ) is
        begin
            -- Apply the inputs to the UUT.
            a   <= a_in;
            b   <= b_in;
            cin <= cin_in;

            -- Full adder is combinational, so no clock is needed.
            -- We only wait for a short simulation time before checking.
            wait for 10 ns;

            assert sum = exp_sum
                report "Full adder SUM failed for A=" & std_logic'image(a_in) &
                       " B=" & std_logic'image(b_in) &
                       " Cin=" & std_logic'image(cin_in) &
                       ". Expected " & std_logic'image(exp_sum) &
                       ", got " & std_logic'image(sum)
                severity error;

            assert carry = exp_carry
                report "Full adder CARRY failed for A=" & std_logic'image(a_in) &
                       " B=" & std_logic'image(b_in) &
                       " Cin=" & std_logic'image(cin_in) &
                       ". Expected " & std_logic'image(exp_carry) &
                       ", got " & std_logic'image(carry)
                severity error;
        end procedure;
    begin
        -- 100% input coverage for a full adder means testing all 2^3 cases.
        -- Truth table:
        -- A B Cin | Sum Carry
        -- 0 0  0  |  0    0
        -- 0 0  1  |  1    0
        -- 0 1  0  |  1    0
        -- 0 1  1  |  0    1
        -- 1 0  0  |  1    0
        -- 1 0  1  |  0    1
        -- 1 1  0  |  0    1
        -- 1 1  1  |  1    1
        check_case('0', '0', '0', '0', '0');
        check_case('0', '0', '1', '1', '0');
        check_case('0', '1', '0', '1', '0');
        check_case('0', '1', '1', '0', '1');
        check_case('1', '0', '0', '1', '0');
        check_case('1', '0', '1', '0', '1');
        check_case('1', '1', '0', '0', '1');
        check_case('1', '1', '1', '1', '1');

        sim_done <= true;
        report "full_adder_bhv_tb completed successfully." severity note;
        wait;
    end process stimulus;
end architecture bench;
