-- =============================================================================
--  File        : Control_Unit.vhd
--  Entity      : Control_Unit
--  Project     : 8-bit CPU  (Digital Technology, SS 2026)
--  Description : Finite-State Machine that sequences the CPU through
--                fetch -> decode -> execute (-> halt). In each state it raises
--                the control signals (IR load, PC increment/load, ACC load,
--                RAM write, output load, halt) that steer the datapath.
--  Style       : Two-process FSM (lecture "Two-process method": one
--                synchronous process for the state memory, one combinational
--                process for the outputs).
--                  - state_memory : process(clk, rst), async reset, sync enable
--                  - output_logic : process(current_state, opcode, flags)
--                Enumerated state type cpu_state_type comes from CPU_Package.
--  Notes       : Moore-style next state; jump decisions in execute use the
--                zero / carry flags. state_debug exposes the state for the
--                dashboard.
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;

use work.CPU_Package.all;          -- cpu_state_type + OP_* constants

entity Control_Unit is
    port (
        clk          : in  std_logic;
        rst          : in  std_logic;
        clk_en       : in  std_logic;

        opcode       : in  std_logic_vector(3 downto 0);
        zero_flag    : in  std_logic;
        carry_flag   : in  std_logic;

        ir_load      : out std_logic;
        pc_increment : out std_logic;
        pc_load      : out std_logic;
        acc_load     : out std_logic;
        ram_write    : out std_logic;
        output_load  : out std_logic;
        halt_control : out std_logic;
        state_debug  : out std_logic_vector(3 downto 0)
    );
end entity;

architecture behavioral of Control_Unit is

    -- only the current state is stored (next state is computed inline below)
    signal current_state : cpu_state_type;

begin

    -- ----------------------------------------------------------------------
    -- Process 1 : State memory (synchronous)
    -- Advances fetch -> decode -> execute -> fetch, or to halt on OP_HALT.
    -- Asynchronous reset, synchronous enable.
    -- ----------------------------------------------------------------------
    state_memory : process(clk, rst)
    begin
        if rst = '1' then                              -- asynchronous reset
            current_state <= st_fetch;
        elsif rising_edge(clk) then
            if clk_en = '1' then                       -- synchronous enable
                case current_state is
                    when st_fetch =>
                        current_state <= st_decode;
                    when st_decode =>
                        current_state <= st_execute;
                    when st_execute =>
                        if opcode = OP_HALT then
                            current_state <= st_halt;
                        else
                            current_state <= st_fetch;
                        end if;
                    when st_halt =>
                        current_state <= st_halt;      -- stay halted
                end case;
            end if;
        end if;
    end process;

    -- ----------------------------------------------------------------------
    -- Process 2 : Output logic (combinational)
    -- All outputs are defaulted to '0' first, then the active state / opcode
    -- raises the ones it needs. Defaulting everything avoids latches.
    -- ----------------------------------------------------------------------
    output_logic : process(current_state, opcode, zero_flag, carry_flag)
    begin
        -- default assignments
        ir_load      <= '0';
        pc_increment <= '0';
        pc_load      <= '0';
        acc_load     <= '0';
        ram_write    <= '0';
        output_load  <= '0';
        halt_control <= '0';
        state_debug  <= "0000";

        case current_state is

            when st_fetch =>
                ir_load      <= '1';                   -- latch instruction
                pc_increment <= '1';                   -- point at next word
                state_debug  <= "0001";

            when st_decode =>
                state_debug  <= "0010";                -- just settle

            when st_execute =>
                state_debug  <= "0011";

                -- decode the opcode and assert the matching datapath control
                case opcode is
                    when OP_LOAD_IMMEDIATE =>
                        acc_load <= '1';
                    when OP_LOAD_MEMORY =>
                        acc_load <= '1';
                    when OP_STORE_MEMORY =>
                        ram_write <= '1';
                    when OP_ADD_MEMORY =>
                        acc_load <= '1';
                    when OP_SUB_MEMORY =>
                        acc_load <= '1';
                    when OP_AND_MEMORY =>
                        acc_load <= '1';
                    when OP_OR_MEMORY =>
                        acc_load <= '1';
                    when OP_XOR_MEMORY =>
                        acc_load <= '1';
                    when OP_NOT_ACC =>
                        acc_load <= '1';
                    when OP_JUMP =>
                        pc_load <= '1';
                    when OP_JUMP_IF_ZERO =>
                        if zero_flag = '1' then
                            pc_load <= '1';
                        end if;
                    when OP_JUMP_IF_CARRY =>
                        if carry_flag = '1' then
                            pc_load <= '1';
                        end if;
                    when OP_OUT =>
                        output_load <= '1';
                    when OP_CLEAR =>
                        acc_load <= '1';
                    when OP_HALT =>
                        halt_control <= '1';
                    when others =>
                        null;                          -- NOP and unused codes
                end case;

            when st_halt =>
                halt_control <= '1';
                state_debug  <= "1111";

        end case;
    end process;

end architecture;
