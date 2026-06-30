-- Two_Digit_Counter.vhd
-- Lab 07 - Exercise 03
--
-- Two-digit decimal counter from 00 to 99 for the Nexys A7-100T board.
--
-- Controls:
--   START_STOP = '1' -> counter runs
--   START_STOP = '0' -> counter pauses
--   CLR        = '1' -> counter resets to 00
--
-- Display:
--   The ones and tens digits are shown on two 7-segment displays.
--   Because the Nexys display shares the segment lines, the design multiplexes
--   the digits using the anode signals.
--
-- Important:
--   The lab asks for STANDARD VHDL only, so this file uses bit, bit_vector,
--   and integer. It does not use std_logic or IEEE packages.

entity Two_Digit_Counter is
    generic (
        -- 100 MHz / 100_000_000 = 1 Hz count clock.
        COUNT_DIVIDE_N   : positive := 100000000,

        -- 100 MHz / 100_000 = 1 kHz refresh clock.
        -- This is fast enough that the two active digits look steady to the eye.
        REFRESH_DIVIDE_N : positive := 100000
    );
    port (
        CLK        : in  bit;                         -- 100 MHz board clock
        START_STOP : in  bit;                         -- Switch input: run/pause
        CLR        : in  bit;                         -- Switch/input: clear counter

        -- Segment order used in this file:
        -- SEG(6) = CA, SEG(5) = CB, SEG(4) = CC, SEG(3) = CD,
        -- SEG(2) = CE, SEG(1) = CF, SEG(0) = CG
        SEG        : out bit_vector(6 downto 0);

        -- AN(0) is the rightmost digit, AN(1) is the digit next to it.
        AN         : out bit_vector(7 downto 0);

        -- Decimal point, active low on the Nexys board.
        DP         : out bit
    );
end entity Two_Digit_Counter;

architecture behavioral of Two_Digit_Counter is

    signal count_clk   : bit;
    signal refresh_clk : bit;

    signal ones_digit  : integer range 0 to 9 := 0;
    signal tens_digit  : integer range 0 to 9 := 0;

    -- scan_select = '0' -> show ones digit
    -- scan_select = '1' -> show tens digit
    signal scan_select : bit := '0';

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

    -- Slow clock used for visible counting.
    U_COUNT_CLK : entity work.clk_divider
        generic map (
            N => COUNT_DIVIDE_N
        )
        port map (
            CLK   => CLK,
            CLK_N => count_clk
        );

    -- Faster clock used only for display multiplexing.
    U_REFRESH_CLK : entity work.clk_divider
        generic map (
            N => REFRESH_DIVIDE_N
        )
        port map (
            CLK   => CLK,
            CLK_N => refresh_clk
        );

    -- Counter logic: 00 -> 01 -> ... -> 99 -> 00.
    process (count_clk)
    begin
        if count_clk'event and count_clk = '1' then
            if CLR = '1' then
                ones_digit <= 0;
                tens_digit <= 0;
            elsif START_STOP = '1' then
                if ones_digit = 9 then
                    ones_digit <= 0;

                    if tens_digit = 9 then
                        tens_digit <= 0;
                    else
                        tens_digit <= tens_digit + 1;
                    end if;
                else
                    ones_digit <= ones_digit + 1;
                end if;
            end if;
        end if;
    end process;

    -- Toggle between the two display digits.
    process (refresh_clk)
    begin
        if refresh_clk'event and refresh_clk = '1' then
            scan_select <= not scan_select;
        end if;
    end process;

    -- Multiplexed display output.
    process (scan_select, ones_digit, tens_digit)
    begin
        if scan_select = '0' then
            -- Rightmost display shows ones.
            SEG <= digit_to_7seg(ones_digit);
            AN  <= "11111110";
        else
            -- Second display from the right shows tens.
            SEG <= digit_to_7seg(tens_digit);
            AN  <= "11111101";
        end if;
    end process;

    -- Decimal point off.
    DP <= '1';

end architecture behavioral;
