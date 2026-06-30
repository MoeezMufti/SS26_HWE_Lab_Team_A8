-- =============================================================================
--  File        : Control_Unit_tb.vhd
--  Entity      : Control_Unit_tb
--  Project     : 8-bit CPU  (Digital Technology, SS 2026)
--  Description : Unit testbench for the Control_Unit FSM.
--
--                The control unit is the "brain" that walks the CPU through
--                fetch -> decode -> execute (-> halt) and raises the right
--                control signals in each step. This testbench drives the clock
--                and the opcode by hand and checks:
--                  - after reset we are in FETCH, with IR_Load and PC_Increment
--                  - FETCH -> DECODE -> EXECUTE happen in order
--                  - in EXECUTE the opcode is decoded (ADD raises ACC_Load,
--                    STORE raises RAM_Write)
--                  - a HALT opcode moves the FSM into the HALT state, and only
--                    *there* is Halt_Control raised
--
--  Notes       : We observe the state through State_Debug:
--                  0001 = FETCH, 0010 = DECODE, 0011 = EXECUTE, 1111 = HALT.
--                Important: in this design HALT_Control is NOT raised during
--                EXECUTE - the execute step for a HALT opcode does nothing, and
--                Halt_Control only goes high one cycle later in the HALT state.
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;

use work.CPU_Package.all;          -- opcode constants (OP_ADD_MEMORY, OP_HALT, ...)

entity Control_Unit_tb is
end entity Control_Unit_tb;

architecture bench of Control_Unit_tb is

    constant CLK_PERIOD : time := 10 ns;

    signal Clock        : std_logic := '0';
    signal Reset        : std_logic := '1';
    signal Clock_Enable : std_logic := '0';
    signal Opcode       : std_logic_vector(3 downto 0) := (others => '0');
    signal Zero_Flag    : std_logic := '0';
    signal Carry_Flag   : std_logic := '0';

    signal IR_Load      : std_logic;
    signal PC_Increment : std_logic;
    signal PC_Load      : std_logic;
    signal ACC_Load     : std_logic;
    signal RAM_Write    : std_logic;
    signal Output_Load  : std_logic;
    signal Halt_Control : std_logic;
    signal State_Debug  : std_logic_vector(3 downto 0);

    signal sim_done : boolean := false;

    -- Check the FSM state via its debug code.
    procedure check_state (signal   Got      : in std_logic_vector(3 downto 0);
                           constant Expected : in std_logic_vector(3 downto 0);
                           constant Tag      : in string) is
    begin
        assert Got = Expected report Tag & " : wrong state code" severity error;
        if Got = Expected then
            report Tag & " PASS" severity note;
        end if;
    end procedure;

    -- Check a single control output bit.
    procedure check_bit (signal   Got      : in std_logic;
                         constant Expected : in std_logic;
                         constant Tag      : in string) is
    begin
        assert Got = Expected report Tag & " : wrong control bit" severity error;
        if Got = Expected then
            report Tag & " PASS" severity note;
        end if;
    end procedure;

begin

    uut : entity work.Control_Unit
        port map (
            Clock        => Clock,
            Reset        => Reset,
            Clock_Enable => Clock_Enable,
            Opcode       => Opcode,
            Zero_Flag    => Zero_Flag,
            Carry_Flag   => Carry_Flag,
            IR_Load      => IR_Load,
            PC_Increment => PC_Increment,
            PC_Load      => PC_Load,
            ACC_Load     => ACC_Load,
            RAM_Write    => RAM_Write,
            Output_Load  => Output_Load,
            Halt_Control => Halt_Control,
            State_Debug  => State_Debug
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
        -- After reset the FSM sits in FETCH. Fetch is where the instruction is
        -- latched and the PC is bumped, so both of those control bits are high.
        Reset <= '1'; Clock_Enable <= '0';
        wait for 12 ns;
        check_state(State_Debug, "0001", "fetch_state");
        check_bit(IR_Load,      '1', "fetch_raises_IR_Load");
        check_bit(PC_Increment, '1', "fetch_raises_PC_Increment");

        -- Present an ADD opcode and start clocking the machine.
        Reset <= '0'; Clock_Enable <= '1'; Opcode <= OP_ADD_MEMORY;

        -- FETCH -> DECODE. Decode is a settle step, so no datapath bit yet.
        wait until rising_edge(Clock); wait for 1 ns;
        check_state(State_Debug, "0010", "decode_state");
        check_bit(ACC_Load, '0', "decode_no_ACC_Load");

        -- DECODE -> EXECUTE. ADD must now raise ACC_Load.
        wait until rising_edge(Clock); wait for 1 ns;
        check_state(State_Debug, "0011", "execute_state");
        check_bit(ACC_Load, '1', "execute_ADD_raises_ACC_Load");

        -- EXECUTE -> FETCH (any non-halt opcode loops back to fetch).
        wait until rising_edge(Clock); wait for 1 ns;
        check_state(State_Debug, "0001", "loops_back_to_fetch");

        -- Now push a STORE opcode through to execute and check RAM_Write.
        Opcode <= OP_STORE_MEMORY;
        wait until rising_edge(Clock); wait for 1 ns;   -- decode
        wait until rising_edge(Clock); wait for 1 ns;   -- execute
        check_bit(RAM_Write, '1', "execute_STORE_raises_RAM_Write");

        -- Finally, a HALT. First get back to fetch, then run it through.
        wait until rising_edge(Clock); wait for 1 ns;   -- execute(store) -> fetch
        Opcode <= OP_HALT;
        wait until rising_edge(Clock); wait for 1 ns;   -- fetch -> decode
        wait until rising_edge(Clock); wait for 1 ns;   -- decode -> execute

        -- In execute the HALT opcode does nothing, so Halt_Control is still low.
        check_state(State_Debug, "0011", "halt_in_execute_state");
        check_bit(Halt_Control, '0', "halt_not_raised_in_execute");

        -- One more clock moves us into the HALT state, where Halt_Control = '1'.
        wait until rising_edge(Clock); wait for 1 ns;
        check_state(State_Debug, "1111", "halt_state");
        check_bit(Halt_Control, '1', "halt_raised_in_halt_state");

        report "Control_Unit_tb finished." severity note;
        sim_done <= true;
        wait;
    end process stimulus;

end architecture bench;
