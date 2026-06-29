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
end entity;

architecture RTL of Accumulator is
    signal Register_Value : std_logic_vector(7 downto 0) := (others => '0');
begin

    process(Clock)
    begin
        if rising_edge(Clock) then
            if Reset = '1' then
                Register_Value <= (others => '0');
            elsif Clock_Enable = '1' then
                if Load_Enable = '1' then
                    Register_Value <= Data_In;
                end if;
            end if;
        end if;
    end process;

    Data_Out <= Register_Value;

end architecture;
