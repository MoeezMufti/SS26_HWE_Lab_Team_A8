library ieee;
use ieee.std_logic_1164.all;

-- 1-bit Half Adder
-- This circuit adds two 1-bit inputs: a and b.
-- It produces:
--   sum   = result bit of a + b
--   carry = carry-out bit when both inputs are 1
entity half_adder is
    port (
        a     : in  std_logic;  -- First 1-bit input
        b     : in  std_logic;  -- Second 1-bit input
        sum   : out std_logic;  -- Sum output
        carry : out std_logic   -- Carry output
    );
end entity half_adder;

architecture behavioral of half_adder is
begin
    -- Sum is 1 only when the two inputs are different.
    -- Example: 0+1 or 1+0 gives sum = 1.
    sum <= a xor b;

    -- Carry is 1 only when both inputs are 1.
    -- Example: 1+1 = binary 10, so sum = 0 and carry = 1.
    carry <= a and b;
end architecture behavioral;
