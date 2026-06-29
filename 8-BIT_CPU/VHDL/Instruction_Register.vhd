library ieee;
use ieee.std_logic_1164.all;

entity Instruction_Register is
    port (
        Clock           : in  std_logic;
        Reset           : in  std_logic;
        Clock_Enable    : in  std_logic;
        Load_Enable     : in  std_logic;
        Instruction_In  : in  std_logic_vector(7 downto 0);
        Instruction_Out : out std_logic_vector(7 downto 0)
    );
end entity;

architecture RTL of Instruction_Register is
    signal Instruction_Value : std_logic_vector(7 downto 0) := (others => '0');
begin

    process(Clock)
    begin
        if rising_edge(Clock) then
            if Reset = '1' then
                Instruction_Value <= (others => '0');
            elsif Clock_Enable = '1' then
                if Load_Enable = '1' then
                    Instruction_Value <= Instruction_In;
                end if;
            end if;
        end if;
    end process;

    Instruction_Out <= Instruction_Value;

end architecture;
