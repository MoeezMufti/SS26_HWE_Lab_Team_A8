library ieee;
use ieee.std_logic_1164.all;

use work.CPU_Package.all;

entity TB_ALU is
end entity;

architecture Simulation of TB_ALU is
    signal A        : std_logic_vector(7 downto 0);
    signal B        : std_logic_vector(7 downto 0);
    signal Opcode   : std_logic_vector(3 downto 0);
    signal Result   : std_logic_vector(7 downto 0);
    signal Carry    : std_logic;
    signal Zero     : std_logic;
    signal Overflow : std_logic;
begin

    UUT : entity work.ALU
        port map (
            Input_A       => A,
            Input_B       => B,
            Opcode        => Opcode,
            Result        => Result,
            Carry_Flag    => Carry,
            Zero_Flag     => Zero,
            Overflow_Flag => Overflow
        );

    process
    begin
        A <= x"03";
        B <= x"02";
        Opcode <= OP_ADD_MEMORY;
        wait for 10 ns;
        assert Result = x"05" report "ADD failed" severity error;

        A <= x"09";
        B <= x"02";
        Opcode <= OP_ADD_MEMORY;
        wait for 10 ns;
        assert Result = x"0B" report "ADD above 9 failed" severity error;

        A <= x"FF";
        B <= x"01";
        Opcode <= OP_ADD_MEMORY;
        wait for 10 ns;
        assert Result = x"00" and Carry = '1' and Zero = '1' report "ADD carry/zero failed" severity error;

        A <= x"05";
        B <= x"02";
        Opcode <= OP_SUB_MEMORY;
        wait for 10 ns;
        assert Result = x"03" report "SUB failed" severity error;

        A <= x"F0";
        B <= x"0F";
        Opcode <= OP_AND_MEMORY;
        wait for 10 ns;
        assert Result = x"00" and Zero = '1' report "AND / zero failed" severity error;

        A <= x"F0";
        B <= x"0F";
        Opcode <= OP_OR_MEMORY;
        wait for 10 ns;
        assert Result = x"FF" report "OR failed" severity error;

        A <= x"AA";
        B <= x"0F";
        Opcode <= OP_XOR_MEMORY;
        wait for 10 ns;
        assert Result = x"A5" report "XOR failed" severity error;

        A <= x"55";
        B <= x"00";
        Opcode <= OP_NOT_ACC;
        wait for 10 ns;
        assert Result = x"AA" report "NOT failed" severity error;

        report "TB_ALU completed successfully." severity note;
        wait;
    end process;

end architecture;
