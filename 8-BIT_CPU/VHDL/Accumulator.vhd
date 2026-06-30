-- =============================================================================
--  File        : Accumulator.vhd
--  Entity      : Accumulator
--  Project     : 8-bit CPU  (Digital Technology, SS 2026)
--  Description : 8-bit register that stores the main working value of the CPU.
--                The ALU calculates a result, and when Load_Enable = '1',
--                this register stores that result on the rising clock edge.
--
--  Notes       : This is sequential logic.
--                Reset is asynchronous.
--                Normal loading is synchronous and controlled by Clock_Enable.
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;

entity Accumulator is
    port (
        Clock        : in  std_logic;
        Reset        : in  std_logic;
        Clock_Enable : in  std_logic;
        Load_Enable  : in  std_logic;

        Data_In      : in  std_logic_vector(7 downto 0);
        Data_Out     : out std_logic_vector(7 downto 0)
    );
end entity Accumulator;

architecture RTL of Accumulator is

    signal Register_Value : std_logic_vector(7 downto 0) := (others => '0');

begin

    -- -------------------------------------------------------------------------
    -- Register process
    --
    -- Reset is asynchronous because it is checked before the clock edge.
    -- Loading is synchronous because Data_In is stored only on rising_edge(Clock).
    -- Clock_Enable allows the CPU control unit to step the register only when
    -- the CPU is allowed to advance.
    -- -------------------------------------------------------------------------
    register_process : process(Clock, Reset)
    begin
        if Reset = '1' then
            Register_Value <= (others => '0');

        elsif rising_edge(Clock) then
            if Clock_Enable = '1' then
                if Load_Enable = '1' then
                    Register_Value <= Data_In;
                end if;
            end if;
        end if;
    end process register_process;

    -- Continuous output of the stored register value.
    Data_Out <= Register_Value;

end architecture RTL;
