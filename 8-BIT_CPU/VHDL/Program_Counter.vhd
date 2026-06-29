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
end entity;

architecture RTL of Program_Counter is
    signal Count_Value : unsigned(3 downto 0) := (others => '0');
begin

    process(Clock)
    begin
        if rising_edge(Clock) then
            if Reset = '1' then
                Count_Value <= (others => '0');
            elsif Clock_Enable = '1' then
                if Load_Enable = '1' then
                    Count_Value <= unsigned(Load_Value);
                elsif Increment = '1' then
                    Count_Value <= Count_Value + 1;
                end if;
            end if;
        end if;
    end process;

    Count_Out <= std_logic_vector(Count_Value);

end architecture;
