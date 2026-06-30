-- ============================================================
-- File        : CR_add_sub.vhd
-- Lab         : Lab 02 - Exercise 03
-- Description : 4-bit adder/subtractor using the ripple carry
--               adder from Exercise 02 as a component.
--
-- Operation:
--   Add_Sub = '0'  ->  Result = A + B
--   Add_Sub = '1'  ->  Result = A - B
--
-- Subtraction is done using two's complement:
--   A - B = A + not(B) + 1
-- ============================================================

library ieee;
use ieee.std_logic_1164.all;

entity CR_add_sub is
    port (
        A          : in  std_logic_vector(3 downto 0);
        B          : in  std_logic_vector(3 downto 0);
        Add_Sub    : in  std_logic;
        Result     : out std_logic_vector(3 downto 0);
        Carry_Out  : out std_logic;
        Borrow_Out : out std_logic
    );
end entity CR_add_sub;

architecture structural of CR_add_sub is
    signal b_selected : std_logic_vector(3 downto 0);
    signal adder_cout : std_logic;
begin
    -- When Add_Sub = 0, B passes unchanged.
    -- When Add_Sub = 1, every bit of B is inverted.
    b_selected <= B xor (3 downto 0 => Add_Sub);

    -- The same ripple carry adder performs both operations.
    -- For subtraction, Cin = 1 completes the two's complement of B.
    RCA : entity work.CR_adder
        generic map (
            WIDTH => 4
        )
        port map (
            A    => A,
            B    => b_selected,
            Cin  => Add_Sub,
            S    => Result,
            Cout => adder_cout
        );

    -- In addition mode this is the normal carry-out.
    Carry_Out <= adder_cout;

    -- In subtraction mode, a borrow happened when the final carry is 0.
    -- During addition mode this output is kept at 0 to avoid confusion.
    Borrow_Out <= (not adder_cout) when Add_Sub = '1' else '0';
end architecture structural;
