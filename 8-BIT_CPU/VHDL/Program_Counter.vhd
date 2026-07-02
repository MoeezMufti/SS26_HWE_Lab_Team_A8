--  Description : 4-bit register/counter that stores the address of the current
--                instruction. It can either increment to the next instruction
--                or load a new address during a jump instruction.

--  Notes       : This is sequential logic.
--                Reset is asynchronous.
--                Normal counting/loading is synchronous and controlled by
--                Clock_Enable.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Program_Counter is
    port (
        Clock        : in  std_logic;
        Reset        : in  std_logic;
        Clock_Enable : in  std_logic;

        Increment    : in  std_logic;
        Load_Enable  : in  std_logic;
        Load_Value   : in  std_logic_vector(3 downto 0);

        Count_Out    : out std_logic_vector(3 downto 0)
    );
end entity Program_Counter;

architecture RTL of Program_Counter is

    -- Internal counter value.
    -- unsigned is used because the counter performs arithmetic: Count_Value + 1.
    signal Count_Value : unsigned(3 downto 0) := (others => '0');

begin

-- Reset is asynchronous because it is checked before the clock edge.
-- Incrementing and loading happen only on rising_edge(Clock).
-- Load_Enable has priority over Increment.
    
    counter_process : process(Clock, Reset)
    begin
        if Reset = '1' then
            Count_Value <= (others => '0');

        elsif rising_edge(Clock) then
            if Clock_Enable = '1' then

                if Load_Enable = '1' then
                    Count_Value <= unsigned(Load_Value);

                elsif Increment = '1' then
                    Count_Value <= Count_Value + 1;

                end if;

            end if;
        end if;
    end process counter_process;

    -- Convert the internal unsigned counter value back to std_logic_vector
    -- so it can connect to the rest of the CPU.
    Count_Out <= std_logic_vector(Count_Value);

end architecture RTL;
