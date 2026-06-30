-- ============================================================
-- File        : BCD_adder_fpga_top.vhd
-- Exercise    : FPGA exercise - 4-bit BCD adder on Nexys A7-100T
-- Description : Board-level wrapper for the Lab02 BCD adder.
--
-- Switch usage:
--   SW(3 downto 0) -> A, first BCD digit  0 to 9
--   SW(7 downto 4) -> B, second BCD digit 0 to 9
--
-- Output usage:
--   Rightmost 7-segment display -> ones digit of A + B
--   CARRY_LED                   -> decimal carry, lit when A + B >= 10
--
-- Important board note:
--   The Nexys A7 7-segment display is active-low.
--   The Lab02 BCDto7seg module gives active-high segment values,
--   so this wrapper inverts the segment outputs before sending them
--   to the board pins.
-- ============================================================

library ieee;
use ieee.std_logic_1164.all;

entity BCD_adder_fpga_top is
    port (
        SW        : in  std_logic_vector(7 downto 0);
        CARRY_LED : out std_logic;

        -- Individual segment outputs. These names match the usual
        -- Nexys A7 master XDC naming: CA, CB, CC, CD, CE, CF, CG.
        CA        : out std_logic;
        CB        : out std_logic;
        CC        : out std_logic;
        CD        : out std_logic;
        CE        : out std_logic;
        CF        : out std_logic;
        CG        : out std_logic;
        DP        : out std_logic;
        AN        : out std_logic_vector(7 downto 0)
    );
end entity BCD_adder_fpga_top;

architecture structural of BCD_adder_fpga_top is
    signal a_bcd           : std_logic_vector(3 downto 0);
    signal b_bcd           : std_logic_vector(3 downto 0);
    signal bcd_sum         : std_logic_vector(3 downto 0);
    signal decimal_carry   : std_logic;
    signal seg_active_high : std_logic_vector(6 downto 0);
begin
    -- The two BCD numbers come directly from the slide switches.
    a_bcd <= SW(3 downto 0);
    b_bcd <= SW(7 downto 4);

    -- Add one BCD digit to another. Cin is fixed to 0 because the
    -- exercise only asks for two 4-bit inputs from switches.
    U_BCD_ADDER : entity work.BCD_adder
        port map (
            A    => a_bcd,
            B    => b_bcd,
            Cin  => '0',
            Sum  => bcd_sum,
            Cout => decimal_carry
        );

    -- Convert the resulting BCD digit to seven segment form.
    U_7SEG : entity work.BCDto7seg
        port map (
            BCD => bcd_sum,
            Seg => seg_active_high
        );

    -- Nexys A7 segments are active-low, so invert the active-high code.
    -- Lab02 segment order is: Seg(6 downto 0) = a b c d e f g.
    CA <= not seg_active_high(6);
    CB <= not seg_active_high(5);
    CC <= not seg_active_high(4);
    CD <= not seg_active_high(3);
    CE <= not seg_active_high(2);
    CF <= not seg_active_high(1);
    CG <= not seg_active_high(0);

    -- Decimal point off. It is also active-low, so '1' means off.
    DP <= '1';

    -- Enable only the rightmost display digit, AN0.
    -- Anodes are active-low on the Nexys A7.
    AN <= "11111110";

    -- Show the decimal carry on one normal LED.
    CARRY_LED <= decimal_carry;
end architecture structural;
