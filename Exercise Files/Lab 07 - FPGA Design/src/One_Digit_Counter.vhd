-- One_Digit_Counter.vhd
-- Lab 07 - Exercise 02
--
-- Decimal counter from 0 to 9 for the Nexys A7-100T board.
--
-- Controls:
--   START_STOP = '1' -> counter runs
--   START_STOP = '0' -> counter pauses
--   CLR        = '1' -> counter resets to 0
--
-- Display:
--   The count value is shown on one 7-segment display digit.
--
-- Important:
--   The lab asks for STANDARD VHDL only, so this file uses bit, bit_vector,
--   and integer. It does not use std_logic or IEEE packages.

entity One_Digit_Counter is
    generic (
        -- Nexys A7 clock is normally 100 MHz.
        -- 100_000_000 gives a visible 1 Hz counting clock.
        COUNT_DIVIDE_N : positive := 100000000
    );
    port (
        CLK        : in  bit;                         -- 100 MHz board clock
        START_STOP : in  bit;                         -- Switch input: run/pause
        CLR        : in  bit;                         -- Switch/input: clear counter

        -- Segment order used in this file:
        -- SEG(6) = CA, SEG(5) = CB, SEG(4) = CC, SEG(3) = CD,
        -- SEG(2) = CE, SEG(1) = CF, SEG(0) = CG
        SEG        : out bit_vector(6 downto 0);

        -- AN(0) is the rightmost digit on the Nexys display.
        AN         : out bit_vector(7 downto 0);

        -- Decimal point, active low on the Nexys board.
        DP         : out bit
    );
end entity One_Digit_Counter;

architecture behavioral of One_Digit_Counter is

    signal slow_clk    : bit;
    signal count_value : integer range 0 to 9 := 0;

    -- Converts a decimal digit to active-low seven-segment output.
    -- The strings below follow the segment order:
    --   CA CB CC CD CE CF CG
    function digit_to_7seg(digit : integer) return bit_vector is
    begin
        case digit is
            when 0 => return "0000001";
            when 1 => return "1001111";
            when 2 => return "0010010";
            when 3 => return "0000110";
            when 4 => return "1001100";
            when 5 => return "0100100";
            when 6 => return "0100000";
            when 7 => return "0001111";
            when 8 => return "0000000";
            when 9 => return "0000100";
            when others => return "1111111";  -- blank/off
        end case;
    end function;

begin

    -- Use the clock divider from Exercise 01 so that the count is visible.
    U_CLK_DIVIDER : entity work.clk_divider
        generic map (
            N => COUNT_DIVIDE_N
        )
        port map (
            CLK   => CLK,
            CLK_N => slow_clk
        );

    -- Main counter.
    process (slow_clk)
    begin
        if slow_clk'event and slow_clk = '1' then
            if CLR = '1' then
                count_value <= 0;
            elsif START_STOP = '1' then
                if count_value = 9 then
                    count_value <= 0;
                else
                    count_value <= count_value + 1;
                end if;
            end if;
        end if;
    end process;

    -- Show the current count value on the rightmost digit.
    SEG <= digit_to_7seg(count_value);

    -- Enable only the rightmost digit. Anodes are active low.
    AN <= "11111110";

    -- Turn decimal point off. Decimal point is active low.
    DP <= '1';

end architecture behavioral;
