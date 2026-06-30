-- ============================================================
-- File        : CR_add_sub_tb.vhd
-- Lab         : Lab 02 - Exercise 03
-- Description : Testbench for the 4-bit adder/subtractor.
--               It checks all A and B values for both modes:
--               addition and subtraction.
-- ============================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity CR_add_sub_tb is
end entity CR_add_sub_tb;

architecture bench of CR_add_sub_tb is
    signal A          : std_logic_vector(3 downto 0) := (others => '0');
    signal B          : std_logic_vector(3 downto 0) := (others => '0');
    signal Add_Sub    : std_logic := '0';
    signal Result     : std_logic_vector(3 downto 0);
    signal Carry_Out  : std_logic;
    signal Borrow_Out : std_logic;
begin
    uut : entity work.CR_add_sub
        port map (
            A          => A,
            B          => B,
            Add_Sub    => Add_Sub,
            Result     => Result,
            Carry_Out  => Carry_Out,
            Borrow_Out => Borrow_Out
        );

    stimulus : process
        variable expected_total  : integer;
        variable expected_result : std_logic_vector(3 downto 0);
        variable expected_carry  : std_logic;
        variable expected_borrow : std_logic;
    begin
        for a_int in 0 to 15 loop
            for b_int in 0 to 15 loop
                -- Addition mode: A + B
                A       <= std_logic_vector(to_unsigned(a_int, 4));
                B       <= std_logic_vector(to_unsigned(b_int, 4));
                Add_Sub <= '0';
                wait for 10 ns;

                expected_total  := a_int + b_int;
                expected_result := std_logic_vector(to_unsigned(expected_total mod 16, 4));
                if expected_total > 15 then
                    expected_carry := '1';
                else
                    expected_carry := '0';
                end if;

                assert (Result = expected_result and Carry_Out = expected_carry and Borrow_Out = '0')
                    report "CR_add_sub addition failed for A=" & integer'image(a_int) &
                           ", B=" & integer'image(b_int)
                    severity error;

                -- Subtraction mode: A - B using two's complement.
                Add_Sub <= '1';
                wait for 10 ns;

                expected_total  := (a_int - b_int) mod 16;
                expected_result := std_logic_vector(to_unsigned(expected_total, 4));
                if a_int < b_int then
                    expected_borrow := '1';
                else
                    expected_borrow := '0';
                end if;

                assert (Result = expected_result and Borrow_Out = expected_borrow)
                    report "CR_add_sub subtraction failed for A=" & integer'image(a_int) &
                           ", B=" & integer'image(b_int)
                    severity error;
            end loop;
        end loop;

        report "CR_add_sub_tb: all addition and subtraction cases passed." severity note;
        wait;
    end process stimulus;
end architecture bench;
