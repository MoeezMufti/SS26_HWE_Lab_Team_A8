-- ============================================================
-- File        : BCDto7seg_tb.vhd
-- Lab         : Lab 02 - Exercise 05
-- Description : Testbench for the BCD to 7-segment converter.
--               It checks decimal digits 0 to 9 and also invalid
--               BCD inputs 10 to 15.
-- ============================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity BCDto7seg_tb is
end entity BCDto7seg_tb;

architecture bench of BCDto7seg_tb is
    signal BCD : std_logic_vector(3 downto 0) := (others => '0');
    signal Seg : std_logic_vector(6 downto 0);

    function expected_segments(value : integer) return std_logic_vector is
    begin
        case value is
            when 0 => return "1111110";
            when 1 => return "0110000";
            when 2 => return "1101101";
            when 3 => return "1111001";
            when 4 => return "0110011";
            when 5 => return "1011011";
            when 6 => return "1011111";
            when 7 => return "1110000";
            when 8 => return "1111111";
            when 9 => return "1111011";
            when others => return "0000000";
        end case;
    end function;
begin
    uut : entity work.BCDto7seg
        port map (
            BCD => BCD,
            Seg => Seg
        );

    stimulus : process
        variable expected : std_logic_vector(6 downto 0);
    begin
        for value in 0 to 15 loop
            BCD <= std_logic_vector(to_unsigned(value, 4));
            wait for 10 ns;

            expected := expected_segments(value);

            assert Seg = expected
                report "BCDto7seg failed for input " & integer'image(value)
                severity error;
        end loop;

        report "BCDto7seg_tb: all valid and invalid cases passed." severity note;
        wait;
    end process stimulus;
end architecture bench;
