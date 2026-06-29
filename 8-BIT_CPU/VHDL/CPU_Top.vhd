library ieee;
use ieee.std_logic_1164.all;

use work.CPU_Package.all;

entity CPU_Top is
    port (
        Clock          : in  std_logic;
        Reset          : in  std_logic;
        Clock_Enable   : in  std_logic;
        Program_Select : in  std_logic_vector(1 downto 0);

        Debug_PC          : out std_logic_vector(3 downto 0);
        Debug_Instruction : out std_logic_vector(7 downto 0);
        Debug_State       : out std_logic_vector(3 downto 0);
        Debug_ACC         : out std_logic_vector(7 downto 0);
        Debug_Output      : out std_logic_vector(7 downto 0);
        Debug_RAM_Data    : out std_logic_vector(7 downto 0);

        Zero_Flag     : out std_logic;
        Carry_Flag    : out std_logic;
        Overflow_Flag : out std_logic;
        Halted        : out std_logic
    );
end entity;

architecture Structural of CPU_Top is

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

    signal IR_Load         : std_logic;
    signal PC_Increment    : std_logic;
    signal PC_Load         : std_logic;
    signal ACC_Load        : std_logic;
    signal RAM_Write       : std_logic;
    signal Output_Load     : std_logic;
    signal Halt_Control    : std_logic;

    signal ALU_Zero        : std_logic;
    signal ALU_Carry       : std_logic;
    signal ALU_Overflow    : std_logic;

    signal Zero_Register     : std_logic := '1';
    signal Carry_Register    : std_logic := '0';
    signal Overflow_Register : std_logic := '0';
    signal Halted_Register   : std_logic := '0';

begin

    Opcode  <= Instruction_Reg(7 downto 4);
    Operand <= Instruction_Reg(3 downto 0);

    ALU_Input_B <= "0000" & Operand when Opcode = OP_LOAD_IMMEDIATE else RAM_Data_Out;

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

    IR_Block : entity work.Instruction_Register
        port map (
            Clock           => Clock,
            Reset           => Reset,
            Clock_Enable    => Clock_Enable,
            Load_Enable     => IR_Load,
            Instruction_In  => Instruction_ROM,
            Instruction_Out => Instruction_Reg
        );

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

    ACC_Block : entity work.Accumulator
        port map (
            Clock        => Clock,
            Reset        => Reset,
            Clock_Enable => Clock_Enable,
            Load_Enable  => ACC_Load,
            Data_In      => ALU_Result,
            Data_Out     => ACC_Value
        );

    process(Clock)
    begin
        if rising_edge(Clock) then
            if Reset = '1' then
                Output_Register  <= (others => '0');
                Zero_Register     <= '1';
                Carry_Register    <= '0';
                Overflow_Register <= '0';
                Halted_Register   <= '0';
            elsif Clock_Enable = '1' then
                if ACC_Load = '1' then
                    Zero_Register     <= ALU_Zero;
                    Carry_Register    <= ALU_Carry;
                    Overflow_Register <= ALU_Overflow;
                end if;

                if Output_Load = '1' then
                    Output_Register <= ACC_Value;
                end if;

                if Halt_Control = '1' then
                    Halted_Register <= '1';
                end if;
            end if;
        end if;
    end process;

    Debug_PC          <= PC_Value;
    Debug_Instruction <= Instruction_Reg;
    Debug_ACC         <= ACC_Value;
    Debug_Output      <= Output_Register;
    Debug_RAM_Data    <= RAM_Data_Out;

    Zero_Flag     <= Zero_Register;
    Carry_Flag    <= Carry_Register;
    Overflow_Flag <= Overflow_Register;
    Halted        <= Halted_Register;

end architecture;
