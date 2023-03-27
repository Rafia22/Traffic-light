library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity Counter is
    Port ( Reset     : in   STD_LOGIC;
           Clock     : in   STD_LOGIC;
           
           clear     : in   STD_LOGIC; -- Clear counter to zero
           
           GreenLight    : out  STD_LOGIC; -- GreenLight Count equals 500
			  WalkLight     : out  STD_LOGIC; -- WalkLight Count equals 300											
           AmberLight    : out  STD_LOGIC  -- AmberLight Count equals 200      
           );
end Counter;

architecture Behavioral of Counter is

signal count : natural range 0 to 800;

begin

   process (reset, clock)
   begin

      if (reset = '1') then
         count <= 1;
      elsif rising_edge(clock) then
         if (clear = '1') then
            count <= 1;
         else
            count <= count+1;
         end if;
      end if;

   end process;
   
   -- No need to register outputs as state machine changes state immediately
   GreenLight <= '1' when (count = 800) else '0';
   AmberLight <= '1' when (count = 200) else '0';
   WalkLight  <= '1' when (count = 300) else '0';
end Behavioral;

