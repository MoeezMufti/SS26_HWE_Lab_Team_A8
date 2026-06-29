library ieee;
use ieee.std_logic_1164.all;

use work.CPU_Package.all;

entity Control_Unit is
    port (
        Clock        : in  std_logic;
        Reset        : in  std_logic;
        Clock_Enable : in  std_logic;

        Opcode     : in  std_logic_vector(3 downto 0);
        Zero_Flag  : in  std_logic;
        Carry_Flag : in  std_logic;

        IR_Load      : out std_logic;
        PC_Increment : out std_logic;
        PC_Load      : out std_logic;
        ACC_Load     : out std_logic;
        RAM_Write    : out std_logic;
        Output_Load  : out std_logic;
        Halt_Control : out std_logic;
        State_Debug  : out std_logic_vector(3 downto 0)
    );
end entity;

architecture RTL of Control_Unit is
    signal Current_State : CPU_State_Type := STATE_FETCH;
begin

    process(Clock)
    begin
        if rising_edge(Clock) then
            if Reset = '1' then
                Current_State <= STATE_FETCH;
            elsif Clock_Enable = '1' then
                case Current_State is
                    when STATE_FETCH =>
                        Current_State <= STATE_DECODE;
                    when STATE_DECODE =>
                        Current_State <= STATE_EXECUTE;
                    when STATE_EXECUTE =>
                        if Opcode = OP_HALT then
                            Current_State <= STATE_HALT;
                        else
                            Current_State <= STATE_FETCH;
                        end if;
                    when STATE_HALT =>
                        Current_State <= STATE_HALT;
                end case;
            end if;
        end if;
    end process;

    process(Current_State, Opcode, Zero_Flag, Carry_Flag)
    begin
        IR_Load      <= '0';
        PC_Increment <= '0';
        PC_Load      <= '0';
        ACC_Load     <= '0';
        RAM_Write    <= '0';
        Output_Load  <= '0';
        Halt_Control <= '0';
        State_Debug  <= "0000";

        case Current_State is

            when STATE_FETCH =>
                IR_Load      <= '1';
                PC_Increment <= '1';
                State_Debug  <= "0001";

            when STATE_DECODE =>
                State_Debug <= "0010";

            when STATE_EXECUTE =>
                State_Debug <= "0011";

                case Opcode is
                    when OP_LOAD_IMMEDIATE =>
                        ACC_Load <= '1';
                    when OP_LOAD_MEMORY =>
                        ACC_Load <= '1';
                    when OP_STORE_MEMORY =>
                        RAM_Write <= '1';
                    when OP_ADD_MEMORY =>
                        ACC_Load <= '1';
                    when OP_SUB_MEMORY =>
                        ACC_Load <= '1';
                    when OP_AND_MEMORY =>
                        ACC_Load <= '1';
                    when OP_OR_MEMORY =>
                        ACC_Load <= '1';
                    when OP_XOR_MEMORY =>
                        ACC_Load <= '1';
                    when OP_NOT_ACC =>
                        ACC_Load <= '1';
                    when OP_JUMP =>
                        PC_Load <= '1';
                    when OP_JUMP_IF_ZERO =>
                        if Zero_Flag = '1' then
                            PC_Load <= '1';
                        end if;
                    when OP_JUMP_IF_CARRY =>
                        if Carry_Flag = '1' then
                            PC_Load <= '1';
                        end if;
                    when OP_OUT =>
                        Output_Load <= '1';
                    when OP_CLEAR =>
                        ACC_Load <= '1';
                    when OP_HALT =>
                        Halt_Control <= '1';
                    when others =>
                        null;
                end case;

            when STATE_HALT =>
                Halt_Control <= '1';
                State_Debug  <= "1111";

        end case;
    end process;

end architecture;
