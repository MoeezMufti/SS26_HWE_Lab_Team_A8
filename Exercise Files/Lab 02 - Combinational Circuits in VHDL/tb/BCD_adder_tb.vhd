-- ============================================================
-- File        : BCD_adder_tb.vhd
-- Lab         : Lab 02 - Exercise 04
-- Description : Testbench for the 1-digit BCD adder.
--               It tests all valid BCD input digits A and B
--               from 0 to 9, with Cin = 0 and Cin = 1.
-- ============================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity BCD_adder_tb is
end entity BCD_adder_tb;

architecture bench of BCD_adder_tb is
    signal A    : std_logic_vector(3 downto 0) := (others => '0');
    signal B    : std_logic_vector(3 downto 0) := (others => '0');
    signal Cin  : std_logic := '0';
    signal Sum  : std_logic_vector(3 downto 0);
    signal Cout : std_logic;
begin
    uut : entity work.BCD_adder
        port map (
            A    => A,
            B    => B,
            Cin  => Cin,
            Sum  => Sum,
            Cout => Cout
        );

    stimulus : process
        variable total          : integer;
        variable expected_sum   : std_logic_vector(3 downto 0);
        variable expected_carry : std_logic;
    begin
        for a_int in 0 to 9 loop
            for b_int in 0 to 9 loop
                for cin_int in 0 to 1 loop
                    A <= std_logic_vector(to_unsigned(a_int, 4));
                    B <= std_logic_vector(to_unsigned(b_int, 4));
                    if cin_int = 1 then
                        Cin <= '1';
                    else
                        Cin <= '0';
                    end if;

                    wait for 10 ns;

                    total        := a_int + b_int + cin_int;
                    expected_sum := std_logic_vector(to_unsigned(total mod 10, 4));
                    if total > 9 then
                        expected_carry := '1';
                    else
                        expected_carry := '0';
                    end if;

                    assert (Sum = expected_sum and Cout = expected_carry)
                        report "BCD_adder failed for A=" & integer'image(a_int) &
                               ", B=" & integer'image(b_int) &
                               ", Cin=" & integer'image(cin_int)
                        severity error;
                end loop;
            end loop;
        end loop;

        report "BCD_adder_tb: all valid BCD cases passed." severity note;
        wait;
    end process stimulus;
end architecture bench;
