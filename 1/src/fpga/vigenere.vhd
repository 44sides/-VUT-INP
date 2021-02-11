library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_arith.all;
use IEEE.std_logic_unsigned.all;

---------- INTERFACE Vigenerovy sifry ----------
entity vigenere is
   port(
         CLK : in std_logic;
         RST : in std_logic;
			
         DATA : in std_logic_vector(7 downto 0);
         KEY : in std_logic_vector(7 downto 0);

         CODE : out std_logic_vector(7 downto 0)
    );
end vigenere;

architecture behavioral of vigenere is

---------- SIGNALS ----------
    signal offset : std_logic_vector(7 downto 0);
	 signal plusMod : std_logic_vector(7 downto 0);
	 signal minusMod : std_logic_vector(7 downto 0);
	 
	 type FSMstate is (plus, minus);
	 signal presState : FSMstate;
	 signal nextState : FSMstate;
	 
	 signal fsmOutput_logic : std_logic_vector(1 downto 0);
	 
	 signal hashtag: std_logic_vector(7 downto 0) := "00100011";
---------- SIGNALS ----------
	 
begin

---------- SHIFTING ----------
    offsetProcess : process (DATA, KEY) is
	 begin
			offset <= KEY - 64;
	 end process;
	 
	 plusModProcess : process (offset, DATA) is
			variable cipher : std_logic_vector(7 downto 0);
	 begin
			cipher := DATA;
			cipher := cipher + offset;
			
			if (cipher > 90) then
				cipher:= 64 + (cipher - 90);
			end if;
			
			plusMod <= cipher;
	 end process;


	 minusModProcess : process (offset, DATA) is
			variable cipher : std_logic_vector(7 downto 0);
	 begin
			cipher := DATA;
			cipher := cipher - offset;
			
			if (cipher < 65) then
				cipher:= 91 - (65 - cipher);
			end if;
			
			minusMod <= cipher;
	 end process;
---------- SHIFTING ----------

---------- MEALY MACHINE ----------
--Present state
    stateLogic: process (CLK, RST) is
	 begin
			if RST = '1' then
				presState <= plus;
			elsif (CLK'event) and (CLK='1') then
				presState <= nextState;
			end if;
	 end process;

--Next State Logic, Output Logic
	 fsmMealy: process (presState, DATA, RST) is
	 begin
			--default values
			nextState <= presState;
			
			--nextState
			case presState is
				when plus =>
					nextState <= minus;
					fsmOutput_logic <= "01";
				when minus =>
					nextState <= plus;
					fsmOutput_logic <= "10";
			end case;
			
			if (DATA > 47 and DATA < 58) then
				fsmOutput_logic <= "00";
			end if;
			
			if RST = '1' then
				fsmOutput_logic <= "00";
			end if;
			
	 end process;
---------- MEALY MACHINE ----------
	 
---------- MULTIPLEXER ----------
	 with fsmOutput_logic select
		CODE <= plusMod when "01",
				  minusMod when "10",
				  hashtag when others;
---------- MULTIPLEXER ----------

end behavioral;