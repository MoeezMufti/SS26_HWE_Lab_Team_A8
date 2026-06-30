library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.CPU_Package.all;

entity Memory_Unit is
    port (
        Clock        : in  std_logic;
        Reset        : in  std_logic;
        Clock_Enable : in  std_logic;

        Program_Select      : in  std_logic_vector(1 downto 0);
        Instruction_Address : in  std_logic_vector(3 downto 0);
        Instruction_Out     : out std_logic_vector(7 downto 0);

        RAM_Write_Enable : in  std_logic;
        RAM_Address      : in  std_logic_vector(3 downto 0);
        RAM_Data_In      : in  std_logic_vector(7 downto 0);
        RAM_Data_Out     : out std_logic_vector(7 downto 0)
    );
end entity;

architecture RTL of Memory_Unit is

    type ROM_Array_Type is array (0 to 15) of std_logic_vector(7 downto 0);
    type RAM_Array_Type is array (0 to 15) of std_logic_vector(7 downto 0);

    signal RAM : RAM_Array_Type := (
        0 => x"02",
        1 => x"01",
        2 => x"00",
        3 => x"0F",
        others => x"00"
    );

    -- Program 0: arithmetic + memory + output. Final output = 04.
    constant Program_0 : ROM_Array_Type := (
        0  => OP_LOAD_IMMEDIATE & "0011", -- ACC = 3
        1  => OP_STORE_MEMORY   & "0010", -- RAM[2] = ACC
        2  => OP_ADD_MEMORY     & "0000", -- ACC = ACC + RAM[0] = 5
        3  => OP_OUT            & "0000", -- OUT = 5
        4  => OP_SUB_MEMORY     & "0001", -- ACC = ACC - RAM[1] = 4
        5  => OP_OUT            & "0000", -- OUT = 4
        6  => OP_AND_MEMORY     & "0011", -- ACC = ACC AND RAM[3] = 4
        7  => OP_OUT            & "0000", -- OUT = 4
        8  => OP_HALT           & "0000", -- HALT
        others => OP_NOP        & "0000"
    );

    -- Program 1: 8-bit datapath demonstration. Final output = 10.
    -- This proves the CPU is not only 4-bit, because:
    -- 4-bit result: F + 1 = 0 with carry
    -- 8-bit result: 0F + 01 = 10
    constant Program_1 : ROM_Array_Type := (
        0  => OP_LOAD_IMMEDIATE & "1111", -- ACC = 0F
        1  => OP_ADD_MEMORY     & "0001", -- ACC = ACC + RAM[1] = 0F + 01 = 10
        2  => OP_OUT            & "0000", -- OUT = 10
        3  => OP_HALT           & "0000", -- Stop CPU
        4  => OP_NOP            & "0000",
        5  => OP_NOP            & "0000",
        6  => OP_NOP            & "0000",
        7  => OP_NOP            & "0000",
        others => OP_NOP        & "0000"
    );

    -- Program 2: logic operations. Final output = 0F.
    constant Program_2 : ROM_Array_Type := (
        0  => OP_LOAD_IMMEDIATE & "1010", -- ACC = A
        1  => OP_XOR_MEMORY     & "0011", -- A XOR F = 5
        2  => OP_OR_MEMORY      & "0011", -- 5 OR F = F
        3  => OP_AND_MEMORY     & "0011", -- F AND F = F
        4  => OP_OUT            & "0000", -- OUT = F
        5  => OP_NOP            & "0000",
        6  => OP_NOP            & "0000",
        7  => OP_HALT           & "0000",
        others => OP_NOP        & "0000"
    );

    -- Program 3: conditional jump using zero flag. Final output = 07.
    constant Program_3 : ROM_Array_Type := (
        0  => OP_LOAD_IMMEDIATE & "0001", -- ACC = 1
        1  => OP_SUB_MEMORY     & "0001", -- ACC = 1 - RAM[1] = 0, zero = 1
        2  => OP_JUMP_IF_ZERO   & "0101", -- if zero, jump to address 5
        3  => OP_LOAD_IMMEDIATE & "1111", -- skipped
        4  => OP_OUT            & "0000", -- skipped
        5  => OP_LOAD_IMMEDIATE & "0111", -- ACC = 7
        6  => OP_OUT            & "0000", -- OUT = 7
        7  => OP_HALT           & "0000",
        others => OP_NOP        & "0000"
    );

begin

    process(Program_Select, Instruction_Address)
        variable Address_Integer : integer range 0 to 15;
    begin
        Address_Integer := to_integer(unsigned(Instruction_Address));

        case Program_Select is
            when "00" =>
                Instruction_Out <= Program_0(Address_Integer);
            when "01" =>
                Instruction_Out <= Program_1(Address_Integer);
            when "10" =>
                Instruction_Out <= Program_2(Address_Integer);
            when others =>
                Instruction_Out <= Program_3(Address_Integer);
        end case;
    end process;

    process(Clock)
    begin
        if rising_edge(Clock) then
            if Reset = '1' then
                RAM(0)  <= x"02";
                RAM(1)  <= x"01";
                RAM(2)  <= x"00";
                RAM(3)  <= x"0F";
                RAM(4)  <= x"00";
                RAM(5)  <= x"00";
                RAM(6)  <= x"00";
                RAM(7)  <= x"00";
                RAM(8)  <= x"00";
                RAM(9)  <= x"00";
                RAM(10) <= x"00";
                RAM(11) <= x"00";
                RAM(12) <= x"00";
                RAM(13) <= x"00";
                RAM(14) <= x"00";
                RAM(15) <= x"00";
            elsif Clock_Enable = '1' then
                if RAM_Write_Enable = '1' then
                    RAM(to_integer(unsigned(RAM_Address))) <= RAM_Data_In;
                end if;
            end if;
        end if;
    end process;

    RAM_Data_Out <= RAM(to_integer(unsigned(RAM_Address)));

end architecture;
