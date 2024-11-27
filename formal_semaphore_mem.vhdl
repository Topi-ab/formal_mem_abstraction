library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

/*
	Think of this module as array of semaphores.
	
	The size of array is 2**DATA_BITS.
	
	Each semaphore has range of SEMPAHORE_MIN (<= 0) to SEMAPHORE_MAX (> 0).
	
	Each a_valid_in='1' cycle increases the semaphore at address a_data_in.
	Each b_valid_in='1' cycle decreases the semaphore at address b_data_in.
	
	If a semaphore in any address goes out of it range assert and/or assume is generated.
	
	if CHECK_ASSERT is true => assert is generated.
	if CHECK_ASSUME is true => assume is generated.
	
	The implementation is based on free pointer (master_ptr), which is random value,
	but constant over time (anyconst attribute), and the module only checks the 
	semaphore on address master_ptr.
	
	As the master_ptr is free variable, all addresses will be analyzed in formal tool.
*/

entity formal_semaphore_mem is
	generic(
		DATA_BITS: natural;
		SEMAPHORE_MIN: integer;
		SEMAPHORE_MAX: integer;
		CHECK_ASSERT: boolean;
		CHECK_ASSUME: boolean
	);
	port(
		clk_in: in std_logic;
		
		a_valid_in: in std_logic;
		a_data_in: in std_logic_vector(DATA_BITS-1 downto 0);
		
		b_valid_in: in std_logic;
		b_data_in: in std_logic_vector(DATA_BITS-1 downto 0)
	);
end;

architecture formal of formal_semaphore_mem is
	attribute anyseq: boolean;
	attribute anyconst: boolean;
	
	signal master_ptr: std_logic_vector(DATA_BITS-1 downto 0);
	attribute anyconst of master_ptr: signal is true;
	
	signal a_ptr_eq: std_logic;
	signal b_ptr_eq: std_logic;
	attribute anyseq of a_ptr_eq: signal is true;
	attribute anyseq of b_ptr_eq: signal is true;
	
	signal s_cnt: integer range SEMAPHORE_MIN-1 to SEMAPHORE_MAX+1;
	attribute anyseq of s_cnt: signal is true;
begin
	assert SEMAPHORE_MIN <= 0 report "SEMAPHORE_MIN must be non-positive" severity failure;
	assert SEMAPHORE_MAX > 0 report "SEMAPHORE_MAX must be positive" severity failure;

	default clock is rising_edge(clk_in);
	
	-- *_ptr_eq:
	assume always a_ptr_eq = '1' <-> a_data_in = master_ptr and a_valid_in = '1';
	assume always b_ptr_eq = '1' <-> b_data_in = master_ptr and b_valid_in = '1';
	
	-- s_cnt:
	assume s_cnt = 0;
	assume always a_ptr_eq = b_ptr_eq |=> stable(s_cnt);
	assume always prev(a_ptr_eq = '1' and b_ptr_eq = '0') -> s_cnt = prev(s_cnt) + 1;
	assume always prev(a_ptr_eq = '0' and b_ptr_eq = '1') -> s_cnt = prev(s_cnt) - 1;
	
	assert_g: if CHECK_ASSERT generate	
		f_1: assert always s_cnt /= SEMAPHORE_MIN-1 and s_cnt /= SEMAPHORE_MAX+1;
	end generate;
	
	assume_g: if CHECK_ASSUME generate
		a_1: assume always s_cnt /= SEMAPHORE_MIN-1 and s_cnt /= SEMAPHORE_MAX+1;
	end generate;
end;
