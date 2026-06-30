-- =============================================================================
--  File        : Memory_Unit_tb.vhd
--  Entity      : Memory_Unit_tb
--  Project     : 8-bit CPU  (Digital Technology, SS 2026)
--  Description : Self-checking unit testbench for the Memory_Unit.
--                Checks: ROM reads for the selected program (combinational),
--                RAM initial contents, a RAM write/read-back, the clk_en gate
--                on writes, and that asynchronous reset restores the RAM init.
--  Style       : Lecture testbench skeleton.
--  Notes       : Expected ROM words are derived from the opcode encoding in
--                CPU_Package, e.g. OP_LOAD_IMMEDIATE & "0011" = 0x13,
--                OP_HALT & "0000" = 0xF0.
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Memory_Unit_tb is
end entity;

architecture bench of Memory_Unit_tb is

    constant CLK_PERIOD : time := 10 ns;

    signal clk    : std_logic := '0';
    signal rst    : std_logic := '1';
    signal clk_en : std_logic := '0';

    signal program_select      : std_logic_vector(1 downto 0) := "00";
    signal instruction_address : std_logic_vector(3 downto 0) := (others => '0');
    signal instruction_out     : std_logic_vector(7 downto 0);

    signal ram_write_enable : std_logic := '0';
    signal ram_address      : std_logic_vector(3 downto 0) := (others => '0');
    signal ram_data_in      : std_logic_vector(7 downto 0) := (others => '0');
    signal ram_data_out     : std_logic_vector(7 downto 0);

    signal sim_done : boolean := false;

    procedure check (signal got : in std_logic_vector(7 downto 0);
                     expected : in std_logic_vector(7 downto 0);
                     tag : in string) is
    begin
        assert got = expected report tag & " : mismatch" severity error;
        if got = expected then
            report tag & " PASS" severity note;
        end if;
    end procedure;

begin

    uut : entity work.Memory_Unit
        port map (
            clk                 => clk,
            rst                 => rst,
            clk_en              => clk_en,
            program_select      => program_select,
            instruction_address => instruction_address,
            instruction_out     => instruction_out,
            ram_write_enable    => ram_write_enable,
            ram_address         => ram_address,
            ram_data_in         => ram_data_in,
            ram_data_out        => ram_data_out
        );

    clock_gen : process
    begin
        while not sim_done loop
            clk <= '0'; wait for CLK_PERIOD / 2;
            clk <= '1'; wait for CLK_PERIOD / 2;
        end loop;
        wait;
    end process;

    stimulus : process
    begin
        rst <= '1'; clk_en <= '0';
        wait for 12 ns;
        rst <= '0';

        -- ---- ROM reads (combinational) ----
        -- Program 0, address 0 : OP_LOAD_IMMEDIATE & "0011" = 0x13
        program_select <= "00"; instruction_address <= x"0";
        wait for 5 ns; check(instruction_out, x"13", "rom_p0_a0");

        -- Program 0, address 8 : OP_HALT & "0000" = 0xF0
        instruction_address <= x"8";
        wait for 5 ns; check(instruction_out, x"F0", "rom_p0_a8");

        -- Program 1, address 0 : OP_LOAD_IMMEDIATE & "1011" = 0x1B
        program_select <= "01"; instruction_address <= x"0";
        wait for 5 ns; check(instruction_out, x"1B", "rom_p1_a0");

        -- ---- RAM initial contents ----
        -- RAM(0) initialises to 0x02
        ram_address <= x"0";
        wait for 5 ns; check(ram_data_out, x"02", "ram_init0");
        -- RAM(3) initialises to 0x0F
        ram_address <= x"3";
        wait for 5 ns; check(ram_data_out, x"0F", "ram_init3");

        -- ---- RAM write then read back ----
        clk_en <= '1';
        ram_address <= x"5"; ram_data_in <= x"AB"; ram_write_enable <= '1';
        wait until rising_edge(clk); wait for 1 ns;
        ram_write_enable <= '0';
        wait for 2 ns; check(ram_data_out, x"AB", "ram_write5");

        -- ---- write must be blocked when clk_en = '0' ----
        clk_en <= '0';
        ram_address <= x"6"; ram_data_in <= x"CC"; ram_write_enable <= '1';
        wait until rising_edge(clk); wait for 1 ns;
        ram_write_enable <= '0';
        wait for 2 ns; check(ram_data_out, x"00", "ram_gated6");

        -- ---- asynchronous reset restores the init contents ----
        rst <= '1';
        wait for 5 ns;
        ram_address <= x"5";
        wait for 2 ns; check(ram_data_out, x"00", "ram_reset5");
        rst <= '0';

        report "Memory_Unit_tb done." severity note;
        sim_done <= true;
        wait;
    end process;

end architecture;
