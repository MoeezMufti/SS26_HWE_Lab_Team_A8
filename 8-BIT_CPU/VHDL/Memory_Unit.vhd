-- =============================================================================
--  File        : Memory_Unit.vhd
--  Entity      : Memory_Unit
--  Project     : 8-bit CPU  (Digital Technology, SS 2026)
--  Description : Combined memory block.
--                  - ROM : four selectable demo programs (program_select picks
--                          one). Read-only, addressed by the program counter.
--                  - RAM : 16 bytes of read/write data memory used by the
--                          load/store/arithmetic instructions.
--  Style       : One combinational process for the ROM read (case statement,
--                like a multiplexer) and one clocked process for the RAM
--                (D-flip-flop array with asynchronous reset, synchronous
--                enable). Array types declared with "type ... is array (...)",
--                as taught under Data types.
--  Notes       : ROM contents are constants; RAM start-up / reset contents are
--                held in the RAM_INIT constant so the value is written in one
--                place only.
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;          -- to_integer / unsigned for addressing

use work.CPU_Package.all;          -- OP_* opcode constants

entity Memory_Unit is
    port (
        clk          : in  std_logic;
        rst          : in  std_logic;
        clk_en       : in  std_logic;

        -- instruction (ROM) side
        program_select      : in  std_logic_vector(1 downto 0);
        instruction_address : in  std_logic_vector(3 downto 0);
        instruction_out     : out std_logic_vector(7 downto 0);

        -- data (RAM) side
        ram_write_enable : in  std_logic;
        ram_address      : in  std_logic_vector(3 downto 0);
        ram_data_in      : in  std_logic_vector(7 downto 0);
        ram_data_out     : out std_logic_vector(7 downto 0)
    );
end entity;

architecture behavioral of Memory_Unit is

    -- array types: 16 words of 8 bits each
    type rom_array_type is array (0 to 15) of std_logic_vector(7 downto 0);
    type ram_array_type is array (0 to 15) of std_logic_vector(7 downto 0);

    -- start-up / reset contents of the data RAM (single source of truth)
    constant RAM_INIT : ram_array_type := (
        0 => x"02",
        1 => x"01",
        2 => x"00",
        3 => x"0F",
        others => x"00"
    );

    signal ram : ram_array_type := RAM_INIT;

    -- Program 0: arithmetic + memory + output. Final output = 04.
    constant PROGRAM_0 : rom_array_type := (
        0  => OP_LOAD_IMMEDIATE & "0011",   -- ACC = 3
        1  => OP_STORE_MEMORY   & "0010",   -- RAM[2] = ACC
        2  => OP_ADD_MEMORY     & "0000",   -- ACC = ACC + RAM[0] = 5
        3  => OP_OUT            & "0000",   -- OUT = 5
        4  => OP_SUB_MEMORY     & "0001",   -- ACC = ACC - RAM[1] = 4
        5  => OP_OUT            & "0000",   -- OUT = 4
        6  => OP_AND_MEMORY     & "0011",   -- ACC = ACC AND RAM[3] = 4
        7  => OP_OUT            & "0000",   -- OUT = 4
        8  => OP_HALT           & "0000",   -- HALT
        others => OP_NOP        & "0000"
    );

    -- Program 1: arithmetic with hex result above 9. Final output = 0D.
    constant PROGRAM_1 : rom_array_type := (
        0  => OP_LOAD_IMMEDIATE & "1011",   -- ACC = B hex = 11 decimal
        1  => OP_ADD_MEMORY     & "0000",   -- ACC = B + RAM[0] = D hex
        2  => OP_OUT            & "0000",   -- OUT = D
        3  => OP_NOP            & "0000",
        4  => OP_NOP            & "0000",
        5  => OP_NOP            & "0000",
        6  => OP_NOP            & "0000",
        7  => OP_HALT           & "0000",
        others => OP_NOP        & "0000"
    );

    -- Program 2: logic operations. Final output = 0F.
    constant PROGRAM_2 : rom_array_type := (
        0  => OP_LOAD_IMMEDIATE & "1010",   -- ACC = A
        1  => OP_XOR_MEMORY     & "0011",   -- A XOR F = 5
        2  => OP_OR_MEMORY      & "0011",   -- 5 OR F = F
        3  => OP_AND_MEMORY     & "0011",   -- F AND F = F
        4  => OP_OUT            & "0000",   -- OUT = F
        5  => OP_NOP            & "0000",
        6  => OP_NOP            & "0000",
        7  => OP_HALT           & "0000",
        others => OP_NOP        & "0000"
    );

    -- Program 3: conditional jump using the zero flag. Final output = 07.
    constant PROGRAM_3 : rom_array_type := (
        0  => OP_LOAD_IMMEDIATE & "0001",   -- ACC = 1
        1  => OP_SUB_MEMORY     & "0001",   -- ACC = 1 - RAM[1] = 0, zero = 1
        2  => OP_JUMP_IF_ZERO   & "0101",   -- if zero, jump to address 5
        3  => OP_LOAD_IMMEDIATE & "1111",   -- skipped
        4  => OP_OUT            & "0000",   -- skipped
        5  => OP_LOAD_IMMEDIATE & "0111",   -- ACC = 7
        6  => OP_OUT            & "0000",   -- OUT = 7
        7  => OP_HALT           & "0000",
        others => OP_NOP        & "0000"
    );

begin

    -- ----------------------------------------------------------------------
    -- ROM read : pick the selected program, then index it with the PC.
    -- Purely combinational (acts like a multiplexer over the four programs).
    -- ----------------------------------------------------------------------
    rom_read : process(program_select, instruction_address)
        variable address_integer : integer range 0 to 15;
    begin
        address_integer := to_integer(unsigned(instruction_address));

        case program_select is
            when "00" =>
                instruction_out <= PROGRAM_0(address_integer);
            when "01" =>
                instruction_out <= PROGRAM_1(address_integer);
            when "10" =>
                instruction_out <= PROGRAM_2(address_integer);
            when others =>
                instruction_out <= PROGRAM_3(address_integer);
        end case;
    end process;

    -- ----------------------------------------------------------------------
    -- RAM write : clocked array. Async reset restores the start-up contents,
    -- synchronous enable gates the write (single-step friendly).
    -- ----------------------------------------------------------------------
    ram_write_proc : process(clk, rst)
    begin
        if rst = '1' then                              -- asynchronous reset
            ram <= RAM_INIT;
        elsif rising_edge(clk) then                    -- store on rising edge
            if clk_en = '1' then                       -- synchronous enable
                if ram_write_enable = '1' then
                    ram(to_integer(unsigned(ram_address))) <= ram_data_in;
                end if;
            end if;
        end if;
    end process;

    -- RAM read is combinational (asynchronous read port)
    ram_data_out <= ram(to_integer(unsigned(ram_address)));

end architecture;
