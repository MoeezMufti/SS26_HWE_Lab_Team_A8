library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.CPU_Package.all;

entity ALU is
    port (
        Input_A       : in  std_logic_vector(7 downto 0);
        Input_B       : in  std_logic_vector(7 downto 0);
        Opcode        : in  std_logic_vector(3 downto 0);

        Result        : out std_logic_vector(7 downto 0);
        Carry_Flag    : out std_logic;
        Zero_Flag     : out std_logic;
        Overflow_Flag : out std_logic
    );
end entity;

architecture RTL of ALU is
begin

    process(Input_A, Input_B, Opcode)
        variable Temp     : unsigned(8 downto 0);
        variable R        : std_logic_vector(7 downto 0);
        variable Carry    : std_logic;
        variable Overflow : std_logic;
    begin
        R        := Input_A;
        Carry    := '0';
        Overflow := '0';

        case Opcode is

            when OP_LOAD_IMMEDIATE =>
                R := Input_B;

            when OP_LOAD_MEMORY =>
                R := Input_B;

            when OP_ADD_MEMORY =>
                Temp  := ('0' & unsigned(Input_A)) + ('0' & unsigned(Input_B));
                R     := std_logic_vector(Temp(7 downto 0));
                Carry := Temp(8);

                if (Input_A(7) = Input_B(7)) and (R(7) /= Input_A(7)) then
                    Overflow := '1';
                end if;

            when OP_SUB_MEMORY =>
                Temp  := ('0' & unsigned(Input_A)) - ('0' & unsigned(Input_B));
                R     := std_logic_vector(Temp(7 downto 0));
                Carry := Temp(8);

                if (Input_A(7) /= Input_B(7)) and (R(7) /= Input_A(7)) then
                    Overflow := '1';
                end if;

            when OP_AND_MEMORY =>
                R := Input_A and Input_B;

            when OP_OR_MEMORY =>
                R := Input_A or Input_B;

            when OP_XOR_MEMORY =>
                R := Input_A xor Input_B;

            when OP_NOT_ACC =>
                R := not Input_A;

            when OP_CLEAR =>
                R := (others => '0');

            when others =>
                R := Input_A;

        end case;

        Result        <= R;
        Carry_Flag    <= Carry;
        Overflow_Flag <= Overflow;

        if R = "00000000" then
            Zero_Flag <= '1';
        else
            Zero_Flag <= '0';
        end if;

    end process;

end architecture;
