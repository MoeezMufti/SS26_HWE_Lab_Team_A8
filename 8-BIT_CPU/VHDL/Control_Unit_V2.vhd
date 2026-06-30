-- =============================================================================
--  File        : Control_Unit.vhd
--  Entity      : Control_Unit
--  Project     : 8-bit CPU  (Digital Technology, SS 2026)
--  Description : Finite-State Machine that sequences the CPU through
--                fetch -> decode -> execute -> halt. In each state it raises
--                the control signals (IR load, PC increment/load, ACC load,
--                RAM write, output load, halt) that steer the datapath.
--
--  Style       : Two-process FSM:
--                  1) state_memory : sequential process for the state register
--                     - asynchronous reset
--                     - synchronous clock enable
--                  2) output_logic : combinational process for control outputs
--
--  Notes       : State transitions follow the fetch/decode/execute/halt cycle.
--                Datapath control outputs are decoded from the current state,
--                opcode, and flags. Conditional jumps use zero/carry flags.
--                state_debug exposes the state for the seven-segment dashboard.
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;

use work.CPU_Package.all;          -- CPU_State_Type + OP_* constants

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
end entity Control_Unit;

architecture behavioral of Control_Unit is

    -- Only the current state is stored.
    -- The state type and state names come from CPU_Package.vhd.
    signal current_state : CPU_State_Type;

begin

    -- -------------------------------------------------------------------------
    -- Process 1: State memory
    --
    -- This process stores the current FSM state.
    -- Reset is asynchronous because it is checked before the clock edge.
    -- Normal state changes are synchronous because they happen only on
    -- rising_edge(clk), and only when clk_en = '1'.
    -- -------------------------------------------------------------------------
    state_memory : process(clk, rst)
    begin
        if rst = '1' then
            current_state <= STATE_FETCH;

        elsif rising_edge(clk) then
            if clk_en = '1' then

                case current_state is

                    when STATE_FETCH =>
                        current_state <= STATE_DECODE;

                    when STATE_DECODE =>
                        current_state <= STATE_EXECUTE;

                    when STATE_EXECUTE =>
                        if opcode = OP_HALT then
                            current_state <= STATE_HALT;
                        else
                            current_state <= STATE_FETCH;
                        end if;

                    when STATE_HALT =>
                        current_state <= STATE_HALT;

                end case;

            end if;
        end if;
    end process state_memory;


    -- -------------------------------------------------------------------------
    -- Process 2: Output logic
    --
    -- This is combinational logic.
    -- All outputs are first assigned safe default values.
    -- Then the active state/opcode raises only the required control signals.
    -- Defaulting all outputs helps avoid inferred latches.
    -- -------------------------------------------------------------------------
    output_logic : process(current_state, opcode, zero_flag, carry_flag)
    begin
        -- Default assignments
        ir_load      <= '0';
        pc_increment <= '0';
        pc_load      <= '0';
        acc_load     <= '0';
        ram_write    <= '0';
        output_load  <= '0';
        halt_control <= '0';
        state_debug  <= "0000";

        case current_state is

            when STATE_FETCH =>
                ir_load      <= '1';       -- Load instruction into instruction register
                pc_increment <= '1';       -- Move PC to the next instruction address
                state_debug  <= "0001";    -- Display 1 = FETCH

            when STATE_DECODE =>
                state_debug  <= "0010";    -- Display 2 = DECODE

            when STATE_EXECUTE =>
                state_debug  <= "0011";    -- Display 3 = EXECUTE

                -- Decode opcode and activate the required datapath control signal.
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
                        null;              -- FSM moves to STATE_HALT; halt_control is raised there

                    when others =>
                        null;              -- NOP and unused opcodes

                end case;

            when STATE_HALT =>
                halt_control <= '1';       -- Stop CPU after the halt state is reached
                state_debug  <= "1111";    -- Display F = HALT

        end case;
    end process output_logic;

end architecture behavioral;
