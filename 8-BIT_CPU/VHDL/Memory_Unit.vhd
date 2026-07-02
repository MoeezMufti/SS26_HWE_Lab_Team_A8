--  Description : Program ROM and data RAM for the 8-bit CPU.
--                Program ROM:
--                  - stores four small demo programs
--                  - selected using Program_Select
--                  - addressed by the 4-bit Program Counter
--                Data RAM:
--                  - 16 addresses, each storing 8-bit data
--                  - asynchronous read
--                  - synchronous write
--
--  Notes       : The ROM part is combinational logic.
--                The RAM write part is sequential logic.
--                Reset is asynchronous and restores the initial RAM values.

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.CPU_Package.all;

entity Memory_Unit is
    port (
        Clock               : in  std_logic;
        Reset               : in  std_logic;
        Clock_Enable        : in  std_logic;

        Program_Select      : in  std_logic_vector(1 downto 0);

        Instruction_Address : in  std_logic_vector(3 downto 0);
        Instruction_Out     : out std_logic_vector(7 downto 0);

        RAM_Write_Enable    : in  std_logic;
        RAM_Address         : in  std_logic_vector(3 downto 0);
        RAM_Data_In         : in  std_logic_vector(7 downto 0);
        RAM_Data_Out        : out std_logic_vector(7 downto 0)
    );
end entity Memory_Unit;

architecture RTL of Memory_Unit is

    -- 16 instructions, each 8 bits wide.
    type ROM_Array_Type is array (0 to 15) of std_logic_vector(7 downto 0);

    -- 16 RAM locations, each 8 bits wide.
    type RAM_Array_Type is array (0 to 15) of std_logic_vector(7 downto 0);

    -- Initial RAM contents.
    signal RAM : RAM_Array_Type := (
        0      => x"02",   -- RAM[0] = 02
        1      => x"01",   -- RAM[1] = 01
        2      => x"00",   -- RAM[2] = 00,
        3      => x"0F",   -- RAM[3] = 0F,
        others => x"00"
    );

    -- Program 0: arithmetic + memory + output.
    -- Final output = 04.
    constant Program_0 : ROM_Array_Type := (
        0      => OP_LOAD_IMMEDIATE & "0011", -- ACC = 03
        1      => OP_STORE_MEMORY   & "0010", -- RAM[2] = ACC = 03
        2      => OP_ADD_MEMORY     & "0000", -- ACC = ACC + RAM[0] = 03 + 02 = 05
        3      => OP_OUT            & "0000", -- OUT = 05
        4      => OP_SUB_MEMORY     & "0001", -- ACC = ACC - RAM[1] = 05 - 01 = 04
        5      => OP_OUT            & "0000", -- OUT = 04
        6      => OP_AND_MEMORY     & "0011", -- ACC = ACC AND RAM[3] = 04 AND 0F = 04
        7      => OP_OUT            & "0000", -- OUT = 04
        8      => OP_HALT           & "0000", -- HALT
        others => OP_NOP            & "0000"
    );

    -- Program 1: 8-bit datapath demonstration.
    -- Final output = 10.
    --   4-bit result: F + 1 = 0 with carry
    --   8-bit result: 0F + 01 = 10
    constant Program_1 : ROM_Array_Type := (
        0      => OP_LOAD_IMMEDIATE & "1111", -- ACC = 0F
        1      => OP_ADD_MEMORY     & "0001", -- ACC = ACC + RAM[1] = 0F + 01 = 10
        2      => OP_OUT            & "0000", -- OUT = 10
        3      => OP_HALT           & "0000", -- HALT
        others => OP_NOP            & "0000"
    );

    -- Program 2: logic operations.
    -- Final output = 0F.
    constant Program_2 : ROM_Array_Type := (
        0      => OP_LOAD_IMMEDIATE & "1010", -- ACC = 0A
        1      => OP_XOR_MEMORY     & "0011", -- ACC = 0A XOR RAM[3] = 0A XOR 0F = 05
        2      => OP_OR_MEMORY      & "0011", -- ACC = 05 OR  RAM[3] = 05 OR  0F = 0F
        3      => OP_AND_MEMORY     & "0011", -- ACC = 0F AND RAM[3] = 0F AND 0F = 0F
        4      => OP_OUT            & "0000", -- OUT = 0F
        5      => OP_HALT           & "0000", -- HALT
        others => OP_NOP            & "0000"
    );

    -- Program 3: conditional jump using zero flag.
    -- Final output = 07.
    constant Program_3 : ROM_Array_Type := (
        0      => OP_LOAD_IMMEDIATE & "0001", -- ACC = 01
        1      => OP_SUB_MEMORY     & "0001", -- ACC = 01 - RAM[1] = 01 - 01 = 00, zero flag = 1
        2      => OP_JUMP_IF_ZERO   & "0101", -- if zero flag = 1, jump to address 5
        3      => OP_LOAD_IMMEDIATE & "1111", -- skipped if jump works
        4      => OP_OUT            & "0000", -- skipped if jump works
        5      => OP_LOAD_IMMEDIATE & "0111", -- ACC = 07
        6      => OP_OUT            & "0000", -- OUT = 07
        7      => OP_HALT           & "0000", -- HALT
        others => OP_NOP            & "0000"
    );

begin

    -- ROM read logic is combinational.
    -- The selected instruction depends only on Program_Select and Instruction_Address.
    rom_read_logic : process(Program_Select, Instruction_Address)
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
    end process rom_read_logic;


    -- RAM write logic
    -- Reset is asynchronous because it is checked before the clock edge.
    -- RAM writes are synchronous because they happen only on rising_edge(Clock).
    ram_write_logic : process(Clock, Reset)
    begin
        if Reset = '1' then
            RAM <= (
                0      => x"02",
                1      => x"01",
                2      => x"00",
                3      => x"0F",
                others => x"00"
            );

        elsif rising_edge(Clock) then
            if Clock_Enable = '1' then
                if RAM_Write_Enable = '1' then
                    RAM(to_integer(unsigned(RAM_Address))) <= RAM_Data_In;
                end if;
            end if;
        end if;
    end process ram_write_logic;


    -- RAM read logic
    -- This is an asynchronous read.
    -- Whenever RAM_Address changes, RAM_Data_Out changes to the value stored at that address.
    RAM_Data_Out <= RAM(to_integer(unsigned(RAM_Address)));

end architecture RTL;
