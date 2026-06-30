-- clk_divider_tb.vhd
-- Lab 07 - Exercise 01 testbench
--
-- This testbench checks the clock divider using N = 4.
-- With N = 4, CLK_N should complete one full period after 4 input clock cycles.
--
-- This is simulation-only code and also uses only STANDARD VHDL types.

entity clk_divider_tb is
end entity clk_divider_tb;

architecture bench of clk_divider_tb is

    constant CLK_PERIOD : time := 10 ns;

    signal CLK      : bit := '0';
    signal CLK_N    : bit;
    signal sim_done : bit := '0';

begin

    UUT : entity work.clk_divider
        generic map (
            N => 4
        )
        port map (
            CLK   => CLK,
            CLK_N => CLK_N
        );

    -- Simple input clock generator.
    clk_process : process
    begin
        while sim_done = '0' loop
            CLK <= '0';
            wait for CLK_PERIOD / 2;
            CLK <= '1';
            wait for CLK_PERIOD / 2;
        end loop;

        wait;
    end process;

    stimulus : process
    begin
        -- Initial output should be low.
        wait for 1 ns;
        assert CLK_N = '0'
            report "Initial CLK_N value is wrong."
            severity error;

        -- First rising edge of CLK: no output toggle yet.
        wait until CLK'event and CLK = '1';
        wait for 1 ns;
        assert CLK_N = '0'
            report "CLK_N toggled too early after first input clock edge."
            severity error;

        -- Second rising edge of CLK: output should toggle high.
        wait until CLK'event and CLK = '1';
        wait for 1 ns;
        assert CLK_N = '1'
            report "CLK_N did not toggle high at the expected time."
            severity error;

        -- Third rising edge of CLK: output should stay high.
        wait until CLK'event and CLK = '1';
        wait for 1 ns;
        assert CLK_N = '1'
            report "CLK_N changed unexpectedly after third input clock edge."
            severity error;

        -- Fourth rising edge of CLK: output should toggle low again.
        wait until CLK'event and CLK = '1';
        wait for 1 ns;
        assert CLK_N = '0'
            report "CLK_N did not toggle low at the expected time."
            severity error;

        report "clk_divider_tb passed successfully." severity note;

        sim_done <= '1';
        wait;
    end process;

end architecture bench;
