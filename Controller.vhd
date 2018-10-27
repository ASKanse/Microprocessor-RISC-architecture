library std;
library ieee;
use ieee.std_logic_1164.all;
library ieee;
use ieee.numeric_std.all; 
library std;
use std.standard.all;

entity Controller is
  port (
    -- Instruction Register write
    inst_write: out std_logic;

    -- Program counter write / select
    pc_write: out std_logic;
    pc_in_select: out std_logic_vector(1 downto 0);

    -- Select the two ALU inputs / op_code
    alu1_select: out std_logic_vector(1 downto 0);
    alu2_select: out std_logic_vector(1 downto 0);

    -- Select the correct inputs to memory
    addr_select: out std_logic_vector(1 downto 0);
	MEMWRITE: out std_logic;
	
	t1_sel: out std_logic_vector(1 downto 0);
    t2_sel: out std_logic_vector(1 downto 0);
    t3_sel: out std_logic;

    -- Choices for Register file
    a1_sel: out std_logic;
    a2_sel: out std_logic;
    rf_d3_sel: out std_logic_vector(1 downto 0);
    regwrite_select: out std_logic_vector(1 downto 0);
    reg_write: out std_logic;
    t1_write, t2_write,t3_write, ar_write, PC_en, rd, alu_op_sel : out std_logic;

    -- Control signals which decide whether or not to set carry flag
    carry_en, zero_en: out std_logic;
	
	pego: in std_logic;
    CARRY, ZERO: in std_logic;
    ir_out: in std_logic_vector(15 downto 0);


    -- clock and reset pins, if reset is high, external memory signals
    -- active.
    clk, reset: in std_logic
  );
end entity;

architecture Struct of Controller is
  type FsmState is (S0, S1, S2, S3, S4, S5, S6, S7, S8, S9, S10, S11,S12, S13, S14, S15, S16);
  signal state: FsmState;
begin

  -- Next state process
  process(clk, reset, state, op_code, op_dif, CARRY, ZERO, pego, ir_out)
    variable nstate: FsmState;
  begin
    nstate := S0;
    case state is
      when S0 =>  -- First state whenever the code is loaded
        nstate := S1;
      
	  when S1 =>  -- Always the first state of every instruction.
        nstate := S2;
      
	  when S2 =>  -- Common Second state of all instructions
        if op_code = "1100" then
		  nstate := S3;
		elsif  op_code = "0000" then
  		  if op_diff = "10" and CARRY = "0" then
		    nstate := S1;
		  elsif op_diff = "01" and ZERO = "0" then
		    nstate := S1;
		  else
		    nstate = S3;
		  end if
		elsif  op_code = "0001" then
  		  if op_diff = "10" and CARRY = "0" then
		    nstate := S1;
		  elsif op_diff = "01" and ZERO = "0" then
		    nstate := S1;
		  else
		    nstate = S3;
		  end if
        elsif op_code = "0001" then
          nstate := S5;
        elsif op_code = "0100" or op_code = "0101" then
          nstate := S6;
        elsif op_code = "1000" then
          nstate := S10;
        elsif op_code = "1001" then
          nstate := S11;
        elsif op_code = "0011" then
          nstate := S12;
        elsif op_code = "0110" then
          nstate := S13;
        elsif op_code = "0111" then
          nstate := S14;
        else
          nstate := S1;
        end if;
      
	  when S3 =>  -- For ALU operations: ADD,ADC,ADZ,NDU,NDZ,NDC,BEQ
        if op_code = "1100" then
		  nstate := S9;
		else 
		  nstate := S4;
		end if;
      
	  when S4 =>  -- For ADZ,ADC,NDC,NDZ
        nstate := S1;
      
	  when S5 =>  -- For ADI
        nstate := S4;
      
	  when S6 =>  -- For LW, SW
          if op_code = "0100" then
		    nstate := S7;
		  elsif op_code = "0101" then
		    nstate := S8;
		  else
		    nstate := S1;
      
	  when S7 =>  -- For LW
        nstate := S4;
      
	  when S8 =>  -- For SW
        nstate := S1;
      
	  when S9 =>  -- For BEQ
          nstate := S1;
  
      when S10 => --For JAL
        nstate := S1;
      
	  when S11 => -- For JLR
        nstate:= S1;
		
      when S12 => -- For LHI
        nstate := S1;
		
      when S13 => -- For LM
        if pego = "1" then
		  nstate := S15;
		else 
		  nstate := S1;
      
	  when S14 =>-- For SM
        if pego = "1" then
		  nstate := S15;
		else 
		  nstate := S1;
      
	  when S15 => -- For LM
        nstate := S13; 
      
	  when S16 => -- For SM
        nstate := S14;
      
	  when others =>
        nstate := S1;
    end case;
    
	op_code <= ir_out(15 downto 12);
	op_dif <= ir_out(1 downto 0);
    
	if(clk'event and clk = '1') then
      if(reset = '1') then
        state <= S0;
      else
        state <= nstate;
      end if;
    end if;
end process;

-- Control Signal process

process(state, ZERO,CARRY, pego, reset, ir_out)
    variable n_inst_write: std_logic;
	variable n_pc_write: std_logic;
    variable n_pc_in_select: std_logic_vector(1 downto 0);
    variable n_alu1_select: std_logic_vector(1 downto 0);
    variable n_alu2_select: std_logic_vector(1 downto 0);
    variable n_addr_select: std_logic_vector(1 downto 0);
    variable n_MEMWRITE: std_logic;
    variable n_regwrite_select: std_logic_vector(1 downto 0);
    variable n_reg_write: std_logic;
    variable n_t1_write: std_logic;
    variable n_t2_write: std_logic;
	variable n_t3_write: std_logic;
	variable n_t1_sel: std_logic_vector(1 downto 0);
    variable n_t2_sel: std_logic_vector(1 downto 0);
	variable n_t3_sel: std_logic;
	variable n_a1_sel: std_logic;
	variable n_a2_sel: std_logic;
    variable n_rf_d3_sel: std_logic_vector(1 downto 0);
    variable n_zero_en: std_logic;
	variable n_carry_en: std_logic;
    variable n_PC_en: std_logic;
    variable n_rd: std_logic;
    variable n_ar_write: std_logic;
	variable n_alu_op_sel: std_logic;
  begin
    n_inst_write := '0';
    n_pc_write := '0';
    n_pc_in_select := "00";
    n_alu1_select := "00";
    n_alu2_select := "00";
    n_addr_select := "00";
    n_MEMWRITE := '0';
    n_regwrite_select := "00";
    n_reg_write := '0';
    n_t1_write := '0';
    n_t2_write := '0';
	n_t3_write := '0';
	n_t1_sel := '0';
    n_t2_sel := '0';
	n_t3_sel := '0';
	n_a1_sel := '0';
	n_a2_sel := '0';
    n_rf_d3_sel:= "00";
    n_zero_en := '0';
    n_carry_en := '0';
    n_PC_en := '0';
    n_rd := '0';
    n_ar_write := '0';
	n_alu_op_sel := '0';
	
	case state is
	
	when S0 =>
	n_pc_write := '0';
    n_pc_in_select := "00";
    n_alu1_select := "00";
    n_alu2_select := "00";
    n_addr_select := "00";
    n_MEMWRITE := '0';
    n_regwrite_select := "00";
    n_reg_write := '0';
    n_t1_write := '0';
    n_t2_write := '0';
	n_t3_write := '0';
	n_t1_sel := '0';
    n_t2_sel := '0';
	n_t3_sel := '0';
	n_a1_sel := '0';
	n_a2_sel := '0';
    n_rf_d3_sel:= "00";
    n_zero_en := '0';
    n_carry_en := '0';
    n_PC_en := '0';
    n_rd := '0';
    n_ar_write := '0';
	n_alu_op_sel := '0';
		
	when S1 =>
	
	
	
	
	
