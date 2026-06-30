-- =============================================================================
--  File        : Accumulator_tb.vhd
--  Entity      : Accumulator_tb
--  Project     : 8-bit CPU  (Digital Technology, SS 2026)
--  Description : Unit testbench for the Accumulator.
--
--                The accumulator is the CPU's main working register. It behaves
--                just like the instruction register (load-on-enable storage),
--                so we check the same set of things:
--                  - asynchronous reset clears it to 00
--                  - it loads Data_In when Load_Enable is high
--                  - it holds when Load_Enable is low
--                  - Clock_Enable low freezes it
--
--  Notes       : Data_In in the real CPU comes from the ALU result. Here we
--                just drive fixed values so the behaviour is easy to read.
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;

entity Accumulator_tb is
end entity Accumulator_tb;

architecture bench of Accumulator_tb is

    constant CLK_PERIOD : time := 10 ns;

    signal Clock        : std_logic := '0';
    signal Reset        : std_logic := '1';
    signal Clock_Enable : std_logic := '0';
    signal Load_Enable  : std_logic := '0';
    signal Data_In      : std_logic_vector(7 downto 0) := (others => '0');
    signal Data_Out     : std_logic_vector(7 downto 0);

    signal sim_done : boolean := false;

    procedure check (signal   Got      : in std_logic_vector(7 downto 0);
                     constant Expected : in std_logic_vector(7 downto 0);
                     constant Tag      : in string) is
    begin
        assert Got = Expected report Tag & " : value mismatch" severity error;
        if Got = Expected then
            report Tag & " PASS" severity note;
        end if;
    end procedure;

begin

    uut : entity work.Accumulator
        port map (
            Clock        => Clock,
            Reset        => Reset,
            Clock_Enable => Clock_Enable,
            Load_Enable  => Load_Enable,
            Data_In      => Data_In,
            Data_Out     => Data_Out
        );

    clock_gen : process
    begin
        while not sim_done loop
            Clock <= '0'; wait for CLK_PERIOD / 2;
            Clock <= '1'; wait for CLK_PERIOD / 2;
        end loop;
        wait;
    end process clock_gen;

    stimulus : process
    begin
        -- Async reset clears it to 00.
        Reset <= '1'; Clock_Enable <= '0'; Load_Enable <= '0';
        wait for 12 ns;
        check(Data_Out, x"00", "reset");

        -- Load 0x42.
        Reset <= '0'; Clock_Enable <= '1'; Load_Enable <= '1'; Data_In <= x"42";
        wait until rising_edge(Clock); wait for 1 ns;
        check(Data_Out, x"42", "load_42");

        -- With Load_Enable low it must keep 0x42 even though Data_In changed.
        Load_Enable <= '0'; Data_In <= x"99";
        wait until rising_edge(Clock); wait for 1 ns;
        check(Data_Out, x"42", "hold_when_not_loading");

        -- Clock_Enable low freezes it, regardless of Load_Enable.
        Load_Enable <= '1'; Clock_Enable <= '0'; Data_In <= x"7E";
        wait until rising_edge(Clock); wait for 1 ns;
        check(Data_Out, x"42", "frozen_when_disabled");

        -- Re-enable and load the new value.
        Clock_Enable <= '1';
        wait until rising_edge(Clock); wait for 1 ns;
        check(Data_Out, x"7E", "load_7E");

        report "Accumulator_tb finished." severity note;
        sim_done <= true;
        wait;
    end process stimulus;

end architecture bench;
