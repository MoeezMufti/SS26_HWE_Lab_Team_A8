-- =============================================================================
--  File        : Button_Debounce.vhd
--  Entity      : Button_Debounce
--  Project     : 8-bit CPU  (Digital Technology, SS 2026)
--  Description : Debounces a mechanical push button and generates one clean
--                clock-cycle pulse for each stable button press.
--
--  Notes       : This is board-support logic, not part of the CPU core.
--                It is used for manual CPU stepping with BTN_C.
--
--                Reset is asynchronous.
--                Button sampling and pulse generation are synchronous.
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;

entity Button_Debounce is
    port (
        Clock     : in  std_logic;
        Reset     : in  std_logic;
        Button_In : in  std_logic;
        Pulse_Out : out std_logic
    );
end entity Button_Debounce;

architecture RTL of Button_Debounce is

    -- Nexys A7 clock is normally 100 MHz.
    -- 2,000,000 cycles = about 20 ms.
    -- This is long enough to ignore normal mechanical button bounce.
    constant DEBOUNCE_LIMIT : natural := 2000000;

    -- Synchronizer registers for the external button input.
    signal Button_Sync_0 : std_logic := '0';
    signal Button_Sync_1 : std_logic := '0';

    -- Debounce state.
    signal Stable_Button      : std_logic := '0';
    signal Previous_Button    : std_logic := '0';
    signal Last_Sampled_Value : std_logic := '0';

    -- Counter used to check how long the button input has stayed unchanged.
    signal Debounce_Counter : natural range 0 to DEBOUNCE_LIMIT := 0;

begin

    -- -------------------------------------------------------------------------
    -- Debounce process
    --
    -- Reset is asynchronous because it is checked before the clock edge.
    -- The button is sampled on rising_edge(Clock).
    --
    -- The circuit only accepts a new button value if the synchronized input
    -- remains unchanged for DEBOUNCE_LIMIT clock cycles.
    -- -------------------------------------------------------------------------
    debounce_process : process(Clock, Reset)
    begin
        if Reset = '1' then
            Button_Sync_0      <= '0';
            Button_Sync_1      <= '0';
            Stable_Button      <= '0';
            Previous_Button    <= '0';
            Last_Sampled_Value <= '0';
            Debounce_Counter   <= 0;
            Pulse_Out          <= '0';

        elsif rising_edge(Clock) then

            -- Default: no pulse.
            -- Pulse_Out becomes '1' for only one clock cycle when a clean
            -- rising button press is detected.
            Pulse_Out <= '0';

            -- Synchronize the external button input to the FPGA clock.
            Button_Sync_0 <= Button_In;
            Button_Sync_1 <= Button_Sync_0;

            -- Check whether the button value is still changing.
            if Button_Sync_1 /= Last_Sampled_Value then
                Last_Sampled_Value <= Button_Sync_1;
                Debounce_Counter   <= 0;

            else
                -- Button value has stayed the same.
                -- Count how long it has remained stable.
                if Debounce_Counter < DEBOUNCE_LIMIT then
                    Debounce_Counter <= Debounce_Counter + 1;

                else
                    -- The input has been stable long enough, so accept it.
                    Stable_Button <= Last_Sampled_Value;
                end if;
            end if;

            -- Store previous stable value for edge detection.
            Previous_Button <= Stable_Button;

            -- Generate one pulse only when the stable button value changes
            -- from 0 to 1.
            if Stable_Button = '1' and Previous_Button = '0' then
                Pulse_Out <= '1';
            end if;

        end if;
    end process debounce_process;

end architecture RTL;
