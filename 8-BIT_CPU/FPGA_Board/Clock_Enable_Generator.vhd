library ieee;
use ieee.std_logic_1164.all;

entity Clock_Enable_Generator is
    generic (
        Slow_Count : natural := 100000000;
        Fast_Count : natural := 20000000
    );
    port (
        Clock        : in  std_logic;
        Reset        : in  std_logic;
        Speed_Select : in  std_logic;
        Tick_Out     : out std_logic
    );
end entity;

architecture RTL of Clock_Enable_Generator is
    signal Counter : natural range 0 to Slow_Count := 0;
begin

    process(Clock)
        variable Selected_Limit : natural;
    begin
        if rising_edge(Clock) then
            if Speed_Select = '1' then
                Selected_Limit := Fast_Count;
            else
                Selected_Limit := Slow_Count;
            end if;

            if Reset = '1' then
                Counter <= 0;
                Tick_Out <= '0';
            else
                Tick_Out <= '0';

                if Counter >= Selected_Limit - 1 then
                    Counter <= 0;
                    Tick_Out <= '1';
                else
                    Counter <= Counter + 1;
                end if;
            end if;
        end if;
    end process;

end architecture;
