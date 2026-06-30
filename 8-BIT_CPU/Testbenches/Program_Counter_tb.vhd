-- =============================================================================
--  File        : Program_Counter_tb.vhd
--  Entity      : Program_Counter_tb
--  Project     : 8-bit CPU  (Digital Technology, SS 2026)
--  Description : Self-checking unit testbench for the Program_Counter.
--                Checks: asynchronous reset, increment, synchronous load
--                (jump), load priority over increment, and the synchronous
--                enable (clk_en) freezing the counter.
--  Style       : Lecture testbench skeleton (entity with no ports, uut, a
--                clock process and a stimulus process).
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Program_Counter_tb is
end entity;

architecture bench of Program_Counter_tb is

    constant CLK_PERIOD : time := 10 ns;

    signal clk        : std_logic := '0';
    signal rst        : std_logic := '1';
    signal clk_en     : std_logic := '0';
    signal increment  : std_logic := '0';
    signal load_en    : std_logic := '0';
    signal load_value : std_logic_vector(3 downto 0) := (others => '0');
    signal count_out  : std_logic_vector(3 downto 0);

    signal sim_done : boolean := false;

    -- compares count_out against an expected integer and reports
    procedure check (signal got : in std_logic_vector(3 downto 0);
                     expected : in integer; tag : in string) is
    begin
        assert to_integer(unsigned(got)) = expected
            report tag & " : count = " & integer'image(to_integer(unsigned(got)))
                 & ", expected = " & integer'image(expected)
            severity error;
        if to_integer(unsigned(got)) = expected then
            report tag & " PASS (count = " & integer'image(expected) & ")"
                severity note;
        end if;
    end procedure;

begin

    uut : entity work.Program_Counter
        port map (
            clk        => clk,
            rst        => rst,
            clk_en     => clk_en,
            increment  => increment,
            load_en    => load_en,
            load_value => load_value,
            count_out  => count_out
        );

    clock_gen : process
    begin
        while not sim_done loop
            clk <= '0'; wait for CLK_PERIOD / 2;
            clk <= '1'; wait for CLK_PERIOD / 2;
        end loop;
        wait;
    end process;

    stimulus : process
    begin
        -- asynchronous reset
        rst <= '1'; clk_en <= '0'; increment <= '0'; load_en <= '0';
        wait for 12 ns;
        check(count_out, 0, "reset");

        -- count up three times
        rst <= '0'; clk_en <= '1'; increment <= '1';
        wait until rising_edge(clk); wait for 1 ns; check(count_out, 1, "inc1");
        wait until rising_edge(clk); wait for 1 ns; check(count_out, 2, "inc2");
        wait until rising_edge(clk); wait for 1 ns; check(count_out, 3, "inc3");

        -- enable low : counter must freeze even though increment is high
        clk_en <= '0';
        wait until rising_edge(clk); wait for 1 ns; check(count_out, 3, "freeze");

        -- synchronous load (jump) to value 10, load wins over increment
        clk_en <= '1'; load_en <= '1'; load_value <= x"A"; increment <= '1';
        wait until rising_edge(clk); wait for 1 ns; check(count_out, 10, "load");

        -- continue incrementing from the loaded value
        load_en <= '0';
        wait until rising_edge(clk); wait for 1 ns; check(count_out, 11, "inc_after_load");

        report "Program_Counter_tb done." severity note;
        sim_done <= true;
        wait;
    end process;

end architecture;
