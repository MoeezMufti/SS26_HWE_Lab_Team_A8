library ieee;
use ieee.std_logic_1164.all;

-- 1-bit Half Subtractor
-- This circuit subtracts one 1-bit value from another: a - b.
-- It produces:
--   diff   = difference bit
--   borrow = 1 when a borrow is needed
entity half_subtractor is
    port (
        a      : in  std_logic;  -- Minuend input, the value we subtract from
        b      : in  std_logic;  -- Subtrahend input, the value being subtracted
        diff   : out std_logic;  -- Difference output
        borrow : out std_logic   -- Borrow output
    );
end entity half_subtractor;

architecture behavioral of half_subtractor is
begin
    -- Difference is 1 when the two inputs are different.
    -- This is the same XOR behavior used for the half adder sum.
    diff <= a xor b;

    -- Borrow is needed only for 0 - 1.
    -- That means borrow = 1 when a = 0 and b = 1.
    borrow <= (not a) and b;
end architecture behavioral;
