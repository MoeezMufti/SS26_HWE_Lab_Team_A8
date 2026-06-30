-- =============================================================================
--  File        : Instruction_Register_tb.vhd
--  Entity      : Instruction_Register_tb
--  Project     : 8-bit CPU  (Digital Technology, SS 2026)
--  Description : Self-checking unit testbench for the Instruction_Register.
--                Checks: asynchronous reset, synchronous load on load_en,
--                value hold when load_en = '0', and clk_en gating.
--  Style       : Lecture testbench skeleton.
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;

entity Instruction_Register_tb is
end entity;

architecture bench of Instruction_Register_tb is

    constant CLK_PERIOD : time := 10 ns;

    signal clk             : std_logic := '0';
    signal rst             : std_logic := '1';
    signal clk_en          : std_logic := '0';
    signal load_en         : std_logic := '0';
    signal instruction_in  : std_logic_vector(7 downto 0) := (others => '0');
    signal instruction_out : std_logic_vector(7 downto 0);

    signal sim_done : boolean := false;

    procedure check (signal got : in std_logic_vector(7 downto 0);
                     expected : in std_logic_vector(7 downto 0);
                     tag : in string) is
    begin
        assert got = expected
            report tag & " : mismatch" severity error;
        if got = expected then
            report tag & " PASS" severity note;
        end if;
    end procedure;

begin

    uut : entity work.Instruction_Register
        port map (
            clk             => clk,
            rst             => rst,
            clk_en          => clk_en,
            load_en         => load_en,
            instruction_in  => instruction_in,
            instruction_out => instruction_out
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
        check(instruction_out, x"00", "reset");

        -- load a value
        rst <= '0'; clk_en <= '1'; load_en <= '1'; instruction_in <= x"AB";
        wait until rising_edge(clk); wait for 1 ns;
        check(instruction_out, x"AB", "load_AB");

        -- with load_en low, a new input on the bus must NOT be captured
        load_en <= '0'; instruction_in <= x"CD";
        wait until rising_edge(clk); wait for 1 ns;
        check(instruction_out, x"AB", "hold");

        -- enable low : even with load_en high, no capture
        load_en <= '1'; clk_en <= '0'; instruction_in <= x"5A";
        wait until rising_edge(clk); wait for 1 ns;
        check(instruction_out, x"AB", "freeze");

        -- re-enable, capture new value
        clk_en <= '1';
        wait until rising_edge(clk); wait for 1 ns;
        check(instruction_out, x"5A", "load_5A");

        report "Instruction_Register_tb done." severity note;
        sim_done <= true;
        wait;
    end process;

end architecture;
