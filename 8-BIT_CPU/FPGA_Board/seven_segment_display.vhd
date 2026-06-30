-- =============================================================================
--  File        : Seven_Segment_Display.vhd
--  Entity      : Seven_Segment_Display
--  Project     : 8-bit CPU  (Digital Technology, SS 2026)
--  Description : Driver for the 8-digit seven-segment display on the Nexys A7.
--
--                The display is used as a live CPU dashboard:
--
--                PC | OPCODE | OPERAND | STATE | ACC_H | ACC_L | OUT_H | OUT_L
--
--  Notes       : The design has two parts:
--                  1) sequential refresh counter for digit multiplexing
--                  2) combinational hexadecimal-to-seven-segment decoder
--
--                Nexys A7 seven-segment signals are active-low:
--                  - segment bit = 0 means segment ON
--                  - anode bit   = 0 means digit ON
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Seven_Segment_Display is
    port (
        Clock             : in  std_logic;

        Digit_0_Rightmost : in  std_logic_vector(3 downto 0);
        Digit_1           : in  std_logic_vector(3 downto 0);
        Digit_2           : in  std_logic_vector(3 downto 0);
        Digit_3           : in  std_logic_vector(3 downto 0);
        Digit_4           : in  std_logic_vector(3 downto 0);
        Digit_5           : in  std_logic_vector(3 downto 0);
        Digit_6           : in  std_logic_vector(3 downto 0);
        Digit_7_Leftmost  : in  std_logic_vector(3 downto 0);

        Segment_Cathodes  : out std_logic_vector(6 downto 0);
        Digit_Anodes      : out std_logic_vector(7 downto 0);
        Decimal_Point     : out std_logic
    );
end entity Seven_Segment_Display;

architecture RTL of Seven_Segment_Display is

    -- Refresh counter for multiplexing the 8 display digits.
    signal Refresh_Counter : unsigned(19 downto 0) := (others => '0');

    -- Selects which digit is currently active.
    signal Active_Digit_Select : std_logic_vector(2 downto 0);

    -- 4-bit value currently being shown on the active digit.
    signal Active_Digit_Value  : std_logic_vector(3 downto 0);

begin

    -- -------------------------------------------------------------------------
    -- Refresh counter
    --
    -- Only one physical digit is switched on at a time.
    -- This counter cycles through the digits quickly, so to the human eye
    -- all 8 digits appear to be on continuously.
    -- -------------------------------------------------------------------------
    refresh_counter_process : process(Clock)
    begin
        if rising_edge(Clock) then
            Refresh_Counter <= Refresh_Counter + 1;
        end if;
    end process refresh_counter_process;

    -- Use the upper counter bits as the digit selector.
    -- These bits change slowly enough for stable display multiplexing.
    Active_Digit_Select <= std_logic_vector(Refresh_Counter(19 downto 17));


    -- -------------------------------------------------------------------------
    -- Digit selection logic
    --
    -- This chooses which input digit value should currently be displayed.
    -- -------------------------------------------------------------------------
    digit_mux_logic : process(Active_Digit_Select,
                              Digit_0_Rightmost,
                              Digit_1,
                              Digit_2,
                              Digit_3,
                              Digit_4,
                              Digit_5,
                              Digit_6,
                              Digit_7_Leftmost)
    begin
        case Active_Digit_Select is

            when "000" =>
                Active_Digit_Value <= Digit_0_Rightmost;
                Digit_Anodes       <= "11111110"; -- AN0 on

            when "001" =>
                Active_Digit_Value <= Digit_1;
                Digit_Anodes       <= "11111101"; -- AN1 on

            when "010" =>
                Active_Digit_Value <= Digit_2;
                Digit_Anodes       <= "11111011"; -- AN2 on

            when "011" =>
                Active_Digit_Value <= Digit_3;
                Digit_Anodes       <= "11110111"; -- AN3 on

            when "100" =>
                Active_Digit_Value <= Digit_4;
                Digit_Anodes       <= "11101111"; -- AN4 on

            when "101" =>
                Active_Digit_Value <= Digit_5;
                Digit_Anodes       <= "11011111"; -- AN5 on

            when "110" =>
                Active_Digit_Value <= Digit_6;
                Digit_Anodes       <= "10111111"; -- AN6 on

            when others =>
                Active_Digit_Value <= Digit_7_Leftmost;
                Digit_Anodes       <= "01111111"; -- AN7 on

        end case;
    end process digit_mux_logic;


    -- -------------------------------------------------------------------------
    -- Hexadecimal to seven-segment decoder
    --
    -- Segment_Cathodes order is:
    --   Segment_Cathodes(6 downto 0) = g f e d c b a
    --
    -- Active-low:
    --   0 = segment ON
    --   1 = segment OFF
    -- -------------------------------------------------------------------------
    hex_decoder_logic : process(Active_Digit_Value)
    begin
        case Active_Digit_Value is

            when "0000" => Segment_Cathodes <= "1000000"; -- 0
            when "0001" => Segment_Cathodes <= "1111001"; -- 1
            when "0010" => Segment_Cathodes <= "0100100"; -- 2
            when "0011" => Segment_Cathodes <= "0110000"; -- 3
            when "0100" => Segment_Cathodes <= "0011001"; -- 4
            when "0101" => Segment_Cathodes <= "0010010"; -- 5
            when "0110" => Segment_Cathodes <= "0000010"; -- 6
            when "0111" => Segment_Cathodes <= "1111000"; -- 7
            when "1000" => Segment_Cathodes <= "0000000"; -- 8
            when "1001" => Segment_Cathodes <= "0010000"; -- 9
            when "1010" => Segment_Cathodes <= "0001000"; -- A
            when "1011" => Segment_Cathodes <= "0000011"; -- b
            when "1100" => Segment_Cathodes <= "1000110"; -- C
            when "1101" => Segment_Cathodes <= "0100001"; -- d
            when "1110" => Segment_Cathodes <= "0000110"; -- E
            when others => Segment_Cathodes <= "0001110"; -- F

        end case;
    end process hex_decoder_logic;

    -- Decimal point is not used, so keep it OFF.
    Decimal_Point <= '1';

end architecture RTL;
