-- ============================================================
-- File        : CR_add_sub_fpga_top.vhd
-- Exercise    : FPGA exercise - 4-bit adder/subtractor on Nexys A7-100T
-- Description : Board-level wrapper for the Lab02 4-bit adder/subtractor.
--
-- Switch usage:
--   SW(3 downto 0)  -> A, first 4-bit number
--   SW(7 downto 4)  -> B, second 4-bit number
--   SW(8)           -> operation select
--                        0 = addition      A + B
--                        1 = subtraction   A - B
--
-- LED usage:
--   LED(3 downto 0) -> 4-bit result
--   LED(4)          -> carry out, useful in addition mode
--   LED(5)          -> borrow out, useful in subtraction mode
--
-- Note:
--   This top file only connects the FPGA board pins to the already
--   designed Lab02 module CR_add_sub. The actual adder/subtractor
--   logic remains inside CR_add_sub.vhd.
-- ============================================================

library ieee;
use ieee.std_logic_1164.all;

entity CR_add_sub_fpga_top is
    port (
        SW  : in  std_logic_vector(8 downto 0);
        LED : out std_logic_vector(5 downto 0)
    );
end entity CR_add_sub_fpga_top;

architecture structural of CR_add_sub_fpga_top is
    signal a_value    : std_logic_vector(3 downto 0);
    signal b_value    : std_logic_vector(3 downto 0);
    signal mode       : std_logic;
    signal result     : std_logic_vector(3 downto 0);
    signal carry_out  : std_logic;
    signal borrow_out : std_logic;
begin
    -- Keep the switch mapping readable by giving the two numbers names.
    a_value <= SW(3 downto 0);
    b_value <= SW(7 downto 4);
    mode    <= SW(8);

    -- Reuse the Lab02 adder/subtractor exactly as a component.
    U_ADD_SUB : entity work.CR_add_sub
        port map (
            A          => a_value,
            B          => b_value,
            Add_Sub    => mode,
            Result     => result,
            Carry_Out  => carry_out,
            Borrow_Out => borrow_out
        );

    -- Show the useful outputs directly on the LEDs.
    LED(3 downto 0) <= result;
    LED(4)          <= carry_out;
    LED(5)          <= borrow_out;
end architecture structural;
