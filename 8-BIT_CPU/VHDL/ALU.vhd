-- =============================================================================
--  File        : ALU.vhd
--  Entity      : ALU
--  Project     : 8-bit CPU  (Digital Technology, SS 2026)
--  Description : Combinational Arithmetic Logic Unit.
--                It performs arithmetic and logic operations selected by opcode.
--                The ALU does not store data; it only calculates the next result.
--
--  Inputs      : Input_A usually comes from the accumulator.
--                Input_B comes from either the operand/immediate value or RAM.
--                Opcode selects the ALU operation.
--
--  Outputs     : Result is the calculated 8-bit value.
--                Carry_Flag shows carry-out for addition or borrow/wrap for subtraction.
--                Zero_Flag is set when Result = 00.
--                Overflow_Flag is set for signed overflow in add/subtract.
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.CPU_Package.all;

entity ALU is
    port (
        Input_A       : in  std_logic_vector(7 downto 0);
        Input_B       : in  std_logic_vector(7 downto 0);
        Opcode        : in  std_logic_vector(3 downto 0);

        Result        : out std_logic_vector(7 downto 0);
        Carry_Flag    : out std_logic;
        Zero_Flag     : out std_logic;
        Overflow_Flag : out std_logic
    );
end entity ALU;

architecture behavioral of ALU is

begin

    -- -------------------------------------------------------------------------
    -- Combinational ALU process
    --
    -- The ALU output depends only on Input_A, Input_B, and Opcode.
    -- Therefore, all three signals are included in the sensitivity list.
    -- Variables are used inside the process to calculate temporary values
    -- before assigning the final outputs.
    -- -------------------------------------------------------------------------
    alu_logic : process(Input_A, Input_B, Opcode)

        -- 9-bit temporary value is used for addition/subtraction.
        -- Bit 8 stores the carry-out or borrow/wrap information.
        variable temp_result : unsigned(8 downto 0);

        -- Internal variables for the final output values.
        variable result_var   : std_logic_vector(7 downto 0);
        variable carry_var    : std_logic;
        variable overflow_var : std_logic;

    begin

        -- Default values.
        -- These avoid incomplete assignments and prevent unintended latches.
        result_var   := Input_A;
        carry_var    := '0';
        overflow_var := '0';
        temp_result  := (others => '0');

        case Opcode is

            when OP_LOAD_IMMEDIATE =>
                result_var := Input_B;

            when OP_LOAD_MEMORY =>
                result_var := Input_B;

            when OP_ADD_MEMORY =>
                temp_result := ('0' & unsigned(Input_A)) + ('0' & unsigned(Input_B));
                result_var  := std_logic_vector(temp_result(7 downto 0));
                carry_var   := temp_result(8);

                -- Signed overflow check:
                -- If both inputs have the same sign but the result sign changes,
                -- signed overflow occurred.
                if (Input_A(7) = Input_B(7)) and (result_var(7) /= Input_A(7)) then
                    overflow_var := '1';
                end if;

            when OP_SUB_MEMORY =>
                temp_result := ('0' & unsigned(Input_A)) - ('0' & unsigned(Input_B));
                result_var  := std_logic_vector(temp_result(7 downto 0));
                carry_var   := temp_result(8);

                -- Signed overflow check for subtraction:
                -- If the inputs have different signs and the result sign changes
                -- compared to Input_A, signed overflow occurred.
                if (Input_A(7) /= Input_B(7)) and (result_var(7) /= Input_A(7)) then
                    overflow_var := '1';
                end if;

            when OP_AND_MEMORY =>
                result_var := Input_A and Input_B;

            when OP_OR_MEMORY =>
                result_var := Input_A or Input_B;

            when OP_XOR_MEMORY =>
                result_var := Input_A xor Input_B;

            when OP_NOT_ACC =>
                result_var := not Input_A;

            when OP_CLEAR =>
                result_var := (others => '0');

            when others =>
                result_var := Input_A;

        end case;

        -- Assign calculated values to ALU outputs.
        Result        <= result_var;
        Carry_Flag    <= carry_var;
        Overflow_Flag <= overflow_var;

        if result_var = "00000000" then
            Zero_Flag <= '1';
        else
            Zero_Flag <= '0';
        end if;

    end process alu_logic;

end architecture behavioral;
