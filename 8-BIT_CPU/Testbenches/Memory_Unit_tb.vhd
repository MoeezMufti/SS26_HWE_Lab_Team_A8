-- =============================================================================
--  File        : Memory_Unit_tb.vhd
--  Entity      : Memory_Unit_tb
--  Project     : 8-bit CPU  (Digital Technology, SS 2026)
--  Description : Unit testbench for the Memory_Unit (program ROM + data RAM).
--
--                The memory unit does two quite different jobs, so we test both:
--
--                Program ROM (combinational read):
--                  - read a couple of known instruction words back and check
--                    they match the encoded opcode | operand
--
--                Data RAM (async read, sync write):
--                  - check the initial contents (RAM[0]=02, RAM[3]=0F)
--                  - write a value and read it back
--                  - confirm a write is blocked when Clock_Enable is low
--                  - confirm an asynchronous reset restores the initial values
--
--  Notes       : Expected ROM bytes come from the opcode encoding in
--                CPU_Package. For example OP_LOAD_IMMEDIATE = "0001", so
--                OP_LOAD_IMMEDIATE & "0011" = 0001_0011 = 0x13.
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Memory_Unit_tb is
end entity Memory_Unit_tb;

architecture bench of Memory_Unit_tb is

    constant CLK_PERIOD : time := 10 ns;

    signal Clock        : std_logic := '0';
    signal Reset        : std_logic := '1';
    signal Clock_Enable : std_logic := '0';

    signal Program_Select      : std_logic_vector(1 downto 0) := "00";
    signal Instruction_Address : std_logic_vector(3 downto 0) := (others => '0');
    signal Instruction_Out     : std_logic_vector(7 downto 0);

    signal RAM_Write_Enable : std_logic := '0';
    signal RAM_Address      : std_logic_vector(3 downto 0) := (others => '0');
    signal RAM_Data_In      : std_logic_vector(7 downto 0) := (others => '0');
    signal RAM_Data_Out     : std_logic_vector(7 downto 0);

    signal sim_done : boolean := false;

    procedure check (signal   Got      : in std_logic_vector(7 downto 0);
                     constant Expected : in std_logic_vector(7 downto 0);
                     constant Tag      : in string) is
    begin
        assert Got = Expected report Tag & " : value mismatch" severity error;
        if Got = Expected then
            report Tag & " PASS" severity note;
        end if;
    end procedure;

begin

    uut : entity work.Memory_Unit
        port map (
            Clock               => Clock,
            Reset               => Reset,
            Clock_Enable        => Clock_Enable,
            Program_Select      => Program_Select,
            Instruction_Address => Instruction_Address,
            Instruction_Out     => Instruction_Out,
            RAM_Write_Enable    => RAM_Write_Enable,
            RAM_Address         => RAM_Address,
            RAM_Data_In         => RAM_Data_In,
            RAM_Data_Out        => RAM_Data_Out
        );

    clock_gen : process
    begin
        while not sim_done loop
            Clock <= '0'; wait for CLK_PERIOD / 2;
            Clock <= '1'; wait for CLK_PERIOD / 2;
        end loop;
        wait;
    end process clock_gen;

    stimulus : process
    begin
        Reset <= '1'; Clock_Enable <= '0';
        wait for 12 ns;
        Reset <= '0';

        -- ---- Program ROM reads (purely combinational) ----
        -- Program 0, address 0 is LOAD_IMMEDIATE 3  ->  0x13
        Program_Select <= "00"; Instruction_Address <= x"0";
        wait for 5 ns; check(Instruction_Out, x"13", "rom_p0_addr0");

        -- Program 0, address 8 is HALT  ->  0xF0
        Instruction_Address <= x"8";
        wait for 5 ns; check(Instruction_Out, x"F0", "rom_p0_addr8");

        -- Program 1, address 0 is LOAD_IMMEDIATE F  ->  0x1F
        Program_Select <= "01"; Instruction_Address <= x"0";
        wait for 5 ns; check(Instruction_Out, x"1F", "rom_p1_addr0");

        -- ---- RAM initial contents ----
        -- The demo programs rely on these starting values.
        RAM_Address <= x"0";
        wait for 5 ns; check(RAM_Data_Out, x"02", "ram_initial_addr0");
        RAM_Address <= x"3";
        wait for 5 ns; check(RAM_Data_Out, x"0F", "ram_initial_addr3");

        -- ---- RAM write then read back ----
        -- Write 0xAB to address 5 with the enable on, then read it back.
        Clock_Enable <= '1';
        RAM_Address <= x"5"; RAM_Data_In <= x"AB"; RAM_Write_Enable <= '1';
        wait until rising_edge(Clock); wait for 1 ns;
        RAM_Write_Enable <= '0';
        wait for 2 ns; check(RAM_Data_Out, x"AB", "ram_write_then_read");

        -- ---- write must be ignored when Clock_Enable is low ----
        -- Address 6 should still read 00 because the write was gated out.
        Clock_Enable <= '0';
        RAM_Address <= x"6"; RAM_Data_In <= x"CC"; RAM_Write_Enable <= '1';
        wait until rising_edge(Clock); wait for 1 ns;
        RAM_Write_Enable <= '0';
        wait for 2 ns; check(RAM_Data_Out, x"00", "ram_write_gated_out");

        -- ---- asynchronous reset restores the initial RAM contents ----
        -- The 0xAB we wrote to address 5 should be wiped back to 00.
        Reset <= '1';
        wait for 5 ns;
        RAM_Address <= x"5";
        wait for 2 ns; check(RAM_Data_Out, x"00", "ram_reset_restores");
        Reset <= '0';

        report "Memory_Unit_tb finished." severity note;
        sim_done <= true;
        wait;
    end process stimulus;

end architecture bench;
