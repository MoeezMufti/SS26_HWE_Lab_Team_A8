-- ============================================================
-- File        : CR_adder_tb.vhd
-- Lab         : Lab 02 - Exercise 02
-- Description : Testbench for the 4-bit ripple carry adder.
--               It checks every possible A, B, and Cin value:
--               16 * 16 * 2 = 512 test cases.
-- ============================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity CR_adder_tb is
end entity CR_adder_tb;

architecture bench of CR_adder_tb is
    constant WIDTH : positive := 4;

    signal A    : std_logic_vector(WIDTH - 1 downto 0) := (others => '0');
    signal B    : std_logic_vector(WIDTH - 1 downto 0) := (others => '0');
    signal Cin  : std_logic := '0';
    signal S    : std_logic_vector(WIDTH - 1 downto 0);
    signal Cout : std_logic;
begin
    uut : entity work.CR_adder
        generic map (
            WIDTH => WIDTH
        )
        port map (
            A    => A,
            B    => B,
            Cin  => Cin,
            S    => S,
            Cout => Cout
        );

    stimulus : process
        variable expected_total : integer;
        variable expected_sum   : std_logic_vector(WIDTH - 1 downto 0);
        variable expected_carry : std_logic;
    begin
        -- Exhaustive test: every valid 4-bit input combination.
        for a_int in 0 to 15 loop
            for b_int in 0 to 15 loop
                for cin_int in 0 to 1 loop
                    A   <= std_logic_vector(to_unsigned(a_int, WIDTH));
                    B   <= std_logic_vector(to_unsigned(b_int, WIDTH));
                    if cin_int = 1 then
                        Cin <= '1';
                    else
                        Cin <= '0';
                    end if;

                    wait for 10 ns;

                    expected_total := a_int + b_int + cin_int;
                    expected_sum   := std_logic_vector(to_unsigned(expected_total mod 16, WIDTH));
                    if expected_total > 15 then
                        expected_carry := '1';
                    else
                        expected_carry := '0';
                    end if;

                    assert (S = expected_sum and Cout = expected_carry)
                        report "CR_adder failed for A=" & integer'image(a_int) &
                               ", B=" & integer'image(b_int) &
                               ", Cin=" & integer'image(cin_int)
                        severity error;
                end loop;
            end loop;
        end loop;

        report "CR_adder_tb: all 512 test cases passed." severity note;
        wait;
    end process stimulus;
end architecture bench;
