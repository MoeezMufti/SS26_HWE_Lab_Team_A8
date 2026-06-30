-- =============================================================================
--  File        : CPU_Top.vhd
--  Entity      : CPU_Top
--  Project     : 8-bit CPU  (Digital Technology, SS 2026)
--  Description : Top level of the 8-bit CPU. Connects the six building blocks
--                (program counter, memory, instruction register, control unit,
--                ALU, accumulator) into the complete datapath + control, and
--                exposes a set of debug outputs for the dashboard.
--  Style       : Structural architecture. Each sub-system is declared with the
--                keyword "component" and then instantiated with a descriptive
--                label and explicit port mapping ("name => signal"), as taught
--                under "Structural design using components".
--  Notes       : One small clocked process holds the output register and the
--                latched status flags (async reset, sync enable). Signal names
--                are lowercase_with_underscores.
-- =============================================================================

library ieee;
use ieee.std_logic_1164.all;

use work.CPU_Package.all;          -- OP_* constants (for ALU operand select)

entity CPU_Top is
    port (
        clk            : in  std_logic;
        rst            : in  std_logic;
        clk_en         : in  std_logic;
        program_select : in  std_logic_vector(1 downto 0);

        -- debug / observation outputs (used by the dashboard)
        debug_pc          : out std_logic_vector(3 downto 0);
        debug_instruction : out std_logic_vector(7 downto 0);
        debug_state       : out std_logic_vector(3 downto 0);
        debug_acc         : out std_logic_vector(7 downto 0);
        debug_output      : out std_logic_vector(7 downto 0);
        debug_ram_data    : out std_logic_vector(7 downto 0);

        zero_flag     : out std_logic;
        carry_flag    : out std_logic;
        overflow_flag : out std_logic;
        halted        : out std_logic
    );
end entity;

architecture structural of CPU_Top is

    -- ----------------------------------------------------------------------
    -- Component declarations (one per sub-system, declared before use)
    -- ----------------------------------------------------------------------
    component Program_Counter is
        port (
            clk        : in  std_logic;
            rst        : in  std_logic;
            clk_en     : in  std_logic;
            increment  : in  std_logic;
            load_en    : in  std_logic;
            load_value : in  std_logic_vector(3 downto 0);
            count_out  : out std_logic_vector(3 downto 0)
        );
    end component;

    component Memory_Unit is
        port (
            clk          : in  std_logic;
            rst          : in  std_logic;
            clk_en       : in  std_logic;
            program_select      : in  std_logic_vector(1 downto 0);
            instruction_address : in  std_logic_vector(3 downto 0);
            instruction_out     : out std_logic_vector(7 downto 0);
            ram_write_enable : in  std_logic;
            ram_address      : in  std_logic_vector(3 downto 0);
            ram_data_in      : in  std_logic_vector(7 downto 0);
            ram_data_out     : out std_logic_vector(7 downto 0)
        );
    end component;

    component Instruction_Register is
        port (
            clk             : in  std_logic;
            rst             : in  std_logic;
            clk_en          : in  std_logic;
            load_en         : in  std_logic;
            instruction_in  : in  std_logic_vector(7 downto 0);
            instruction_out : out std_logic_vector(7 downto 0)
        );
    end component;

    component Control_Unit is
        port (
            clk          : in  std_logic;
            rst          : in  std_logic;
            clk_en       : in  std_logic;
            opcode       : in  std_logic_vector(3 downto 0);
            zero_flag    : in  std_logic;
            carry_flag   : in  std_logic;
            ir_load      : out std_logic;
            pc_increment : out std_logic;
            pc_load      : out std_logic;
            acc_load     : out std_logic;
            ram_write    : out std_logic;
            output_load  : out std_logic;
            halt_control : out std_logic;
            state_debug  : out std_logic_vector(3 downto 0)
        );
    end component;

    component ALU is
        port (
            input_a       : in  std_logic_vector(7 downto 0);
            input_b       : in  std_logic_vector(7 downto 0);
            opcode        : in  std_logic_vector(3 downto 0);
            result        : out std_logic_vector(7 downto 0);
            carry_flag    : out std_logic;
            zero_flag     : out std_logic;
            overflow_flag : out std_logic
        );
    end component;

    component Accumulator is
        port (
            clk      : in  std_logic;
            rst      : in  std_logic;
            clk_en   : in  std_logic;
            load_en  : in  std_logic;
            data_in  : in  std_logic_vector(7 downto 0);
            data_out : out std_logic_vector(7 downto 0)
        );
    end component;

    -- ----------------------------------------------------------------------
    -- Internal interconnect signals (the "wires" between the blocks)
    -- ----------------------------------------------------------------------
    signal pc_value        : std_logic_vector(3 downto 0);
    signal instruction_rom : std_logic_vector(7 downto 0);
    signal instruction_reg : std_logic_vector(7 downto 0);

    signal opcode_sig      : std_logic_vector(3 downto 0);
    signal operand_sig     : std_logic_vector(3 downto 0);

    signal acc_value       : std_logic_vector(7 downto 0);
    signal alu_input_b     : std_logic_vector(7 downto 0);
    signal alu_result      : std_logic_vector(7 downto 0);

    signal ram_data_out    : std_logic_vector(7 downto 0);
    signal output_register : std_logic_vector(7 downto 0);

    -- control signals from the control unit
    signal ir_load         : std_logic;
    signal pc_increment    : std_logic;
    signal pc_load         : std_logic;
    signal acc_load        : std_logic;
    signal ram_write       : std_logic;
    signal output_load     : std_logic;
    signal halt_control    : std_logic;

    -- raw (combinational) flags out of the ALU
    signal alu_zero        : std_logic;
    signal alu_carry       : std_logic;
    signal alu_overflow    : std_logic;

    -- latched status flags + halt flag (registered versions)
    signal zero_register     : std_logic;
    signal carry_register    : std_logic;
    signal overflow_register : std_logic;
    signal halted_register   : std_logic;

begin

    -- split the instruction word into opcode (high nibble) and operand (low)
    opcode_sig  <= instruction_reg(7 downto 4);
    operand_sig <= instruction_reg(3 downto 0);

    -- second ALU operand: immediate value for LOAD_IMMEDIATE, else RAM data
    alu_input_b <= "0000" & operand_sig when opcode_sig = OP_LOAD_IMMEDIATE
                   else ram_data_out;

    -- ----------------------------------------------------------------------
    -- Component instantiations (labelled, explicit port mapping)
    -- ----------------------------------------------------------------------
    pc_block : Program_Counter
        port map (
            clk        => clk,
            rst        => rst,
            clk_en     => clk_en,
            increment  => pc_increment,
            load_en    => pc_load,
            load_value => operand_sig,
            count_out  => pc_value
        );

    memory_block : Memory_Unit
        port map (
            clk                 => clk,
            rst                 => rst,
            clk_en              => clk_en,
            program_select      => program_select,
            instruction_address => pc_value,
            instruction_out     => instruction_rom,
            ram_write_enable    => ram_write,
            ram_address         => operand_sig,
            ram_data_in         => acc_value,
            ram_data_out        => ram_data_out
        );

    ir_block : Instruction_Register
        port map (
            clk             => clk,
            rst             => rst,
            clk_en          => clk_en,
            load_en         => ir_load,
            instruction_in  => instruction_rom,
            instruction_out => instruction_reg
        );

    control_block : Control_Unit
        port map (
            clk          => clk,
            rst          => rst,
            clk_en       => clk_en,
            opcode       => opcode_sig,
            zero_flag    => zero_register,
            carry_flag   => carry_register,
            ir_load      => ir_load,
            pc_increment => pc_increment,
            pc_load      => pc_load,
            acc_load     => acc_load,
            ram_write    => ram_write,
            output_load  => output_load,
            halt_control => halt_control,
            state_debug  => debug_state
        );

    alu_block : ALU
        port map (
            input_a       => acc_value,
            input_b       => alu_input_b,
            opcode        => opcode_sig,
            result        => alu_result,
            carry_flag    => alu_carry,
            zero_flag     => alu_zero,
            overflow_flag => alu_overflow
        );

    acc_block : Accumulator
        port map (
            clk      => clk,
            rst      => rst,
            clk_en   => clk_en,
            load_en  => acc_load,
            data_in  => alu_result,
            data_out => acc_value
        );

    -- ----------------------------------------------------------------------
    -- Status / output register : async reset, sync enable.
    -- Flags are captured only when the accumulator is updated, so a jump that
    -- tests them sees the flags of the instruction that produced the result.
    -- ----------------------------------------------------------------------
    status_output_register : process(clk, rst)
    begin
        if rst = '1' then                              -- asynchronous reset
            output_register   <= (others => '0');
            zero_register     <= '1';                  -- ACC = 0 after reset
            carry_register    <= '0';
            overflow_register <= '0';
            halted_register   <= '0';
        elsif rising_edge(clk) then
            if clk_en = '1' then                       -- synchronous enable
                if acc_load = '1' then
                    zero_register     <= alu_zero;
                    carry_register    <= alu_carry;
                    overflow_register <= alu_overflow;
                end if;

                if output_load = '1' then
                    output_register <= acc_value;
                end if;

                if halt_control = '1' then
                    halted_register <= '1';
                end if;
            end if;
        end if;
    end process;

    -- ----------------------------------------------------------------------
    -- Drive the observation / debug outputs
    -- ----------------------------------------------------------------------
    debug_pc          <= pc_value;
    debug_instruction <= instruction_reg;
    debug_acc         <= acc_value;
    debug_output      <= output_register;
    debug_ram_data    <= ram_data_out;

    zero_flag     <= zero_register;
    carry_flag    <= carry_register;
    overflow_flag <= overflow_register;
    halted        <= halted_register;

end architecture;
