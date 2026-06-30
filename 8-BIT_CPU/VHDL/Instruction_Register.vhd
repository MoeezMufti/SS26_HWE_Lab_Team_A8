-- =============================================================================
--  File        : Instruction_Register.vhd
--  Entity      : Instruction_Register
--  Project     : 8-bit CPU  (Digital Technology, SS 2026)
--  Description : 8-bit register that stores the current instruction fetched
--                from program memory.
--
--  Notes       : This is sequential logic.
--                Reset is asynchronous.
--                Normal loading is synchronous and controlled by Clock_Enable
--                and Load_Enable.
--
--                The instruction format is:
--                instruction(7 downto 4) = opcode
--                instruction(3 downto 0) = operand/address
-- =============================================================================

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
end entity Instruction_Register;

architecture RTL of Instruction_Register is

    signal Instruction_Value : std_logic_vector(7 downto 0) := (others => '0');

begin

    -- -------------------------------------------------------------------------
    -- Register process
    --
    -- Reset is asynchronous because it is checked before the clock edge.
    -- The instruction is stored only on rising_edge(Clock), when both
    -- Clock_Enable and Load_Enable are active.
    -- -------------------------------------------------------------------------
    register_process : process(Clock, Reset)
    begin
        if Reset = '1' then
            Instruction_Value <= (others => '0');

        elsif rising_edge(Clock) then
            if Clock_Enable = '1' then
                if Load_Enable = '1' then
                    Instruction_Value <= Instruction_In;
                end if;
            end if;
        end if;
    end process register_process;

    -- Continuous output of the stored instruction.
    Instruction_Out <= Instruction_Value;

end architecture RTL;
