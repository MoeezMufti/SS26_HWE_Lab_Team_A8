-- =============================================================================
--  File        : CPU_Top.vhd
--  Entity      : CPU_Top
--  Project     : 8-bit CPU  (Digital Technology, SS 2026)
--  Description : Structural top level of the CPU core.
--                This file connects the CPU datapath and control blocks:
--                program counter, memory unit, instruction register,
--                control unit, ALU, and accumulator.
--
--  Notes       : This is not the FPGA board top level.
--                It is the CPU core top level.
--                Nexys_A7_Top.vhd connects this CPU to switches, buttons,
--                LEDs, and seven-segment displays.
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;

use work.CPU_Package.all;

entity CPU_Top is
    port (
        Clock             : in  std_logic;
        Reset             : in  std_logic;
        Clock_Enable      : in  std_logic;

        Program_Select    : in  std_logic_vector(1 downto 0);

        Debug_PC          : out std_logic_vector(3 downto 0);
        Debug_Instruction : out std_logic_vector(7 downto 0);
        Debug_State       : out std_logic_vector(3 downto 0);
        Debug_ACC         : out std_logic_vector(7 downto 0);
        Debug_Output      : out std_logic_vector(7 downto 0);
        Debug_RAM_Data    : out std_logic_vector(7 downto 0);

        Zero_Flag         : out std_logic;
        Carry_Flag        : out std_logic;
        Overflow_Flag     : out std_logic;
        Halted            : out std_logic
    );
end entity CPU_Top;

architecture Structural of CPU_Top is

    -- Datapath signals
    signal PC_Value        : std_logic_vector(3 downto 0);
    signal Instruction_ROM : std_logic_vector(7 downto 0);
    signal Instruction_Reg : std_logic_vector(7 downto 0);

    signal Opcode          : std_logic_vector(3 downto 0);
    signal Operand         : std_logic_vector(3 downto 0);

    signal ACC_Value       : std_logic_vector(7 downto 0);
    signal ALU_Input_B     : std_logic_vector(7 downto 0);
    signal ALU_Result      : std_logic_vector(7 downto 0);

    signal RAM_Data_Out    : std_logic_vector(7 downto 0);
    signal Output_Register : std_logic_vector(7 downto 0) := (others => '0');

    -- Control signals from the control unit
    signal IR_Load         : std_logic;
    signal PC_Increment    : std_logic;
    signal PC_Load         : std_logic;
    signal ACC_Load        : std_logic;
    signal RAM_Write       : std_logic;
    signal Output_Load     : std_logic;
    signal Halt_Control    : std_logic;

    -- ALU flag outputs
    signal ALU_Zero        : std_logic;
    signal ALU_Carry       : std_logic;
    signal ALU_Overflow    : std_logic;

    -- Stored CPU flags
    signal Zero_Register     : std_logic := '1';
    signal Carry_Register    : std_logic := '0';
    signal Overflow_Register : std_logic := '0';

begin

    -- -------------------------------------------------------------------------
    -- Instruction decode
    --
    -- The instruction register holds one 8-bit instruction.
    -- Upper 4 bits are the opcode.
    -- Lower 4 bits are the operand/address.
    -- -------------------------------------------------------------------------
    Opcode  <= Instruction_Reg(7 downto 4);
    Operand <= Instruction_Reg(3 downto 0);


    -- -------------------------------------------------------------------------
    -- ALU input selection
    --
    -- For LOAD_IMMEDIATE, the 4-bit operand is extended to 8 bits.
    -- For memory-based instructions, Input_B comes from RAM.
    -- -------------------------------------------------------------------------
    ALU_Input_B <= "0000" & Operand when Opcode = OP_LOAD_IMMEDIATE else
                   RAM_Data_Out;


    -- -------------------------------------------------------------------------
    -- Program Counter
    -- Stores the address of the current instruction.
    -- -------------------------------------------------------------------------
    PC_Block : entity work.Program_Counter
        port map (
            Clock        => Clock,
            Reset        => Reset,
            Clock_Enable => Clock_Enable,
            Increment    => PC_Increment,
            Load_Enable  => PC_Load,
            Load_Value   => Operand,
            Count_Out    => PC_Value
        );


    -- -------------------------------------------------------------------------
    -- Memory Unit
    -- Contains program ROM and data RAM.
    -- -------------------------------------------------------------------------
    Memory_Block : entity work.Memory_Unit
        port map (
            Clock               => Clock,
            Reset               => Reset,
            Clock_Enable        => Clock_Enable,
            Program_Select      => Program_Select,
            Instruction_Address => PC_Value,
            Instruction_Out     => Instruction_ROM,
            RAM_Write_Enable    => RAM_Write,
            RAM_Address         => Operand,
            RAM_Data_In         => ACC_Value,
            RAM_Data_Out        => RAM_Data_Out
        );


    -- -------------------------------------------------------------------------
    -- Instruction Register
    -- Stores the instruction fetched from program ROM.
    -- -------------------------------------------------------------------------
    IR_Block : entity work.Instruction_Register
        port map (
            Clock           => Clock,
            Reset           => Reset,
            Clock_Enable    => Clock_Enable,
            Load_Enable     => IR_Load,
            Instruction_In  => Instruction_ROM,
            Instruction_Out => Instruction_Reg
        );


    -- -------------------------------------------------------------------------
    -- Control Unit
    -- FSM that generates the control signals for the CPU.
    -- -------------------------------------------------------------------------
    Control_Block : entity work.Control_Unit
        port map (
            Clock        => Clock,
            Reset        => Reset,
            Clock_Enable => Clock_Enable,
            Opcode       => Opcode,
            Zero_Flag    => Zero_Register,
            Carry_Flag   => Carry_Register,
            IR_Load      => IR_Load,
            PC_Increment => PC_Increment,
            PC_Load      => PC_Load,
            ACC_Load     => ACC_Load,
            RAM_Write    => RAM_Write,
            Output_Load  => Output_Load,
            Halt_Control => Halt_Control,
            State_Debug  => Debug_State
        );


    -- -------------------------------------------------------------------------
    -- ALU
    -- Combinational block that calculates arithmetic/logic results.
    -- -------------------------------------------------------------------------
    ALU_Block : entity work.ALU
        port map (
            Input_A       => ACC_Value,
            Input_B       => ALU_Input_B,
            Opcode        => Opcode,
            Result        => ALU_Result,
            Carry_Flag    => ALU_Carry,
            Zero_Flag     => ALU_Zero,
            Overflow_Flag => ALU_Overflow
        );


    -- -------------------------------------------------------------------------
    -- Accumulator
    -- Stores the ALU result when ACC_Load is active.
    -- -------------------------------------------------------------------------
    ACC_Block : entity work.Accumulator
        port map (
            Clock        => Clock,
            Reset        => Reset,
            Clock_Enable => Clock_Enable,
            Load_Enable  => ACC_Load,
            Data_In      => ALU_Result,
            Data_Out     => ACC_Value
        );


    -- -------------------------------------------------------------------------
    -- Output and flag registers
    --
    -- Output_Register stores the value sent out by the OP_OUT instruction.
    -- Flags are stored only when the accumulator loads a new ALU result.
    -- Reset is asynchronous.
    -- -------------------------------------------------------------------------
    status_registers : process(Clock, Reset)
    begin
        if Reset = '1' then
            Output_Register  <= (others => '0');
            Zero_Register    <= '1';
            Carry_Register   <= '0';
            Overflow_Register <= '0';

        elsif rising_edge(Clock) then
            if Clock_Enable = '1' then

                if ACC_Load = '1' then
                    Zero_Register     <= ALU_Zero;
                    Carry_Register    <= ALU_Carry;
                    Overflow_Register <= ALU_Overflow;
                end if;

                if Output_Load = '1' then
                    Output_Register <= ACC_Value;
                end if;

            end if;
        end if;
    end process status_registers;


    -- -------------------------------------------------------------------------
    -- Debug outputs
    -- These go to the FPGA board top level for LEDs / seven-segment display.
    -- -------------------------------------------------------------------------
    Debug_PC          <= PC_Value;
    Debug_Instruction <= Instruction_Reg;
    Debug_ACC         <= ACC_Value;
    Debug_Output      <= Output_Register;
    Debug_RAM_Data    <= RAM_Data_Out;

    Zero_Flag         <= Zero_Register;
    Carry_Flag        <= Carry_Register;
    Overflow_Flag     <= Overflow_Register;

    -- Halted is directly driven by the control unit halt state.
    Halted            <= Halt_Control;

end architecture Structural;
