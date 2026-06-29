library ieee;
use ieee.std_logic_1164.all;

package CPU_Package is

    -- 8-bit instruction format:
    -- instruction(7 downto 4) = opcode
    -- instruction(3 downto 0) = operand/address

    constant OP_NOP            : std_logic_vector(3 downto 0) := "0000";
    constant OP_LOAD_IMMEDIATE : std_logic_vector(3 downto 0) := "0001";
    constant OP_LOAD_MEMORY    : std_logic_vector(3 downto 0) := "0010";
    constant OP_STORE_MEMORY   : std_logic_vector(3 downto 0) := "0011";
    constant OP_ADD_MEMORY     : std_logic_vector(3 downto 0) := "0100";
    constant OP_SUB_MEMORY     : std_logic_vector(3 downto 0) := "0101";
    constant OP_AND_MEMORY     : std_logic_vector(3 downto 0) := "0110";
    constant OP_OR_MEMORY      : std_logic_vector(3 downto 0) := "0111";
    constant OP_XOR_MEMORY     : std_logic_vector(3 downto 0) := "1000";
    constant OP_NOT_ACC        : std_logic_vector(3 downto 0) := "1001";
    constant OP_JUMP           : std_logic_vector(3 downto 0) := "1010";
    constant OP_JUMP_IF_ZERO   : std_logic_vector(3 downto 0) := "1011";
    constant OP_JUMP_IF_CARRY  : std_logic_vector(3 downto 0) := "1100";
    constant OP_OUT            : std_logic_vector(3 downto 0) := "1101";
    constant OP_CLEAR          : std_logic_vector(3 downto 0) := "1110";
    constant OP_HALT           : std_logic_vector(3 downto 0) := "1111";

    type CPU_State_Type is (
        STATE_FETCH,
        STATE_DECODE,
        STATE_EXECUTE,
        STATE_HALT
    );

end package;
