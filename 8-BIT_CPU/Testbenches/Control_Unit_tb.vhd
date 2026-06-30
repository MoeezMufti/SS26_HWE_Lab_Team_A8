-- =============================================================================
--  File        : Control_Unit_tb.vhd
--  Entity      : Control_Unit_tb
--  Project     : 8-bit CPU  (Digital Technology, SS 2026)
--  Description : Self-checking unit testbench for the Control_Unit FSM.
--                Walks the machine through fetch -> decode -> execute and
--                checks the control outputs in each state, the opcode decode
--                in execute, and the transition into the halt state.
--  Style       : Lecture testbench skeleton. state_debug is used as the
--                observable state code (0001 fetch, 0010 decode, 0011 execute,
--                1111 halt).
--  Notes       : Opcode constants come from CPU_Package.
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;

use work.CPU_Package.all;

entity Control_Unit_tb is
end entity;

architecture bench of Control_Unit_tb is

    constant CLK_PERIOD : time := 10 ns;

    signal clk          : std_logic := '0';
    signal rst          : std_logic := '1';
    signal clk_en       : std_logic := '0';
    signal opcode       : std_logic_vector(3 downto 0) := (others => '0');
    signal zero_flag    : std_logic := '0';
    signal carry_flag   : std_logic := '0';

    signal ir_load      : std_logic;
    signal pc_increment : std_logic;
    signal pc_load      : std_logic;
    signal acc_load     : std_logic;
    signal ram_write    : std_logic;
    signal output_load  : std_logic;
    signal halt_control : std_logic;
    signal state_debug  : std_logic_vector(3 downto 0);

    signal sim_done : boolean := false;

    procedure check_state (signal got : in std_logic_vector(3 downto 0);
                           expected : in std_logic_vector(3 downto 0);
                           tag : in string) is
    begin
        assert got = expected report tag & " : wrong state" severity error;
        if got = expected then
            report tag & " PASS" severity note;
        end if;
    end procedure;

    procedure check_bit (signal got : in std_logic;
                         expected : in std_logic; tag : in string) is
    begin
        assert got = expected report tag & " : wrong control bit" severity error;
        if got = expected then
            report tag & " PASS" severity note;
        end if;
    end procedure;

begin

    uut : entity work.Control_Unit
        port map (
            clk          => clk,
            rst          => rst,
            clk_en       => clk_en,
            opcode       => opcode,
            zero_flag    => zero_flag,
            carry_flag   => carry_flag,
            ir_load      => ir_load,
            pc_increment => pc_increment,
            pc_load      => pc_load,
            acc_load     => acc_load,
            ram_write    => ram_write,
            output_load  => output_load,
            halt_control => halt_control,
            state_debug  => state_debug
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
        -- reset -> fetch state, fetch raises ir_load and pc_increment
        rst <= '1'; clk_en <= '0';
        wait for 12 ns;
        check_state(state_debug, "0001", "fetch_state");
        check_bit(ir_load,      '1', "fetch_ir_load");
        check_bit(pc_increment, '1', "fetch_pc_inc");

        -- present an ADD opcode and start clocking
        rst <= '0'; clk_en <= '1'; opcode <= OP_ADD_MEMORY;

        -- fetch -> decode
        wait until rising_edge(clk); wait for 1 ns;
        check_state(state_debug, "0010", "decode_state");
        check_bit(acc_load, '0', "decode_no_accload");

        -- decode -> execute : ADD must assert acc_load
        wait until rising_edge(clk); wait for 1 ns;
        check_state(state_debug, "0011", "execute_state");
        check_bit(acc_load, '1', "execute_add_accload");

        -- execute -> fetch (non-halt opcode loops back)
        wait until rising_edge(clk); wait for 1 ns;
        check_state(state_debug, "0001", "back_to_fetch");

        -- now drive a STORE opcode through to execute and check ram_write
        opcode <= OP_STORE_MEMORY;
        wait until rising_edge(clk); wait for 1 ns;   -- decode
        wait until rising_edge(clk); wait for 1 ns;   -- execute
        check_bit(ram_write, '1', "execute_store_ramwrite");

        -- next, HALT : execute asserts halt_control and FSM enters halt state
        opcode <= OP_HALT;
        wait until rising_edge(clk); wait for 1 ns;   -- back to fetch
        wait until rising_edge(clk); wait for 1 ns;   -- decode
        wait until rising_edge(clk); wait for 1 ns;   -- execute (halt opcode)
        check_bit(halt_control, '1', "execute_halt_ctrl");
        wait until rising_edge(clk); wait for 1 ns;   -- enter halt state
        check_state(state_debug, "1111", "halt_state");

        report "Control_Unit_tb done." severity note;
        sim_done <= true;
        wait;
    end process;

end architecture;
