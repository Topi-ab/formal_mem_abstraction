library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity test_semaphore_mem is
	generic(
		DATA_BITS: natural := 8;
		SEMAPHORE_MIN: integer := -1;
		SEMAPHORE_MAX: integer := 1;
		CHECK_ASSERT: boolean := true;
		CHECK_ASSUME: boolean := false
	);
	port(
		clk_in: in std_logic;
		
		a_valid_in: in std_logic;
		a_data_in: in unsigned(DATA_BITS-1 downto 0);
		
		b_valid_out: out std_logic;
		b_data_out: out unsigned(DATA_BITS-1 downto 0)
	);
end;

architecture tester of test_semaphore_mem is
	constant buff_size: natural := 3;
	
	type buff_e is record
		valid: std_logic;
		data: unsigned(DATA_BITS-1 downto 0);
	end record;
	
	type buff_t is array(0 to buff_size-1) of buff_e;
	
	signal buff: buff_t := (others => (valid => '0', data => (others => '0')));
	
	signal bug_cnt: unsigned(10 downto 0) := (others => '0');
begin
	process(clk_in)
	begin
		if rising_edge(clk_in) then
			if a_valid_in = '1' then
				bug_cnt <= bug_cnt + 1;
			end if;
			
			if a_valid_in = '1' then
				buff(0).valid <= a_valid_in;
				buff(0).data <= a_data_in;
				buff(1 to buff_size-1) <= buff(0 to buff_size-2);
			end if;
		end if;
	end process;

	out_pr: process(all)
	begin
		b_valid_out <= buff(buff_size-1).valid and a_valid_in;
		b_data_out <= buff(buff_size-1).data;
		if bug_cnt = 13 or bug_cnt = 17 then
			b_data_out <= to_unsigned(15, b_data_out);
		end if;
	end process;

	dut: entity work.formal_semaphore_mem
		generic map(
			DATA_BITS => DATA_BITS,
			SEMAPHORE_MIN => SEMAPHORE_MIN,
			SEMAPHORE_MAX => SEMAPHORE_MAX,
			CHECK_ASSERT => CHECK_ASSERT,
			CHECK_ASSUME => CHECK_ASSUME
		)
		port map(
			clk_in => clk_in,
			a_valid_in => a_valid_in,
			a_data_in => std_logic_vector(a_data_in),
			b_valid_in => b_valid_out,
			b_data_in => std_logic_vector(b_data_out)
		);
	
	default clock is rising_edge(clk_in);
	
	-- assume a_data_in = 0;
	assume always a_valid_in = '1' |=> a_data_in = prev(a_data_in) + 1;
	assume always a_valid_in = '0' |=> stable(a_data_in);
end;
