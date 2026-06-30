-- ============================================================
-- File        : CR_adder.vhd
-- Lab         : Lab 02 - Exercise 02
-- Description : Ripple carry adder built structurally from
--               full_adder components.
--
-- Default width is 4 bits, as required in the lab. The generic
-- WIDTH makes the design easy to reuse for a different bit width.
-- To build an 8-bit adder, for example, instantiate it with
-- WIDTH => 8 and connect 8-bit vectors.
-- ============================================================

library ieee;
use ieee.std_logic_1164.all;

entity CR_adder is
    generic (
        WIDTH : positive := 4
    );
    port (
        A    : in  std_logic_vector(WIDTH - 1 downto 0);
        B    : in  std_logic_vector(WIDTH - 1 downto 0);
        Cin  : in  std_logic;
        S    : out std_logic_vector(WIDTH - 1 downto 0);
        Cout : out std_logic
    );
end entity CR_adder;

architecture structural of CR_adder is
    signal carry : std_logic_vector(WIDTH downto 0);
begin
    -- External carry-in enters the least significant full adder.
    carry(0) <= Cin;

    -- One full adder is generated for every bit position.
    FA_GEN : for i in 0 to WIDTH - 1 generate
        FA_i : entity work.full_adder
            port map (
                A    => A(i),
                B    => B(i),
                Cin  => carry(i),
                S    => S(i),
                Cout => carry(i + 1)
            );
    end generate FA_GEN;

    -- Carry leaving the most significant full adder.
    Cout <= carry(WIDTH);
end architecture structural;
