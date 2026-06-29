library ieee;
use ieee.std_logic_1164.all;

use work.CPU_Package.all;

entity Nexys_A7_ALU_Test is
    port (
        clk  : in  std_logic;
        sw   : in  std_logic_vector(15 downto 0);

        btnC : in  std_logic;
        btnU : in  std_logic;
        btnL : in  std_logic;
        btnR : in  std_logic;
        btnD : in  std_logic;

        led  : out std_logic_vector(15 downto 0);
        seg  : out std_logic_vector(6 downto 0);
        an   : out std_logic_vector(7 downto 0);
        dp   : out std_logic
    );
end entity;

architecture Structural of Nexys_A7_ALU_Test is
    signal A        : std_logic_vector(7 downto 0);
    signal B        : std_logic_vector(7 downto 0);
    signal Opcode   : std_logic_vector(3 downto 0);
    signal Result   : std_logic_vector(7 downto 0);
    signal Carry    : std_logic;
    signal Zero     : std_logic;
    signal Overflow : std_logic;
begin

    -- Switch mapping:
    -- SW[7:0]    = Input A
    -- SW[11:8]   = Input B lower nibble, zero-extended to 8 bits
    -- SW[15:12]  = Opcode
    A      <= sw(7 downto 0);
    B      <= "0000" & sw(11 downto 8);
    Opcode <= sw(15 downto 12);

    ALU_Block : entity work.ALU
        port map (
            Input_A       => A,
            Input_B       => B,
            Opcode        => Opcode,
            Result        => Result,
            Carry_Flag    => Carry,
            Zero_Flag     => Zero,
            Overflow_Flag => Overflow
        );

    -- Single driver for all LEDs. This avoids multi-driven net warnings.
    -- Buttons are mapped to LEDs to avoid unused-button warnings.
    process(Result, Zero, Carry, Overflow, btnC, btnU, btnL, btnR, btnD)
    begin
        led(7 downto 0) <= Result;

        led(8)  <= btnC;
        led(9)  <= btnU;
        led(10) <= btnL;
        led(11) <= btnR;

        led(12) <= Zero;
        led(13) <= Carry;
        led(14) <= Overflow;

        led(15) <= btnD;
    end process;

    -- Seven-segment layout, left to right:
    -- 0 0 Opcode B A_high A_low Result_high Result_low
    -- Example: A=03, B=2, Opcode=4, Result=05 -> 00420305
    Display : entity work.Seven_Segment_Display
        port map (
            Clock => clk,

            Digit_0_Rightmost => Result(3 downto 0),
            Digit_1           => Result(7 downto 4),
            Digit_2           => A(3 downto 0),
            Digit_3           => A(7 downto 4),
            Digit_4           => sw(11 downto 8),
            Digit_5           => Opcode,
            Digit_6           => "0000",
            Digit_7_Leftmost  => "0000",

            Segment_Cathodes => seg,
            Digit_Anodes     => an,
            Decimal_Point    => dp
        );

end architecture;
