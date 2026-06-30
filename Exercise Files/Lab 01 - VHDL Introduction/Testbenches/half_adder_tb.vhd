library ieee;
use ieee.std_logic_1164.all;

-- Testbench for the 1-bit Half Adder
-- A testbench has no input/output ports because it only runs in simulation.
entity half_adder_tb is
end entity half_adder_tb;

architecture bench of half_adder_tb is
    -- Internal test signals connected to the half adder.
    signal a        : std_logic := '0';
    signal b        : std_logic := '0';
    signal sum      : std_logic;
    signal carry    : std_logic;

    -- This signal is not needed for hardware. It is only useful in the waveform
    -- to clearly see when the simulation has completed.
    signal sim_done : boolean := false;
begin
    -- Unit Under Test (UUT): this is the actual half_adder design being tested.
    uut : entity work.half_adder
        port map (
            a     => a,
            b     => b,
            sum   => sum,
            carry => carry
        );

    stimulus : process
        -- Small helper procedure to avoid repeating the same assert code.
        -- It applies one input combination, waits for the output to update,
        -- and then checks whether the result is correct.
        procedure check_case(
            constant a_in      : in std_logic;
            constant b_in      : in std_logic;
            constant exp_sum   : in std_logic;
            constant exp_carry : in std_logic
        ) is
        begin
            -- Apply test inputs.
            a <= a_in;
            b <= b_in;

            -- Wait a short simulation time so the combinational outputs settle.
            wait for 10 ns;

            -- Check the sum output.
            assert sum = exp_sum
                report "Half adder SUM failed for A=" & std_logic'image(a_in) &
                       " B=" & std_logic'image(b_in) &
                       ". Expected " & std_logic'image(exp_sum) &
                       ", got " & std_logic'image(sum)
                severity error;

            -- Check the carry output.
            assert carry = exp_carry
                report "Half adder CARRY failed for A=" & std_logic'image(a_in) &
                       " B=" & std_logic'image(b_in) &
                       ". Expected " & std_logic'image(exp_carry) &
                       ", got " & std_logic'image(carry)
                severity error;
        end procedure;
    begin
        -- 100% input coverage for a half adder means testing all 2^2 cases.
        -- Truth table:
        -- A B | Sum Carry
        -- 0 0 |  0    0
        -- 0 1 |  1    0
        -- 1 0 |  1    0
        -- 1 1 |  0    1
        check_case('0', '0', '0', '0');
        check_case('0', '1', '1', '0');
        check_case('1', '0', '1', '0');
        check_case('1', '1', '0', '1');

        sim_done <= true;
        report "half_adder_tb completed successfully." severity note;
        wait;
    end process stimulus;
end architecture bench;
