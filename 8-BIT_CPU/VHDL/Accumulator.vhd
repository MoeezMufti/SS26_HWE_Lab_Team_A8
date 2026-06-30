-- =============================================================================
--  File        : Accumulator.vhd
--  Entity      : Accumulator
--  Project     : 8-bit CPU  (Digital Technology, SS 2026)
--  Description : 8-bit accumulator register (ACC). Holds the main working value
--                of the CPU. The ALU result is written back here whenever the
--                control unit asserts load_en.
--  Style       : Behavioural, single clocked process. This is exactly the
--                lecture "D-flip-flop with synchronous enable", widened to 8
--                bits and given an asynchronous reset.
--  Notes       : This file completes the design - CPU_Top instantiates an
--                Accumulator, so the entity must exist.
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;

entity Accumulator is
    port (
        clk      : in  std_logic;
        rst      : in  std_logic;
        clk_en   : in  std_logic;
        load_en  : in  std_logic;
        data_in  : in  std_logic_vector(7 downto 0);
        data_out : out std_logic_vector(7 downto 0)
    );
end entity;

architecture behavioral of Accumulator is

    signal acc_value : std_logic_vector(7 downto 0);

begin

    -- accumulator register : async reset, sync enable, synchronous load
    acc_register : process(clk, rst)
    begin
        if rst = '1' then                          -- asynchronous reset
            acc_value <= (others => '0');
        elsif rising_edge(clk) then                -- store on rising edge
            if clk_en = '1' then                   -- synchronous enable
                if load_en = '1' then              -- write ALU result back
                    acc_value <= data_in;
                end if;
            end if;
        end if;
    end process;

    data_out <= acc_value;

end architecture;
