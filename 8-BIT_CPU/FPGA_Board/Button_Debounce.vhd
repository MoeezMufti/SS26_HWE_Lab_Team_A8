library ieee;
use ieee.std_logic_1164.all;

entity Button_Debounce is
    generic (
        Debounce_Cycles : natural := 1000000
    );
    port (
        Clock     : in  std_logic;
        Reset     : in  std_logic;
        Button_In : in  std_logic;
        Pulse_Out : out std_logic
    );
end entity;

architecture RTL of Button_Debounce is
    signal Sync_0       : std_logic := '0';
    signal Sync_1       : std_logic := '0';
    signal Stable_Value : std_logic := '0';
    signal Counter      : natural range 0 to Debounce_Cycles := 0;
begin

    process(Clock)
    begin
        if rising_edge(Clock) then
            if Reset = '1' then
                Sync_0       <= '0';
                Sync_1       <= '0';
                Stable_Value <= '0';
                Counter      <= 0;
                Pulse_Out    <= '0';
            else
                Pulse_Out <= '0';

                Sync_0 <= Button_In;
                Sync_1 <= Sync_0;

                if Sync_1 = Stable_Value then
                    Counter <= 0;
                else
                    if Counter = Debounce_Cycles then
                        Stable_Value <= Sync_1;
                        Counter <= 0;

                        if Sync_1 = '1' then
                            Pulse_Out <= '1';
                        end if;
                    else
                        Counter <= Counter + 1;
                    end if;
                end if;
            end if;
        end if;
    end process;

end architecture;
