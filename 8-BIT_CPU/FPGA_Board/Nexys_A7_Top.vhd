-- =============================================================================
--  File        : Nexys_A7_Top.vhd
--  Entity      : Nexys_A7_Top
--  Project     : 8-bit CPU  (Digital Technology, SS 2026)
--  Description : FPGA board top level for the Nexys A7.
--                This file connects the CPU core to physical board inputs
--                and outputs: switches, buttons, LEDs, and seven-segment display.
--
--  Board usage :
--                BTN_D       = reset
--                BTN_C       = manual step button
--                SW15        = mode select: 0 manual, 1 automatic
--                SW14        = automatic clock speed select
--                SW13-SW12   = program select
--
--  Display     : Seven-segment display shows, from left to right:
--                PC | OPCODE | OPERAND | STATE | ACC_H | ACC_L | OUT_H | OUT_L
-- =============================================================================

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
end entity Nexys_A7_Top;

architecture Structural of Nexys_A7_Top is

    -- Board/control signals
    signal Reset_Signal        : std_logic;
    signal Step_Pulse          : std_logic;
    signal Auto_Tick           : std_logic;
    signal CPU_Enable          : std_logic;
    signal Program_Select      : std_logic_vector(1 downto 0);

    -- CPU debug signals
    signal Debug_PC            : std_logic_vector(3 downto 0);
    signal Debug_Instruction   : std_logic_vector(7 downto 0);
    signal Debug_State         : std_logic_vector(3 downto 0);
    signal Debug_ACC           : std_logic_vector(7 downto 0);
    signal Debug_Output        : std_logic_vector(7 downto 0);
    signal Debug_RAM_Data      : std_logic_vector(7 downto 0);

    -- CPU status flags
    signal Zero_Flag           : std_logic;
    signal Carry_Flag          : std_logic;
    signal Overflow_Flag       : std_logic;
    signal Halted              : std_logic;

    -- Debug/tie-off signals
    signal Unused_Switch_Debug : std_logic;
    signal RAM_Debug_Activity  : std_logic;

begin

    -- -------------------------------------------------------------------------
    -- Board input mapping
    -- -------------------------------------------------------------------------

    -- BTN_D is used as reset.
    Reset_Signal <= btnD;

    -- SW13 and SW12 select which program is active.
    Program_Select <= sw(13 downto 12);

    -- The CPU only needs SW15, SW14, SW13, and SW12.
    -- SW0-SW11 are folded into a debug signal so Vivado does not warn that
    -- these input ports have no load.
    Unused_Switch_Debug <= sw(0)  or sw(1)  or sw(2)  or sw(3)  or
                           sw(4)  or sw(5)  or sw(6)  or sw(7)  or
                           sw(8)  or sw(9)  or sw(10) or sw(11);

    -- This debug signal shows whether any bit of RAM debug data is active.
    RAM_Debug_Activity <= Debug_RAM_Data(0) or Debug_RAM_Data(1) or
                          Debug_RAM_Data(2) or Debug_RAM_Data(3) or
                          Debug_RAM_Data(4) or Debug_RAM_Data(5) or
                          Debug_RAM_Data(6) or Debug_RAM_Data(7);


    -- -------------------------------------------------------------------------
    -- Manual step button
    --
    -- BTN_C is passed through a debounce block.
    -- The output Step_Pulse gives one clean pulse for manual stepping.
    -- -------------------------------------------------------------------------
    Step_Button : entity work.Button_Debounce
        port map (
            Clock     => clk,
            Reset     => Reset_Signal,
            Button_In => btnC,
            Pulse_Out => Step_Pulse
        );


    -- -------------------------------------------------------------------------
    -- Automatic clock enable generator
    --
    -- This does not replace the FPGA clock.
    -- It creates a slower enable pulse used to step the CPU automatically.
    -- SW14 selects the speed.
    -- -------------------------------------------------------------------------
    Auto_Clock : entity work.Clock_Enable_Generator
        port map (
            Clock        => clk,
            Reset        => Reset_Signal,
            Speed_Select => sw(14),
            Tick_Out     => Auto_Tick
        );


    -- -------------------------------------------------------------------------
    -- CPU enable selection
    --
    -- SW15 = 0: manual mode, CPU advances using Step_Pulse from BTN_C.
    -- SW15 = 1: automatic mode, CPU advances using Auto_Tick.
    -- If the CPU is halted, CPU_Enable is forced to 0.
    -- -------------------------------------------------------------------------
    cpu_enable_logic : process(Step_Pulse, Auto_Tick, sw, Halted)
    begin
        if Halted = '1' then
            CPU_Enable <= '0';

        elsif sw(15) = '0' then
            CPU_Enable <= Step_Pulse;

        else
            CPU_Enable <= Auto_Tick;

        end if;
    end process cpu_enable_logic;


    -- -------------------------------------------------------------------------
    -- CPU core
    --
    -- CPU_Top contains the actual CPU:
    -- program counter, memory, instruction register, control unit, ALU,
    -- accumulator, output register, and flags.
    -- -------------------------------------------------------------------------
    CPU : entity work.CPU_Top
        port map (
            Clock             => clk,
            Reset             => Reset_Signal,
            Clock_Enable      => CPU_Enable,

            Program_Select    => Program_Select,

            Debug_PC          => Debug_PC,
            Debug_Instruction => Debug_Instruction,
            Debug_State       => Debug_State,
            Debug_ACC         => Debug_ACC,
            Debug_Output      => Debug_Output,
            Debug_RAM_Data    => Debug_RAM_Data,

            Zero_Flag         => Zero_Flag,
            Carry_Flag        => Carry_Flag,
            Overflow_Flag     => Overflow_Flag,
            Halted            => Halted
        );


    -- -------------------------------------------------------------------------
    -- LED debug output
    -- -------------------------------------------------------------------------

    led(7 downto 0)  <= Debug_ACC;
    led(11 downto 8) <= Debug_PC;
    led(12)          <= Zero_Flag;
    led(13)          <= Carry_Flag;
    led(14)          <= Halted;

    -- LED15 is a combined debug/activity LED.
    -- It also intentionally uses otherwise-unused buttons/switches/internal
    -- debug signals to keep synthesis warnings clean.
    led(15) <= CPU_Enable or Overflow_Flag or btnU or btnL or btnR or
               Unused_Switch_Debug or RAM_Debug_Activity;


    -- -------------------------------------------------------------------------
    -- Seven-segment dashboard
    --
    -- The display shows, from left to right:
    --
    --   PC | OPCODE | OPERAND | STATE | ACC_H | ACC_L | OUT_H | OUT_L
    --
    -- Because the Nexys A7 display has 8 digits, each 4-bit value is shown
    -- as one hexadecimal digit.
    -- -------------------------------------------------------------------------
    Display : entity work.Seven_Segment_Display
        port map (
            Clock             => clk,

            Digit_0_Rightmost => Debug_Output(3 downto 0),
            Digit_1           => Debug_Output(7 downto 4),
            Digit_2           => Debug_ACC(3 downto 0),
            Digit_3           => Debug_ACC(7 downto 4),
            Digit_4           => Debug_State,
            Digit_5           => Debug_Instruction(3 downto 0),
            Digit_6           => Debug_Instruction(7 downto 4),
            Digit_7_Leftmost  => Debug_PC,

            Segment_Cathodes  => seg,
            Digit_Anodes      => an,
            Decimal_Point     => dp
        );

end architecture Structural;
