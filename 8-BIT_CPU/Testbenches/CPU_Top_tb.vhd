-- =============================================================================
--  File        : CPU_Top_tb.vhd
--  Entity      : CPU_Top_tb
--  Project     : 8-bit CPU  (Digital Technology, SS 2026)
--  Description : Testbench for the whole CPU core. It runs each of the four
--                demo programs that live in the Memory_Unit and checks that the
--                CPU stops with the value we expect on Debug_Output.
--
--                This is the "does the whole thing actually work" test. The
--                unit testbenches check each block on its own; this one checks
--                that they cooperate correctly once wired together in CPU_Top.
--
--  Notes       : A testbench has no ports of its own. It generates the clock,
--                drives reset and the program selector, and watches the debug
--                outputs. Clock_Enable is held high here so the CPU runs at
--                full speed - on the board it will be pulsed once per step.
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;        -- needed for to_integer / unsigned in the checks

entity CPU_Top_tb is
end entity CPU_Top_tb;

architecture bench of CPU_Top_tb is

    -- Clock period. The exact number does not matter for a behavioural
    -- simulation, it only sets the time axis of the waveform.
    constant CLK_PERIOD : time := 10 ns;

    -- Signals that connect to the CPU under test.
    signal Clock          : std_logic := '0';
    signal Reset          : std_logic := '1';
    signal Clock_Enable   : std_logic := '0';
    signal Program_Select : std_logic_vector(1 downto 0) := "00";

    signal Debug_PC          : std_logic_vector(3 downto 0);
    signal Debug_Instruction : std_logic_vector(7 downto 0);
    signal Debug_State       : std_logic_vector(3 downto 0);
    signal Debug_ACC         : std_logic_vector(7 downto 0);
    signal Debug_Output      : std_logic_vector(7 downto 0);
    signal Debug_RAM_Data    : std_logic_vector(7 downto 0);

    signal Zero_Flag     : std_logic;
    signal Carry_Flag    : std_logic;
    signal Overflow_Flag : std_logic;
    signal Halted        : std_logic;

    -- When this goes true the clock process stops, which ends the simulation.
    signal sim_done : boolean := false;

begin

    -- The Device Under Test: the complete CPU core.
    uut : entity work.CPU_Top
        port map (
            Clock             => Clock,
            Reset             => Reset,
            Clock_Enable      => Clock_Enable,
            Program_Select    => Program_Select,
            Debug_PC          => Debug_PC,
            Debug_Instruction => Debug_Instruction,
            Debug_State       => Debug_State,
            Debug_ACC         => Debug_ACC,
            Debug_Output      => Debug_Output,
            Debug_RAM_Data    => Debug_RAM_Data,
            Zero_Flag         => Zero_Flag,
            Carry_Flag        => Carry_Flag,
            Overflow_Flag     => Overflow_Flag,
            Halted            => Halted
        );

    -- Free-running clock. It keeps toggling until the stimulus says we are done.
    clock_gen : process
    begin
        while not sim_done loop
            Clock <= '0';
            wait for CLK_PERIOD / 2;
            Clock <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
        wait;                       -- stop toggling forever once the test ends
    end process clock_gen;

    -- Main stimulus: run all four programs one after another.
    stimulus : process

        -- Helper that runs a single program from a clean reset and then checks
        -- the output once the CPU halts. Putting this in a procedure keeps the
        -- four program runs short and readable.
        procedure run_program
            (Selection : in std_logic_vector(1 downto 0);
             Expected  : in integer) is
            variable Got : integer;
        begin
            -- Hold the CPU in reset for two clocks with the program selected.
            -- Two clocks is just to be safe - one is enough for an async reset.
            Program_Select <= Selection;
            Reset          <= '1';
            Clock_Enable   <= '0';
            wait until rising_edge(Clock);
            wait until rising_edge(Clock);

            -- Release reset and let the CPU run on its own.
            Reset        <= '0';
            Clock_Enable <= '1';

            -- Wait until the CPU reaches its halt state. The for-loop is a
            -- safety timeout so a broken design can never hang the simulation.
            for i in 0 to 500 loop
                wait until rising_edge(Clock);
                exit when Halted = '1';
            end loop;

            Got := to_integer(unsigned(Debug_Output));

            -- Check 1: the program must actually stop (Halted high).
            assert Halted = '1'
                report "Program " & integer'image(to_integer(unsigned(Selection)))
                     & " never halted (timed out)."
                severity error;

            -- Check 2: the output value must match what we worked out by hand.
            assert Got = Expected
                report "Program " & integer'image(to_integer(unsigned(Selection)))
                     & " : got "      & integer'image(Got)
                     & ", expected "  & integer'image(Expected)
                severity error;

            -- If both checks held, print a clear PASS line for the report.
            if (Halted = '1') and (Got = Expected) then
                report "Program " & integer'image(to_integer(unsigned(Selection)))
                     & " PASS : output = " & integer'image(Got)
                    severity note;
            end if;
        end procedure run_program;

    begin
        -- Expected outputs are documented in Memory_Unit.vhd next to each program.
        run_program("00", 4);      -- arithmetic + store + output, ends at 04
        run_program("01", 16);     -- 8-bit datapath demo: 0F + 01 = 10 hex = 16
        run_program("10", 15);     -- logic operations, ends at 0F = 15
        run_program("11", 7);      -- conditional jump on the zero flag, ends at 07

        report "All four programs checked." severity note;

        sim_done <= true;          -- let the clock stop and end the run
        wait;
    end process stimulus;

end architecture bench;
