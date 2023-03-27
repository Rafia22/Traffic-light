library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity Traffic is
    Port ( Reset      : in   STD_LOGIC;
           Clock      : in   STD_LOGIC;
           
           -- for debug
           debugLED   : out  std_logic;
           LEDs       : out  std_logic_vector(2 downto 0);

           -- Car and pedestrian buttons
           CarEW      : in   STD_LOGIC; -- Car on EW road
           CarNS      : in   STD_LOGIC; -- Car on NS road
           PedEW      : in   STD_LOGIC; -- Pedestrian moving EW (crossing NS road)
           PedNS      : in   STD_LOGIC; -- Pedestrian moving NS (crossing EW road)
           
           -- Light control
           LightsEW   : out STD_LOGIC_VECTOR (1 downto 0); -- controls EW lights
           LightsNS   : out STD_LOGIC_VECTOR (1 downto 0)  -- controls NS lights
           
           );
end Traffic;

architecture Behavioral of Traffic is

-- Encoding for lights
constant RED   : std_logic_vector(1 downto 0) := "00";
constant AMBER : std_logic_vector(1 downto 0) := "01";
constant GREEN : std_logic_vector(1 downto 0) := "10";
constant WALK  : std_logic_vector(1 downto 0) := "11";

type StateType is (NSGreenPW, NSAmber, EWGreenPW, EWAmber, NSGreenCS, EWGreenCS);

signal state, NextState : StateType;
signal clearCounter :STD_LOGIC;
signal AmberCount   :STD_LOGIC;
signal GreenCount   :STD_LOGIC;
signal WalkCount    :STD_LOGIC;
signal enPedNS, enPedEW, clearPedNS,clearPedEW : STD_LOGIC;  --to enable ped buttons
begin

	theCounter:
	entity work.Counter
   port Map (
           Reset     => Reset,
           Clock     => Clock,
           
           -- Counter control
           clear   => clearCounter, 

           AmberLight  => AmberCount,  
			  GreenLight  => GreenCount, 
           WalkLight  =>  WalkCount  
           );
     
 
   -- Show reset status on FPGA LED
   debugLed <= Reset; 
   
   -- Threee LEDs for debug 
   LEDs     <= "000";
	
	SP:
	process (Reset, Clock)
	
	begin
		if (Reset = '1') then
			state <= EWGreenCS;
			enPedNS <= '0';
			enPedEW <= '0';
		elsif rising_edge (Clock) then
			state <= NextState;
			if (PedNS ='1') then
				enPedNS <= '1';
		   elsif (PedEW = '1') then
				enPedEW <= '1';
			end if;
			
			if (clearPedNS='1') then
				enPedNS <= '0';
			elsif (clearPedEW='1') then
				enPedEW <= '0';
			end if;
			 
		end if;
	end process SP;
   
	CP:
	process(state, CarEW, CarNS, enPedEW, enPedNS, WalkCount,GreenCount,AmberCount)
	
	begin 
	--adding default values to signals to prevent latches
	LightsNS <= RED;
	LightsEW <= RED;
	clearCounter <= '0';
	NextState <= state;
	
	case state is 
		when NSGreenPW => 
		LightsNS <= WALK;
		if (WalkCount = '1') then
			if (CarEW='1') or (PedEW='1') then
				NextState <= NSAmber;
				clearPedNS <= '1';
				clearCounter <= '1';
			end if;
			
		end if;
 
	 when NSAmber => 
	 LightsNS <= AMBER;
	 if (AmberCount ='1') then
		if (enPedEW ='1') then
			NextState <= EWGreenPW;
			clearCounter <= '1';
		elsif (enPedEW ='0') then
			NextState <= EWGreenCS;
			clearCounter <= '1';
		elsif (enPedNS = '1') then
			NextState <= EWGreenCS;
			clearCounter <= '1';
		end if;
		
	 end if;
	 
	 when EWGreenCS =>
	 LightsEW <= GREEN;
	 if (GreenCount = '1') then
		if (enPedNS = '1') or (CarNS = '1') then
			NextState <= EWAmber;
			clearCounter <= '1';
		elsif (enPedEW ='1') then
			NextState <= EWAmber;
			clearCounter <= '1';
		end if;
		
	 end if;  
	 
	 when EWGreenPW => 
	 LightsEW <= WALK;
	 if (WalkCount = '1') then
		if (enPedNS = '1') or (CarNS = '1')then
			NextState <= EWAmber;
			clearPedEW <= '1';
			clearCounter <= '1';
		end if;
		
	 end if;
   
	 when EWAmber =>   
	 LightsEW <= AMBER;
	 if (AmberCount = '1') then
		if (enPedNS ='1') then
			NextState <= NSGreenPW;
			clearCounter <= '1';
		elsif (enPedNS ='0') then
			NextState <= NSGreenCS;
			clearCounter <= '1';
		elsif (enPedEW = '1') then
			NextState <= NSGreenCS;
			clearCounter <= '1';
		end if;
		
	 end if;
	 
	 when NSGreenCS => 
	 LightsNS <= GREEN;
	 if (GreenCount = '1') then
		if (CarEW = '1') or (enPedEW = '1') then
			NextState <= NSAmber;
			clearCounter <= '1';
		elsif (enPedNS = '1') then
			NextState <= NSAmber;
			clearCounter <= '1';
		end if;
		
	 end if;

   end case;
	
	end process;
   
end Behavioral;