-- =============================================================================
--  File        : Clock_Enable_Generator.vhd
--  Entity      : Clock_Enable_Generator
--  Project     : 8-bit CPU  (Digital Technology, SS 2026)
--  Description : Generates a slow one-clock-cycle enable pulse for automatic
--                CPU stepping on the FPGA board.
--
--  Notes       : This module does not create a new clock.
--                It uses the main FPGA clock and generates Tick_Out as a
--                clock-enable pulse.
--
--                Reset is asynchronous.
--                Counter and pulse generation are synchronous.
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Clock_Enable_Generator is
    port (
        Clock        : in  std_logic;
        Reset        : in  std_logic;
        Speed_Select : in  std_logic;
        Tick_Out     : out std_logic
    );
end entity Clock_Enable_Generator;

architecture RTL of Clock_Enable_Generator is

    -- Nexys A7 board clock is normally 100 MHz.
    --
    -- 100,000,000 clock cycles = about 1 second
    -- 25,000,000  clock cycles = about 0.25 seconds
    --
    -- Speed_Select = 0 -> slow mode
    -- Speed_Select = 1 -> fast mode
    constant SLOW_LIMIT : unsigned(26 downto 0) := to_unsigned(100000000 - 1, 27);
    constant FAST_LIMIT : unsigned(26 downto 0) := to_unsigned(25000000  - 1, 27);

    signal Counter_Value : unsigned(26 downto 0) := (others => '0');
    signal Current_Limit : unsigned(26 downto 0);

begin

    -- -------------------------------------------------------------------------
    -- Speed selection
    --
    -- This is combinational logic.
    -- It selects which counter limit will be used.
    -- -------------------------------------------------------------------------
    Current_Limit <= FAST_LIMIT when Speed_Select = '1' else SLOW_LIMIT;


    -- -------------------------------------------------------------------------
    -- Tick generation process
    --
    -- Tick_Out is normally 0.
    -- When the counter reaches the selected limit, Tick_Out becomes 1 for
    -- exactly one clock cycle, and the counter restarts from 0.
    -- -------------------------------------------------------------------------
    tick_process : process(Clock, Reset)
    begin
        if Reset = '1' then
            Counter_Value <= (others => '0');
            Tick_Out      <= '0';

        elsif rising_edge(Clock) then

            -- Default value: no tick.
            Tick_Out <= '0';

            if Counter_Value = Current_Limit then
                Counter_Value <= (others => '0');
                Tick_Out      <= '1';
            else
                Counter_Value <= Counter_Value + 1;
            end if;

        end if;
    end process tick_process;

end architecture RTL;
