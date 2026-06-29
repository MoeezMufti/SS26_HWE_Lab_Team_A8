library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Seven_Segment_Display is
    port (
        Clock : in std_logic;

        Digit_0_Rightmost : in std_logic_vector(3 downto 0);
        Digit_1           : in std_logic_vector(3 downto 0);
        Digit_2           : in std_logic_vector(3 downto 0);
        Digit_3           : in std_logic_vector(3 downto 0);
        Digit_4           : in std_logic_vector(3 downto 0);
        Digit_5           : in std_logic_vector(3 downto 0);
        Digit_6           : in std_logic_vector(3 downto 0);
        Digit_7_Leftmost  : in std_logic_vector(3 downto 0);

        Segment_Cathodes : out std_logic_vector(6 downto 0);
        Digit_Anodes     : out std_logic_vector(7 downto 0);
        Decimal_Point    : out std_logic
    );
end entity;

architecture RTL of Seven_Segment_Display is
    signal Refresh_Counter : unsigned(19 downto 0) := (others => '0');
    signal Digit_Select    : std_logic_vector(2 downto 0);
    signal Current_Digit   : std_logic_vector(3 downto 0);

    function Hex_To_Seven_Segment(Hex_Value : std_logic_vector(3 downto 0))
        return std_logic_vector is
    begin
        case Hex_Value is
            when "0000" => return "1000000"; -- 0
            when "0001" => return "1111001"; -- 1
            when "0010" => return "0100100"; -- 2
            when "0011" => return "0110000"; -- 3
            when "0100" => return "0011001"; -- 4
            when "0101" => return "0010010"; -- 5
            when "0110" => return "0000010"; -- 6
            when "0111" => return "1111000"; -- 7
            when "1000" => return "0000000"; -- 8
            when "1001" => return "0010000"; -- 9
            when "1010" => return "0001000"; -- A
            when "1011" => return "0000011"; -- b
            when "1100" => return "1000110"; -- C
            when "1101" => return "0100001"; -- d
            when "1110" => return "0000110"; -- E
            when others => return "0001110"; -- F
        end case;
    end function;

begin

    process(Clock)
    begin
        if rising_edge(Clock) then
            Refresh_Counter <= Refresh_Counter + 1;
        end if;
    end process;

    Digit_Select <= std_logic_vector(Refresh_Counter(19 downto 17));

    process(Digit_Select, Digit_0_Rightmost, Digit_1, Digit_2, Digit_3,
            Digit_4, Digit_5, Digit_6, Digit_7_Leftmost)
    begin
        Digit_Anodes <= "11111111";
        Current_Digit <= Digit_0_Rightmost;

        case Digit_Select is
            when "000" =>
                Current_Digit <= Digit_0_Rightmost;
                Digit_Anodes(0) <= '0';
            when "001" =>
                Current_Digit <= Digit_1;
                Digit_Anodes(1) <= '0';
            when "010" =>
                Current_Digit <= Digit_2;
                Digit_Anodes(2) <= '0';
            when "011" =>
                Current_Digit <= Digit_3;
                Digit_Anodes(3) <= '0';
            when "100" =>
                Current_Digit <= Digit_4;
                Digit_Anodes(4) <= '0';
            when "101" =>
                Current_Digit <= Digit_5;
                Digit_Anodes(5) <= '0';
            when "110" =>
                Current_Digit <= Digit_6;
                Digit_Anodes(6) <= '0';
            when others =>
                Current_Digit <= Digit_7_Leftmost;
                Digit_Anodes(7) <= '0';
        end case;
    end process;

    Segment_Cathodes <= Hex_To_Seven_Segment(Current_Digit);
    Decimal_Point <= '1';

end architecture;
