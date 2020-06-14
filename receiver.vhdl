library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity i2cReceiver is 
  port(
    sda           : in std_logic;
    scl           : in std_logic;
    reset         : in std_logic;
    enable        : in std_logic;
    scanReady     : out std_logic;
    addrReceived  : out std_logic_vector(9 downto 0);
    dataReceived  : out std_logic_vector(7 downto 0)
  );
  constant filterPeriod : time := 40 ns ; -- Señal de reloj de 25MHz
end entity;

architecture arch of i2cReceiver is
  signal filterClk : std_logic := '0';
  signal filterScl : std_logic_vector(7 downto 0) := "00000000";
  signal filteredScl : std_logic := '0';
  
  signal read_char        : std_logic := '0';
  signal read_address     : std_logic := '0';
  signal ready_set        : std_logic := '0';
  signal incount          : unsigned(3 downto 0) := "0000";
  signal shiftinFrame     : std_logic_vector(9 downto 0) := "000000000";
  signal frameNumber      : unsigned(1 downto 0) := "00";
  signal frameDir         : unsigned(4 downto 0) := "00000";
  signal bitAddress10     : std_logic := '0';
  signal r_w              : std_logic := '0';
  signal ack              : std_logic := '0';
begin
  filterClk <= not filterClk after (filterPeriod / 2);
    
  scl_filter : process
  begin
      wait until filterClk'event and filterClk = '1';
      
      filterScl <= scl & filterScl(7 downto 1);
      
      if filterScl = x"FF" then 
        filteredScl <= '1';
      elsif filterScl = x"00" then
        filteredScl <= '0';
      end if;

  end process;
 
  process
  begin
      wait until (filteredScl'event and filteredScl = '0');
      if reset = '1' then
        incount <= "0000";
        read_char <= '0';
      else
        if sda = '0' and read_char = '0' then
          read_char <= '1';
          ready_set <= '0';
        else
          if read_char = '1' then
            if incount < "1001" then
                
                bitAddress10 <= '1' when incount = "1001" and shiftinFrame(9 downto 5) = "11110";
                incount <= incount+1;
                shiftinFrame(8 downto 0) <= shiftinFrame(9 downto 1);
                shiftinFrame(9) <= sda;
                ready_set <= '0';

            else
               
                if bitAddress10 = '1' then 
                    if frameNumber <= "00" then
                        addrReceived(9 downto 8) <= shiftinFrame(4 downto 3);
                    elsif frameNumber <= "01" then 
                        addrReceived(7 downto 0) <= shiftinFrame(9 downto 2);
                    else 
                        dataReceived(7 downto 0) <= shiftinFrame(9 downto 2);
                        read_char <= '0';
                        ready_set <= '1';
                    end if;
                else 
                    if frameNumber <= "00" then 
                        addrReceived(6 downto 0) <= shiftinFrame(9 downto 3);
                    else 
                        dataReceived(7 downto 0) <= shiftinFrame(9 downto 2);
                        read_char <= '0';
                        ready_set <= '1';
                    end if;
                end if;
                
                r_w <= shiftinFrame(2) when frameNumber = "00";
                ack <= shiftinFrame(1);

                if ack = '1' then 
                        -- marcar error
                end if;

                incount <= "0000";
                frameNumber <= frameNumber+1;
              
            end if;
          end if;
      end if;
    end if;
  end process;

  process (enable, ready_set)
  begin
    if enable = '1' then
      scanReady <= '0';
    elsif ready_set'event then
      scanReady <= ready_set;
    end if;
  end process;

end arch;