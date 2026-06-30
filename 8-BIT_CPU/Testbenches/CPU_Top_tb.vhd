-- =============================================================================
--  File        : CPU_Top_tb.vhd
--  Entity      : CPU_Top_tb
--  Project     : 8-bit CPU  (Digital Technology, SS 2026)
--  Description : Testbench (simulation only, not synthesisable) for CPU_Top.
--                Runs each of the four demo programs in turn and checks that
--                the CPU halts with the expected value on debug_output.
--  Style       : Standard testbench skeleton from the lecture
--                ("Overview of simulation: test benches"): an entity with no
--                ports, the design under test instantiated as uut, a clock
--                process, and a stimulus process.
--  Notes       : clk_en is held '1' here so the CPU runs at full speed. On the
--                board it will instead be pulsed once per step (single-step).
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;          -- to_integer / unsigned for the checks

entity CPU_Top_tb is
end entity;

architecture bench of CPU_Top_tb is

    -- clock period constant (100 MHz-style 10 ns period, value is arbitrary
    -- for behavioural simulation)
    constant CLK_PERIOD : time := 10 ns;

    -- signals that drive / observe the design under test
    signal clk            : std_logic := '0';
    signal rst            : std_logic := '1';
    signal clk_en         : std_logic := '0';
    signal program_select : std_logic_vector(1 downto 0) := "00";

    signal debug_pc          : std_logic_vector(3 downto 0);
    signal debug_instruction : std_logic_vector(7 downto 0);
    signal debug_state       : std_logic_vector(3 downto 0);
    signal debug_acc         : std_logic_vector(7 downto 0);
    signal debug_output      : std_logic_vector(7 downto 0);
    signal debug_ram_data    : std_logic_vector(7 downto 0);

    signal zero_flag     : std_logic;
    signal carry_flag    : std_logic;
    signal overflow_flag : std_logic;
    signal halted        : std_logic;

    -- stops the clock once all programs have been checked
    signal sim_done : boolean := false;

begin

    -- -------------------------------------------------------------------------
    -- Device under test
    -- -------------------------------------------------------------------------
    uut : entity work.CPU_Top
        port map (
            clk               => clk,
            rst               => rst,
            clk_en            => clk_en,
            program_select    => program_select,
            debug_pc          => debug_pc,
            debug_instruction => debug_instruction,
            debug_state       => debug_state,
            debug_acc         => debug_acc,
            debug_output      => debug_output,
            debug_ram_data    => debug_ram_data,
            zero_flag         => zero_flag,
            carry_flag        => carry_flag,
            overflow_flag     => overflow_flag,
            halted            => halted
        );

    -- -------------------------------------------------------------------------
    -- Clock generator
    -- -------------------------------------------------------------------------
    clock_gen : process
    begin
        while not sim_done loop
            clk <= '0';
            wait for CLK_PERIOD / 2;
            clk <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
        wait;                                  -- stop forever once done
    end process;

    -- -------------------------------------------------------------------------
    -- Stimulus: run each program, wait for halt, check the result
    -- -------------------------------------------------------------------------
    stimulus : process

        -- runs one program: resets the CPU, selects the program, lets it run
        -- until it halts (or a timeout), then compares the output.
        procedure run_program
            (sel : in std_logic_vector(1 downto 0);
             expected : in integer) is
            variable got : integer;
        begin
            -- apply reset for two clocks with the program selected
            program_select <= sel;
            rst    <= '1';
            clk_en <= '0';
            wait until rising_edge(clk);
            wait until rising_edge(clk);

            -- release reset and let the CPU run
            rst    <= '0';
            clk_en <= '1';

            -- wait until the CPU halts, with a safety timeout
            for i in 0 to 500 loop
                wait until rising_edge(clk);
                exit when halted = '1';
            end loop;

            got := to_integer(unsigned(debug_output));

            assert halted = '1'
                report "Program " & integer'image(to_integer(unsigned(sel)))
                     & " did NOT halt (timeout)."
                severity error;

            assert got = expected
                report "Program " & integer'image(to_integer(unsigned(sel)))
                     & " : output = "  & integer'image(got)
                     & ", expected = " & integer'image(expected)
                severity error;

            if (halted = '1') and (got = expected) then
                report "Program " & integer'image(to_integer(unsigned(sel)))
                     & " PASS : output = " & integer'image(got)
                severity note;
            end if;
        end procedure;

    begin
        -- expected final outputs are documented in Memory_Unit.vhd
        run_program("00", 4);     -- arithmetic + memory + output
        run_program("01", 13);    -- arithmetic, hex result D
        run_program("10", 15);    -- logic operations, result F
        run_program("11", 7);     -- conditional jump on zero flag

        report "All four programs checked." severity note;

        sim_done <= true;         -- let the clock process stop
        wait;
    end process;

end architecture;
