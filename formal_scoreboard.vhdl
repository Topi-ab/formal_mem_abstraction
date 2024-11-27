library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

/*
	Think of this module as two fifos used to synchronize two streams (a_* and b_*).
	
	When data is received on the first port, it stays in the fifo until the corresponding
	data is received on the the second port, and then the comparison is done between 
	the first and the second data.
	
	if CHECK_ASSERT is true => assert is generated.
	if CHECK_ASSUME is true => assume is generated.
	
	The implementation is based on free pointer (master_ptr), which is random value,
	but constant over time (anyconst attribute), and the module only checks the 
	data which has sequence number (a_ptr / b_ptr) of master_ptr.
	
	When both ports have received the corresponding data, the comparison is done
	to check that the data from both ports are equal.
	
	As the master_ptr is free variable, all addresses will be analyzed in formal tool.
*/

entity formal_scoreboard is
	generic(
		PTR_BITS: natural := 8;
		DATA_BITS: natural;
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

architecture formal of formal_scoreboard is
	attribute anyseq: boolean;
	attribute anyconst: boolean;
	
	signal master_ptr: unsigned(PTR_BITS-1 downto 0);
	attribute anyconst of master_ptr: signal is true;
	
	signal a_ptr: unsigned(PTR_BITS-1 downto 0);
	signal b_ptr: unsigned(PTR_BITS-1 downto 0);
	attribute anyseq of a_ptr: signal is true;
	attribute anyseq of b_ptr: signal is true;
	
	signal mem_a: std_logic_vector(DATA_BITS-1 downto 0);
	signal mem_b: std_logic_vector(DATA_BITS-1 downto 0);
	attribute anyconst of mem_a: signal is true;
	attribute anyconst of mem_b: signal is true;
	
	signal a_ptr_eq: std_logic;
	signal b_ptr_eq: std_logic;
	attribute anyseq of a_ptr_eq: signal is true;
	attribute anyseq of b_ptr_eq: signal is true;
	
	signal a_captured: std_logic := '0';
	signal b_captured: std_logic := '0';
	signal ab_captured: std_logic;
	attribute anyseq of a_captured: signal is true;
	attribute anyseq of b_captured: signal is true;
	attribute anyseq of ab_captured: signal is true;
begin
	default clock is rising_edge(clk_in);
	
	-- *_ptr_eq:
	assume always a_ptr_eq = '1' <-> a_ptr = master_ptr and a_valid_in = '1';
	assume always b_ptr_eq = '1' <-> b_ptr = master_ptr and b_valid_in = '1';
	
	-- -- *_captured:
	assume a_captured = a_ptr_eq;
	assume always (a_ptr_eq = '0') <-> stable(a_captured);

	assume b_captured = b_ptr_eq;
	assume always (b_ptr_eq = '0') <-> stable(b_captured);

	assume always ab_captured = (a_captured and b_captured);

	-- *_ptr:
	assume a_ptr = 0;
	-- assume always a_valid_in = '1' |=> a_ptr = prev(a_ptr) + 1;
	-- assume always a_valid_in = '0' |=> stable(a_ptr);
	-- assume always prev(a_valid_in = '1') |-> a_ptr = prev(a_ptr) + 1;
	-- assume always prev(a_valid_in = '0') |-> stable(a_ptr);
	assume always prev(a_valid_in = '1') <-> a_ptr = prev(a_ptr) + 1;
	assume always prev(a_valid_in = '0') <-> stable(a_ptr);
	
	assume b_ptr = 0;
	-- assume always b_valid_in = '1' |=> b_ptr = prev(b_ptr) + 1;
	-- assume always b_valid_in = '0' |=> stable(b_ptr);
	-- assume always prev(b_valid_in = '1') |-> b_ptr = prev(b_ptr) + 1;
	-- assume always prev(b_valid_in = '0') |-> stable(b_ptr);
	assume always prev(b_valid_in = '1') <-> b_ptr = prev(b_ptr) + 1;
	assume always prev(b_valid_in = '0') <-> stable(b_ptr);
	
	-- mem_*:
	-- assume always a_ptr_eq = '1' |-> mem_a = a_data_in;
	-- assume always b_ptr_eq = '1' |-> mem_b = b_data_in;
	assume always a_ptr_eq = '1' <-> mem_a = a_data_in;
	assume always b_ptr_eq = '1' <-> mem_b = b_data_in;
	
	-- These assumes seem to slow down the verification.
	-- assume never a_captured = '1' and fell(b_ptr_eq);
	-- assume never b_captured = '1' and fell(a_ptr_eq);

	assert_g: if CHECK_ASSERT generate
		f_1: assert always ab_captured = '1' |-> mem_a = mem_b;
	end generate;

	assume_g: if CHECK_ASSUME generate
		a_1: assume always ab_captured = '1' |-> mem_a = mem_b;
	end generate;
end;
