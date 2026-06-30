-- =============================================================================
--  File        : Program_Counter_tb.vhd
--  Entity      : Program_Counter_tb
--  Project     : 8-bit CPU  (Digital Technology, SS 2026)
--  Description : Unit testbench for the Program_Counter.
--
--                The program counter is a small 4-bit counter, but it has a few
--                behaviours we really need to get right, so this testbench
--                checks them one by one:
--                  - asynchronous reset clears it to 0
--                  - it counts up when Increment is active
--                  - Clock_Enable low freezes it (needed for single-stepping)
--                  - Load_Enable jumps it to a new address
--                  - Load_Enable wins over Increment (a jump must override +1)
--
--  Notes       : Each check compares Count_Out against a value we expect and
--                prints PASS, or raises an error if it does not match.
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Program_Counter_tb is
end entity Program_Counter_tb;

architecture bench of Program_Counter_tb is

    constant CLK_PERIOD : time := 10 ns;

    signal Clock        : std_logic := '0';
    signal Reset        : std_logic := '1';
    signal Clock_Enable : std_logic := '0';
    signal Increment    : std_logic := '0';
    signal Load_Enable  : std_logic := '0';
    signal Load_Value   : std_logic_vector(3 downto 0) := (others => '0');
    signal Count_Out    : std_logic_vector(3 downto 0);

    signal sim_done : boolean := false;

    -- Small helper so every check reads the same way and prints a PASS line.
    procedure check (signal   Got      : in std_logic_vector(3 downto 0);
                     constant Expected : in integer;
                     constant Tag      : in string) is
    begin
        assert to_integer(unsigned(Got)) = Expected
            report Tag & " : count = " & integer'image(to_integer(unsigned(Got)))
                 & ", expected = " & integer'image(Expected)
            severity error;
        if to_integer(unsigned(Got)) = Expected then
            report Tag & " PASS (count = " & integer'image(Expected) & ")"
                severity note;
        end if;
    end procedure;

begin

    uut : entity work.Program_Counter
        port map (
            Clock        => Clock,
            Reset        => Reset,
            Clock_Enable => Clock_Enable,
            Increment    => Increment,
            Load_Enable  => Load_Enable,
            Load_Value   => Load_Value,
            Count_Out    => Count_Out
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
        -- Start in reset. The counter should be 0 straight away, without even
        -- needing a clock edge, because the reset is asynchronous.
        Reset <= '1'; Clock_Enable <= '0'; Increment <= '0'; Load_Enable <= '0';
        wait for 12 ns;
        check(Count_Out, 0, "reset");

        -- Now let it count: release reset, enable the clock, ask it to increment.
        -- After each clock edge it should be one higher.
        Reset <= '0'; Clock_Enable <= '1'; Increment <= '1';
        wait until rising_edge(Clock); wait for 1 ns; check(Count_Out, 1, "increment_1");
        wait until rising_edge(Clock); wait for 1 ns; check(Count_Out, 2, "increment_2");
        wait until rising_edge(Clock); wait for 1 ns; check(Count_Out, 3, "increment_3");

        -- Drop Clock_Enable. Even though Increment is still high, the counter
        -- must stay frozen. This is exactly what lets us single-step the CPU.
        Clock_Enable <= '0';
        wait until rising_edge(Clock); wait for 1 ns; check(Count_Out, 3, "frozen_when_disabled");

        -- Jump: load the value 10 (0xA). Increment is also high on purpose, to
        -- prove that Load_Enable takes priority and we really jump, not +1.
        Clock_Enable <= '1'; Load_Enable <= '1'; Load_Value <= x"A"; Increment <= '1';
        wait until rising_edge(Clock); wait for 1 ns; check(Count_Out, 10, "load_jump");

        -- After the jump, normal counting should continue from the loaded value.
        Load_Enable <= '0';
        wait until rising_edge(Clock); wait for 1 ns; check(Count_Out, 11, "increment_after_jump");

        report "Program_Counter_tb finished." severity note;
        sim_done <= true;
        wait;
    end process stimulus;

end architecture bench;
