library ieee;
use ieee.std_logic_1164.all;

-- 1-bit Full Subtractor using behavioral modelling
-- This circuit performs: a - b - bin
-- bin is the borrow input from a previous lower-bit subtractor.
entity full_subtractor_bhv is
    port (
        a      : in  std_logic;  -- Minuend input
        b      : in  std_logic;  -- Subtrahend input
        bin    : in  std_logic;  -- Borrow input
        diff   : out std_logic;  -- Difference output
        borrow : out std_logic   -- Borrow output
    );
end entity full_subtractor_bhv;

architecture behavioral of full_subtractor_bhv is
begin
    -- Difference is 1 when an odd number of a, b, and bin are 1.
    diff <= a xor b xor bin;

    -- Borrow becomes 1 when the subtraction needs to borrow from the next bit.
    -- The equation covers these cases:
    --   a = 0 and b = 1
    --   a = 0 and bin = 1
    --   b = 1 and bin = 1
    borrow <= ((not a) and b) or ((not a) and bin) or (b and bin);
end architecture behavioral;
