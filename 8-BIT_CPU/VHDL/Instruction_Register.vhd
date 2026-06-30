-- =============================================================================
--  File        : Instruction_Register.vhd
--  Entity      : Instruction_Register
--  Project     : 8-bit CPU  (Digital Technology, SS 2026)
--  Description : 8-bit instruction register (IR). Latches the instruction word
--                that was fetched from the program ROM so that it stays stable
--                while it is decoded and executed.
--  Style       : Behavioural, single clocked process (D-flip-flop with
--                asynchronous reset and synchronous enable). No arithmetic, so
--                only std_logic_1164 is needed.
--  Notes       : load_en is driven by the control unit during the fetch state.
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;

entity Instruction_Register is
    port (
        clk             : in  std_logic;
        rst             : in  std_logic;
        clk_en          : in  std_logic;
        load_en         : in  std_logic;
        instruction_in  : in  std_logic_vector(7 downto 0);
        instruction_out : out std_logic_vector(7 downto 0)
    );
end entity;

architecture behavioral of Instruction_Register is

    signal instruction_value : std_logic_vector(7 downto 0);

begin

    -- 8-bit storage register : async reset, sync enable
    ir_register : process(clk, rst)
    begin
        if rst = '1' then                          -- asynchronous reset
            instruction_value <= (others => '0');
        elsif rising_edge(clk) then                -- store on rising edge
            if clk_en = '1' then                   -- synchronous enable
                if load_en = '1' then              -- capture fetched word
                    instruction_value <= instruction_in;
                end if;
            end if;
        end if;
    end process;

    instruction_out <= instruction_value;

end architecture;
