library ieee;
use ieee.std_logic_1164.all;

entity TB_CPU is
end entity;

architecture Simulation of TB_CPU is
    signal Clock          : std_logic := '0';
    signal Reset          : std_logic := '0';
    signal Clock_Enable   : std_logic := '0';
    signal Program_Select : std_logic_vector(1 downto 0) := "00";

    signal Debug_PC          : std_logic_vector(3 downto 0);
    signal Debug_Instruction : std_logic_vector(7 downto 0);
    signal Debug_State       : std_logic_vector(3 downto 0);
    signal Debug_ACC         : std_logic_vector(7 downto 0);
    signal Debug_Output      : std_logic_vector(7 downto 0);
    signal Debug_RAM_Data    : std_logic_vector(7 downto 0);

    signal Zero_Flag     : std_logic;
    signal Carry_Flag    : std_logic;
    signal Overflow_Flag : std_logic;
    signal Halted        : std_logic;

    procedure Step_CPU(signal CE : out std_logic) is
    begin
        CE <= '1';
        wait for 10 ns;
        CE <= '0';
        wait for 10 ns;
    end procedure;

begin

    Clock <= not Clock after 5 ns;

    UUT : entity work.CPU_Top
        port map (
            Clock          => Clock,
            Reset          => Reset,
            Clock_Enable   => Clock_Enable,
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

    process
    begin
        -- Program 0: expected final output 04
        Program_Select <= "00";
        Reset <= '1';
        wait for 30 ns;
        Reset <= '0';
        wait for 20 ns;
        for i in 0 to 35 loop
            Step_CPU(Clock_Enable);
        end loop;
        assert Halted = '1' report "Program 0 did not halt" severity error;
        assert Debug_Output = x"04" report "Program 0 output should be 04" severity error;

        -- Program 1: expected final output 0D
        Program_Select <= "01";
        Reset <= '1';
        wait for 30 ns;
        Reset <= '0';
        wait for 20 ns;
        for i in 0 to 35 loop
            Step_CPU(Clock_Enable);
        end loop;
        assert Halted = '1' report "Program 1 did not halt" severity error;
        assert Debug_Output = x"0D" report "Program 1 output should be 0D" severity error;

        -- Program 2: expected final output 0F
        Program_Select <= "10";
        Reset <= '1';
        wait for 30 ns;
        Reset <= '0';
        wait for 20 ns;
        for i in 0 to 35 loop
            Step_CPU(Clock_Enable);
        end loop;
        assert Halted = '1' report "Program 2 did not halt" severity error;
        assert Debug_Output = x"0F" report "Program 2 output should be 0F" severity error;

        -- Program 3: expected final output 07
        Program_Select <= "11";
        Reset <= '1';
        wait for 30 ns;
        Reset <= '0';
        wait for 20 ns;
        for i in 0 to 35 loop
            Step_CPU(Clock_Enable);
        end loop;
        assert Halted = '1' report "Program 3 did not halt" severity error;
        assert Debug_Output = x"07" report "Program 3 output should be 07" severity error;

        report "TB_CPU completed successfully." severity note;
        wait;
    end process;

end architecture;
