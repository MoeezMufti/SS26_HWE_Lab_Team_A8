library ieee;
use ieee.std_logic_1164.all;

entity Nexys_A7_Top is
    port (
        clk  : in  std_logic;
        sw   : in  std_logic_vector(15 downto 0);

        btnC : in  std_logic;
        btnU : in  std_logic;
        btnL : in  std_logic;
        btnR : in  std_logic;
        btnD : in  std_logic;

        led  : out std_logic_vector(15 downto 0);
        seg  : out std_logic_vector(6 downto 0);
        an   : out std_logic_vector(7 downto 0);
        dp   : out std_logic
    );
end entity;

architecture Structural of Nexys_A7_Top is

    signal Reset_Signal      : std_logic;
    signal Step_Pulse        : std_logic;
    signal Auto_Tick         : std_logic;
    signal CPU_Enable        : std_logic;

    signal Program_Select    : std_logic_vector(1 downto 0);

    signal Debug_PC          : std_logic_vector(3 downto 0);
    signal Debug_Instruction : std_logic_vector(7 downto 0);
    signal Debug_State       : std_logic_vector(3 downto 0);
    signal Debug_ACC         : std_logic_vector(7 downto 0);
    signal Debug_Output      : std_logic_vector(7 downto 0);
    signal Debug_RAM_Data    : std_logic_vector(7 downto 0);

    signal Zero_Flag         : std_logic;
    signal Carry_Flag        : std_logic;
    signal Overflow_Flag     : std_logic;
    signal Halted            : std_logic;

    signal Unused_Switch_Debug : std_logic;
    signal RAM_Debug_Activity  : std_logic;

begin

    Reset_Signal   <= btnD;
    Program_Select <= sw(13 downto 12);

    -- The full CPU only needs SW15, SW14, SW13, and SW12.
    -- SW0-SW11 are folded into a debug signal to avoid unused-port warnings.
    Unused_Switch_Debug <= sw(0) or sw(1) or sw(2) or sw(3) or
                           sw(4) or sw(5) or sw(6) or sw(7) or
                           sw(8) or sw(9) or sw(10) or sw(11);

    RAM_Debug_Activity <= Debug_RAM_Data(0) or Debug_RAM_Data(1) or
                          Debug_RAM_Data(2) or Debug_RAM_Data(3) or
                          Debug_RAM_Data(4) or Debug_RAM_Data(5) or
                          Debug_RAM_Data(6) or Debug_RAM_Data(7);

    Step_Button : entity work.Button_Debounce
        port map (
            Clock     => clk,
            Reset     => Reset_Signal,
            Button_In => btnC,
            Pulse_Out => Step_Pulse
        );

    Auto_Clock : entity work.Clock_Enable_Generator
        port map (
            Clock        => clk,
            Reset        => Reset_Signal,
            Speed_Select => sw(14),
            Tick_Out     => Auto_Tick
        );

    process(Step_Pulse, Auto_Tick, sw, Halted)
    begin
        if Halted = '1' then
            CPU_Enable <= '0';
        elsif sw(15) = '0' then
            CPU_Enable <= Step_Pulse;
        else
            CPU_Enable <= Auto_Tick;
        end if;
    end process;

    CPU : entity work.CPU_Top
        port map (
            Clock          => clk,
            Reset          => Reset_Signal,
            Clock_Enable   => CPU_Enable,
            Program_Select => Program_Select,

            Debug_PC          => Debug_PC,
            Debug_Instruction => Debug_Instruction,
            Debug_State       => Debug_State,
            Debug_ACC         => Debug_ACC,
            Debug_Output      => Debug_Output,
            Debug_RAM_Data    => Debug_RAM_Data,

            Zero_Flag     => Zero_Flag,
            Carry_Flag    => Carry_Flag,
            Overflow_Flag => Overflow_Flag,
            Halted        => Halted
        );

    led(7 downto 0)   <= Debug_ACC;
    led(11 downto 8)  <= Debug_PC;
    led(12)           <= Zero_Flag;
    led(13)           <= Carry_Flag;
    led(14)           <= Halted;

    -- LED15 is a combined debug LED. It also intentionally uses otherwise-unused
    -- buttons/switches/internal debug signals to keep synthesis warnings clean.
    led(15) <= CPU_Enable or Overflow_Flag or btnU or btnL or btnR or
               Unused_Switch_Debug or RAM_Debug_Activity;

    -- Seven-segment display, left to right:
    -- PC | OPCODE | OPERAND | STATE | ACC_H | ACC_L | OUT_H | OUT_L
    Display : entity work.Seven_Segment_Display
        port map (
            Clock => clk,

            Digit_0_Rightmost => Debug_Output(3 downto 0),
            Digit_1           => Debug_Output(7 downto 4),
            Digit_2           => Debug_ACC(3 downto 0),
            Digit_3           => Debug_ACC(7 downto 4),
            Digit_4           => Debug_State,
            Digit_5           => Debug_Instruction(3 downto 0),
            Digit_6           => Debug_Instruction(7 downto 4),
            Digit_7_Leftmost  => Debug_PC,

            Segment_Cathodes => seg,
            Digit_Anodes     => an,
            Decimal_Point    => dp
        );

end architecture;
