-- =============================================================================
--  File        : Instruction_Register_tb.vhd
--  Entity      : Instruction_Register_tb
--  Project     : 8-bit CPU  (Digital Technology, SS 2026)
--  Description : Unit testbench for the Instruction_Register.
--
--                The instruction register just has to hold one 8-bit value, but
--                it must only update at the right moments. So we check:
--                  - asynchronous reset clears it to 00
--                  - it captures Instruction_In when Load_Enable is high
--                  - it holds its value when Load_Enable is low (even if the
--                    input bus changes underneath it)
--                  - Clock_Enable low freezes it completely
--
--  Notes       : Holding the value when Load_Enable is low is the important
--                one - during decode/execute the ROM output keeps changing, and
--                the instruction we are running must not change with it.
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;

entity Instruction_Register_tb is
end entity Instruction_Register_tb;

architecture bench of Instruction_Register_tb is

    constant CLK_PERIOD : time := 10 ns;

    signal Clock           : std_logic := '0';
    signal Reset           : std_logic := '1';
    signal Clock_Enable    : std_logic := '0';
    signal Load_Enable     : std_logic := '0';
    signal Instruction_In  : std_logic_vector(7 downto 0) := (others => '0');
    signal Instruction_Out : std_logic_vector(7 downto 0);

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

    uut : entity work.Instruction_Register
        port map (
            Clock           => Clock,
            Reset           => Reset,
            Clock_Enable    => Clock_Enable,
            Load_Enable     => Load_Enable,
            Instruction_In  => Instruction_In,
            Instruction_Out => Instruction_Out
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
        -- Async reset should give us 00 with no clock needed.
        Reset <= '1'; Clock_Enable <= '0'; Load_Enable <= '0';
        wait for 12 ns;
        check(Instruction_Out, x"00", "reset");

        -- Load a value. With both enables high it should appear after one edge.
        Reset <= '0'; Clock_Enable <= '1'; Load_Enable <= '1'; Instruction_In <= x"AB";
        wait until rising_edge(Clock); wait for 1 ns;
        check(Instruction_Out, x"AB", "load_AB");

        -- Now drop Load_Enable and change the input. The register must ignore
        -- the new input and keep holding AB.
        Load_Enable <= '0'; Instruction_In <= x"CD";
        wait until rising_edge(Clock); wait for 1 ns;
        check(Instruction_Out, x"AB", "hold_when_not_loading");

        -- Even with Load_Enable high again, Clock_Enable low must block capture.
        Load_Enable <= '1'; Clock_Enable <= '0'; Instruction_In <= x"5A";
        wait until rising_edge(Clock); wait for 1 ns;
        check(Instruction_Out, x"AB", "frozen_when_disabled");

        -- Re-enable the clock and it should finally take the new value.
        Clock_Enable <= '1';
        wait until rising_edge(Clock); wait for 1 ns;
        check(Instruction_Out, x"5A", "load_5A");

        report "Instruction_Register_tb finished." severity note;
        sim_done <= true;
        wait;
    end process stimulus;

end architecture bench;
