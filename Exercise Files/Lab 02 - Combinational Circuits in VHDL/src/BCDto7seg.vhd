-- ============================================================
-- File        : BCDto7seg.vhd
-- Lab         : Lab 02 - Exercise 05
-- Description : BCD to 7-segment decoder.
--
-- Segment order used here:
--   Seg(6 downto 0) = a b c d e f g
--
-- The output is active-high:
--   '1' means the segment is ON.
-- If your FPGA board uses active-low displays, simply invert Seg
-- before connecting it to the pins.
-- ============================================================

library ieee;
use ieee.std_logic_1164.all;

entity BCDto7seg is
    port (
        BCD : in  std_logic_vector(3 downto 0);
        Seg : out std_logic_vector(6 downto 0)
    );
end entity BCDto7seg;

architecture behavioral of BCDto7seg is
begin
    process (BCD)
    begin
        case BCD is
            when "0000" => Seg <= "1111110"; -- 0
            when "0001" => Seg <= "0110000"; -- 1
            when "0010" => Seg <= "1101101"; -- 2
            when "0011" => Seg <= "1111001"; -- 3
            when "0100" => Seg <= "0110011"; -- 4
            when "0101" => Seg <= "1011011"; -- 5
            when "0110" => Seg <= "1011111"; -- 6
            when "0111" => Seg <= "1110000"; -- 7
            when "1000" => Seg <= "1111111"; -- 8
            when "1001" => Seg <= "1111011"; -- 9
            when others => Seg <= "0000000"; -- invalid BCD input, display off
        end case;
    end process;
end architecture behavioral;
