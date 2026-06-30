-- =============================================================================
--  File        : Program_Counter.vhd
--  Entity      : Program_Counter
--  Project     : 8-bit CPU  (Digital Technology, SS 2026)
--  Description : 4-bit program counter. Points at the next instruction in the
--                program ROM. Supports synchronous load (for jumps) and
--                increment (normal fetch).
--  Style       : Behavioural, single clocked process. Built like the lecture
--                "D-flip-flop with asynchronous reset and synchronous enable":
--                  - asynchronous reset (rst in sensitivity list, checked first)
--                  - rising_edge(clk) for the storing edge
--                  - synchronous enable (clk_en)
--  Notes       : load has priority over increment. Names are
--                lowercase_with_underscores (lecture naming convention).
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;          -- unsigned + "+" + conversions

entity Program_Counter is
    port (
        clk        : in  std_logic;
        rst        : in  std_logic;
        clk_en     : in  std_logic;
        increment  : in  std_logic;
        load_en    : in  std_logic;
        load_value : in  std_logic_vector(3 downto 0);
        count_out  : out std_logic_vector(3 downto 0)
    );
end entity;

architecture behavioral of Program_Counter is

    -- internal count kept as unsigned so we can use "+ 1" (numeric_std)
    signal count_value : unsigned(3 downto 0);

begin

    -- counter register : async reset, sync enable
    pc_register : process(clk, rst)
    begin
        if rst = '1' then                          -- asynchronous reset
            count_value <= (others => '0');
        elsif rising_edge(clk) then                -- store on rising edge
            if clk_en = '1' then                   -- synchronous enable
                if load_en = '1' then              -- jump: load new address
                    count_value <= unsigned(load_value);
                elsif increment = '1' then         -- normal fetch: PC + 1
                    count_value <= count_value + 1;
                end if;
            end if;
        end if;
    end process;

    -- cast the internal unsigned back to std_logic_vector for the output port
    count_out <= std_logic_vector(count_value);

end architecture;
