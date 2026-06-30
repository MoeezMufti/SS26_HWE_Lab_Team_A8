-- =============================================================================
--  File        : Accumulator_tb.vhd
--  Entity      : Accumulator_tb
--  Project     : 8-bit CPU  (Digital Technology, SS 2026)
--  Description : Self-checking unit testbench for the Accumulator.
--                Checks: asynchronous reset, synchronous load on load_en,
--                hold when load_en = '0', and clk_en gating.
--  Style       : Lecture testbench skeleton.
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;

entity Accumulator_tb is
end entity;

architecture bench of Accumulator_tb is

    constant CLK_PERIOD : time := 10 ns;

    signal clk      : std_logic := '0';
    signal rst      : std_logic := '1';
    signal clk_en   : std_logic := '0';
    signal load_en  : std_logic := '0';
    signal data_in  : std_logic_vector(7 downto 0) := (others => '0');
    signal data_out : std_logic_vector(7 downto 0);

    signal sim_done : boolean := false;

    procedure check (signal got : in std_logic_vector(7 downto 0);
                     expected : in std_logic_vector(7 downto 0);
                     tag : in string) is
    begin
        assert got = expected report tag & " : mismatch" severity error;
        if got = expected then
            report tag & " PASS" severity note;
        end if;
    end procedure;

begin

    uut : entity work.Accumulator
        port map (
            clk      => clk,
            rst      => rst,
            clk_en   => clk_en,
            load_en  => load_en,
            data_in  => data_in,
            data_out => data_out
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
        rst <= '1'; clk_en <= '0'; load_en <= '0';
        wait for 12 ns;
        check(data_out, x"00", "reset");

        -- load 0x42
        rst <= '0'; clk_en <= '1'; load_en <= '1'; data_in <= x"42";
        wait until rising_edge(clk); wait for 1 ns;
        check(data_out, x"42", "load_42");

        -- hold when load_en low
        load_en <= '0'; data_in <= x"99";
        wait until rising_edge(clk); wait for 1 ns;
        check(data_out, x"42", "hold");

        -- freeze when clk_en low
        load_en <= '1'; clk_en <= '0'; data_in <= x"7E";
        wait until rising_edge(clk); wait for 1 ns;
        check(data_out, x"42", "freeze");

        -- re-enable, load new value
        clk_en <= '1';
        wait until rising_edge(clk); wait for 1 ns;
        check(data_out, x"7E", "load_7E");

        report "Accumulator_tb done." severity note;
        sim_done <= true;
        wait;
    end process;

end architecture;
