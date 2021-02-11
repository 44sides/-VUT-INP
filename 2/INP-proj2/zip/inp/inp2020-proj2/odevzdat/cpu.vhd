-- cpu.vhd: Simple 8-bit CPU (BrainF*ck interpreter)
-- Copyright (C) 2020 Brno University of Technology,
--                    Faculty of Information Technology
-- Author(s): Vladyslav Tverdokhlib
--

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;

-- ----------------------------------------------------------------------------
--                        Entity declaration
-- ----------------------------------------------------------------------------
entity cpu is
 port (
   CLK   : in std_logic;  -- hodinovy signal
   RESET : in std_logic;  -- asynchronni reset procesoru
   EN    : in std_logic;  -- povoleni cinnosti procesoru
 
   -- synchronni pamet ROM
   CODE_ADDR : out std_logic_vector(11 downto 0); -- adresa do pameti
   CODE_DATA : in std_logic_vector(7 downto 0);   -- CODE_DATA <- rom[CODE_ADDR] pokud CODE_EN='1'
   CODE_EN   : out std_logic;                     -- povoleni cinnosti
   
   -- synchronni pamet RAM
   DATA_ADDR  : out std_logic_vector(9 downto 0); -- adresa do pameti
   DATA_WDATA : out std_logic_vector(7 downto 0); -- ram[DATA_ADDR] <- DATA_WDATA pokud DATA_EN='1'
   DATA_RDATA : in std_logic_vector(7 downto 0);  -- DATA_RDATA <- ram[DATA_ADDR] pokud DATA_EN='1'
   DATA_WE    : out std_logic;                    -- cteni (0) / zapis (1)
   DATA_EN    : out std_logic;                    -- povoleni cinnosti 
   
   -- vstupni port
   IN_DATA   : in std_logic_vector(7 downto 0);   -- IN_DATA <- stav klavesnice pokud IN_VLD='1' a IN_REQ='1'
   IN_VLD    : in std_logic;                      -- data platna
   IN_REQ    : out std_logic;                     -- pozadavek na vstup data
   
   -- vystupni port
   OUT_DATA : out  std_logic_vector(7 downto 0);  -- zapisovana data
   OUT_BUSY : in std_logic;                       -- LCD je zaneprazdnen (1), nelze zapisovat
   OUT_WE   : out std_logic                       -- LCD <- OUT_DATA pokud OUT_WE='1' a OUT_BUSY='0'
 );
end cpu;


-- ----------------------------------------------------------------------------
--                      Architecture declaration
-- ----------------------------------------------------------------------------
architecture behavioral of cpu is
	
	signal pc_reg : std_logic_vector(11 downto 0);
	signal pc_inc : std_logic;
	signal pc_dec : std_logic;
	signal pc_ld : std_logic;
	
	signal ras_data : std_logic_vector(11 downto 0);
	
	signal ptr_reg : std_logic_vector(9 downto 0);
	signal ptr_inc : std_logic;
	signal ptr_dec : std_logic;
	
	type FSMstate is (
		s_start,
		s_fetch,
		s_decode,
	
		s_ptr_inc,
		s_ptr_dec,
	
		s_value_inc,
		s_value_dec,
	
		s_while_start,
		s_while_end,
	
		s_output,
		s_input,
		
		s_value_inc_mx,
		s_value_inc_write,
		s_value_dec_mx,
		s_value_dec_write,
		
		s_output_final,
		s_input_final,
		
		s_while_end_check,
		s_while_check,
		s_while_skip,
		s_while_en,
	
		s_null
	);
	
	signal state : FSMstate := s_start;
	signal nstate : FSMstate;
	
	signal mx_select : std_logic_vector (1 downto 0) := (others => '0');
	signal mx_out : std_logic_vector (7 downto 0) := (others => '0');
	
begin

-- ----------------------------------------------------------------------------
--                      Program counter
-- ----------------------------------------------------------------------------
	pc_cntr: process (RESET, CLK, pc_inc, pc_dec, pc_ld)
	begin
	
		if(RESET='1') then
			pc_reg <= (others => '0');
		elsif (CLK'event) and (CLK='1') then
		
			if (pc_inc = '1') then
				pc_reg <= pc_reg + 1;
			elsif (pc_dec = '1') then
				pc_reg <= pc_reg - 1;
			elsif (pc_ld = '1') then
				pc_reg <= ras_data;
			end if;
			
		end if;
	end process;
	
	CODE_ADDR <= pc_reg;
-- ----------------------------------------------------------------------------
--                      Program counter
-- ----------------------------------------------------------------------------
 
-- ----------------------------------------------------------------------------
--                      Data pointer
-- ----------------------------------------------------------------------------
	ptr: process (RESET, CLK, pc_inc, pc_dec)
	begin
	
		if(RESET='1') then
			ptr_reg <= (others => '0');
		elsif (CLK'event) and (CLK='1') then
		
			if (ptr_inc = '1') then
				ptr_reg <= ptr_reg + 1;
			elsif (ptr_dec = '1') then
				ptr_reg <= ptr_reg - 1;
			end if;
			
		end if;
	end process;
	
	DATA_ADDR <= ptr_reg;
-- ----------------------------------------------------------------------------
--                      Data pointer
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
--                      Multiplexer
-- ----------------------------------------------------------------------------
	mux: process (RESET, CLK, mx_select)
	begin
	
		if (RESET='1') then
			mx_out <= (others => '0');
		elsif (CLK'event) and (CLK='1') then
				case mx_select is
			when "00" =>
					mx_out <= IN_DATA;
			when "01" =>
					mx_out <= DATA_RDATA + 1;
			when "10" =>
					mx_out <= DATA_RDATA - 1;
			when others =>
					mx_out <= (others => '0');
				end case;
		end if;
	end process;
	
	DATA_WDATA <= mx_out;
-- ----------------------------------------------------------------------------
--                      Multiplexer
-- ----------------------------------------------------------------------------

-- ----------------------------------------------------------------------------
--                    					  FSM
-- ----------------------------------------------------------------------------
	state_logic : process (RESET, CLK, EN)
	begin
	
		if (RESET='1') then
			state <= s_start;
		elsif (CLK'event) and (CLK='1') then
		
			if (EN = '1') then
				state <= nstate;
			end if;
			
		end if;
		
	end process;
	
	fsm : process (state, OUT_BUSY, IN_VLD, CODE_DATA, DATA_RDATA)
	begin
	
		-- inicializace
		pc_inc <= '0';
		pc_dec <= '0';
		pc_ld <= '0';
		
		ptr_inc <= '0';
		ptr_dec <= '0';
		
		CODE_EN <= '0';
		
		DATA_EN <= '0';
		DATA_WE <= '0';
		
		OUT_WE <= '0';
		
		IN_REQ <= '0';
		
		mx_select <= "00";
		-- inicializace
		
		case state is
			when s_start =>
					nstate <= s_fetch;
			when s_fetch =>
					CODE_EN <= '1';
					nstate <= s_decode;
			when s_decode =>
					case CODE_DATA is
							when X"3E" =>
									nstate <= s_ptr_inc;
							when X"3C" =>
									nstate <= s_ptr_dec;
									
							when X"2B" =>
									nstate <= s_value_inc;
							when X"2D" =>
									nstate <= s_value_dec;
									
							when X"5B" =>
									nstate <= s_while_start;
							when X"5D" =>
									nstate <= s_while_end;
									
							when X"2E" =>
									nstate <= s_output;
							when X"2C" =>
									nstate <= s_input;
									
							when X"00" =>
									nstate <= s_null;
									
							when others => 
									pc_inc <= '1';
									nstate <= s_fetch;
					end case;
					
			when s_ptr_inc =>
					ptr_inc <= '1';
					pc_inc <= '1';
				nstate <= s_fetch;
				
			when s_ptr_dec =>
					ptr_dec <= '1';
					pc_inc <= '1';
				nstate <= s_fetch;
			
			when s_value_inc => -- read
					DATA_EN <= '1';
					DATA_WE <= '0';
					nstate <= s_value_inc_mx;
			when s_value_inc_mx => -- inc
					mx_select <= "01";
					nstate <= s_value_inc_write;
			when s_value_inc_write => -- write
					DATA_EN <= '1';
					DATA_WE <= '1';
					pc_inc <= '1';
				nstate <= s_fetch;
					
			when s_value_dec => -- read
					DATA_EN <= '1';
					DATA_WE <= '0';
					nstate <= s_value_dec_mx;
			when s_value_dec_mx => -- inc
					mx_select <= "10";
					nstate <= s_value_dec_write;
			when s_value_dec_write => -- write
					DATA_EN <= '1';
					DATA_WE <= '1';
					pc_inc <= '1';
				nstate <= s_fetch;
			
			when s_output => --read
					DATA_EN <= '1';
					DATA_WE <= '0';
					nstate <= s_output_final;
			when s_output_final =>
					if (OUT_BUSY = '1') then -- waiting
							DATA_EN <= '1'; ---- 
							DATA_WE <= '0'; ---- 
							nstate <= s_output_final;
					else
					      OUT_DATA <= DATA_RDATA;
							OUT_WE <= '1'; -- output permission
							pc_inc <= '1';
						 nstate <= s_fetch;
					end if;
					
					when s_input =>
					IN_REQ <= '1';
					if (IN_VLD /= '1') then
						nstate <= s_input;
					else
						nstate <= s_input_final;
					end if;
			when s_input_final =>
					mx_select <= "00";
					DATA_EN <= '1';
					DATA_WE <= '1';
				nstate <= s_fetch;
					
			when s_while_end =>
					DATA_EN <= '1';
					DATA_WE <= '0';
					nstate <= s_while_end_check;
			when s_while_end_check =>
					if (DATA_RDATA = "00000000") then
							pc_inc <= '1';
						nstate <= s_fetch;
					else
							pc_ld <= '1';
						nstate <= s_fetch;
					end if;
					
			when s_while_start =>
					pc_inc <= '1';
					DATA_EN <= '1';
					DATA_WE <= '0';
					nstate <= s_while_check;
			
			when s_while_check =>
					if (DATA_RDATA /= "00000000") then
							ras_data <= pc_reg;
						nstate <= s_fetch;
					else
							CODE_EN <= '1';
							nstate <= s_while_skip;
					end if;
			
			when s_while_skip =>
					pc_inc <= '1';
					if (CODE_DATA = X"5D") then
							ras_data <= "000000000000";
							nstate <= s_fetch;
					else
							nstate <= s_while_en;
					end if;
					
			when s_while_en =>
					CODE_EN <= '1';
					nstate <= s_while_skip;
					
			when others => 
					null;
					
		end case;
		
	end process;
-- ----------------------------------------------------------------------------
--                    					  FSM
-- ----------------------------------------------------------------------------

end behavioral;