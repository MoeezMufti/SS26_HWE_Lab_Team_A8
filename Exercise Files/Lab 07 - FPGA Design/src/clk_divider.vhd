-- clk_divider.vhd
-- Lab 07 - Exercise 01
--
-- This module divides an input clock CLK by the generic factor N.
-- Example:
--   If CLK = 100 MHz and N = 100_000_000, then CLK_N = 1 Hz.
--
-- Important:
--   The lab asks for STANDARD VHDL only, so this file uses bit/integer types
--   and does not use std_logic or IEEE packages.
--
--   For a clean 50% duty cycle, use an even value of N.

entity clk_divider is
    generic (
        N : positive := 100000000       -- Clock division factor
    );
    port (
        CLK   : in  bit;                -- Main input clock
        CLK_N : out bit                 -- Divided output clock
    );
end entity clk_divider;

architecture behavioral of clk_divider is

    -- Half of N is used because the output clock must toggle twice per period.
    -- Example for N = 100:
    --   toggle after 50 input clocks -> full output period after 100 clocks.
    constant HALF_PERIOD : positive := N / 2;

    signal counter : integer range 0 to HALF_PERIOD - 1 := 0;
    signal clk_reg : bit := '0';

begin

    -- This assertion is mainly a safety note for simulation.
    -- A clock with exactly 50% duty cycle needs an even division factor.
    assert (N >= 2 and (N mod 2 = 0))
        report "clk_divider: N should be an even value greater than or equal to 2."
        severity warning;

    process (CLK)
    begin
        if CLK'event and CLK = '1' then
            if counter = HALF_PERIOD - 1 then
                counter <= 0;
                clk_reg <= not clk_reg;
            else
                counter <= counter + 1;
            end if;
        end if;
    end process;

    CLK_N <= clk_reg;

end architecture behavioral;
