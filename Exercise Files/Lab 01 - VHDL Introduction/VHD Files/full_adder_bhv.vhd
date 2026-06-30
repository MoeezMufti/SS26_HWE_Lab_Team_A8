library ieee;
use ieee.std_logic_1164.all;

-- 1-bit Full Adder using behavioral modelling
-- This circuit adds three 1-bit values: a, b, and cin.
-- cin is the carry input from a previous lower-bit adder.
entity full_adder_bhv is
    port (
        a     : in  std_logic;  -- First 1-bit input
        b     : in  std_logic;  -- Second 1-bit input
        cin   : in  std_logic;  -- Carry input
        sum   : out std_logic;  -- Sum output
        carry : out std_logic   -- Carry output
    );
end entity full_adder_bhv;

architecture behavioral of full_adder_bhv is
begin
    -- Sum is 1 when an odd number of inputs are 1.
    -- This is exactly what XOR does for a, b, and cin.
    sum <= a xor b xor cin;

    -- Carry is 1 when at least two of the three inputs are 1.
    -- Examples:
    --   1 + 1 + 0 gives carry = 1
    --   1 + 0 + 1 gives carry = 1
    --   0 + 1 + 1 gives carry = 1
    --   1 + 1 + 1 also gives carry = 1
    carry <= (a and b) or (a and cin) or (b and cin);
end architecture behavioral;
