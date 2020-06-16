library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity slave is
  generic(
    address     : std_logic_vector(9 downto 0)
  ); 
  port(
    scl             :  in std_logic;
    sda             :  inout std_logic;
    addrReceived    :  out std_logic_vector(9 downto 0) := "0000000000";
    addrRamReceived :  out std_logic_vector(7 downto 0) := "00000000";
    dataReceived    :  out std_logic_vector(7 downto 0) := "00000000"
  );
  constant filterPeriod : time := 40 ns ; -- Señal de reloj de 25MHz
  constant bit_period : time := 20 us ; -- scl clock ~ 50 Khz max
end entity;

architecture arch of slave is
  signal filterClk : std_logic := '0';
  signal filterScl : std_logic_vector(7 downto 0) := "00000000";
  signal filteredScl : std_logic := '0';
  
  type RAMArray is array (0 to 255) of std_logic_vector(7 downto 0);
  signal RAM : RAMArray := (others => "00000000");

  signal sdaInt              : std_logic := '1';
  signal sdaEnaS             : std_logic := '0';
  signal read_char           : std_logic := '0';
  signal read_address        : std_logic := '0';
  signal incount             : unsigned(3 downto 0) := "0000";
  signal shiftinFrame        : std_logic_vector(7 downto 0) := "00000000";
  signal frameNumber         : unsigned(1 downto 0) := "00";
  signal frameDir            : unsigned(4 downto 0) := "00000";
  signal addrRamReceivedint  : std_logic_vector(7 downto 0) := "00000000";
  signal addrReceivedint     : std_logic_vector(9 downto 0) := "0000000000";
  signal addrRamReceivedintU : unsigned(7 downto 0) := "00000000";
  signal bitAddress10        : std_logic := '0';
  signal r_w                 : std_logic := '0';
  signal ack                 : std_logic := '0';
begin
  addrReceived <= addrReceivedint;
  addrRamReceived <= addrRamReceivedint;
  addrRamReceivedintU <= unsigned(addrRamReceivedint);
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
      wait until filteredScl'event;
      if sda = '0' and read_char = '0' and filteredScl = '0' then
        read_char <= '1';
        r_w <= '0';
        incount <= "0000";
        frameNumber <= "00";
        bitAddress10 <= '0';
        shiftinFrame <= "00000000";
      else if filteredScl = '1' then
        if read_char = '1' then
          if incount < "1001" then
              if frameNumber = "00" and incount = "0101" and shiftinFrame(4 downto 0) = "11110" then
                bitAddress10 <= '1';
              end if;
            
              shiftinFrame(7 downto 1) <= shiftinFrame(6 downto 0);
              shiftinFrame(0) <= sda;
              wait for 0 ns;
              if incount = "0111" then
                -- START HANDLE ACK
                if bitAddress10 = '1' then
                  if frameNumber = "00" then
                    if address(9 downto 8) = shiftinFrame(2 downto 1) then
                      wait for (bit_period/4);sdaEnaS <= '1';wait for (bit_period/4); sdaInt <= '0';wait for (bit_period);sdaEnaS <= '0';
                    else
                      wait for (bit_period/4);wait for (bit_period/4);wait for (bit_period);
                    end if;
                  elsif frameNumber = "01" then
                    if address(9 downto 8) = addrReceivedint(9 downto 8) and address(7 downto 0) = shiftinFrame(7 downto 0) then
                      wait for (bit_period/4);sdaEnaS <= '1';wait for (bit_period/4); sdaInt <= '0';wait for (bit_period);sdaEnaS <= '0';
                    else
                      wait for (bit_period/4);wait for (bit_period/4);wait for (bit_period);
                    end if;  
                  else
                    if address = addrReceivedint then
                      wait for (bit_period/4);sdaEnaS <= '1';wait for (bit_period/4); sdaInt <= '0';wait for (bit_period);sdaEnaS <= '0';
                    else
                      wait for (bit_period/4);wait for (bit_period/4);wait for (bit_period);
                    end if; 
                  end if;
                else
                  if frameNumber = "00" then
                    if address(6 downto 0) = shiftinFrame(7 downto 1) and address(9 downto 7) = "000" then
                      wait for (bit_period/4);sdaEnaS <= '1';wait for (bit_period/4); sdaInt <= '0';wait for (bit_period);sdaEnaS <= '0';
                    else
                      wait for (bit_period/4);wait for (bit_period/4);wait for (bit_period);
                    end if;  
                  else
                    if address = addrReceivedint then
                      wait for (bit_period/4);sdaEnaS <= '1';wait for (bit_period/4); sdaInt <= '0';wait for (bit_period);sdaEnaS <= '0';
                    else
                      wait for (bit_period/4);wait for (bit_period/4);wait for (bit_period);
                    end if;  
                  end if;
                end if;
                -- END HANDLE ACK
                -- START HANDEL END OF FRAME
                if bitAddress10 = '1' then 
                    if frameNumber = "00" then
                      addrReceivedint(9 downto 8) <= shiftinFrame(2 downto 1);
                    elsif frameNumber = "01" then 
                      addrReceivedint(7 downto 0) <= shiftinFrame(7 downto 0);
                    elsif frameNumber = "10" then
                      addrRamReceivedint(7 downto 0) <= shiftinFrame(7 downto 0);
                      if r_w = '1' and address = addrReceivedint then
                        wait for bit_period;
                        sdaEnaS <= '1';
                        wait for bit_period;
                        for i in 0 to 7 loop   
                          sdaInt <= RAM(TO_INTEGER(addrRamReceivedintU))(7-i);
                          wait for bit_period;
                        end loop;
                        sdaInt <= '0';
                        wait for bit_period;
                        sdaEnaS <= '0';
                        read_char <= '0';
                      end if;
                    else 
                      if r_w = '0' and address = addrReceivedint then
                        RAM(TO_INTEGER(addrRamReceivedintU)) <= shiftinFrame(7 downto 0);
                      end if;
                      dataReceived(7 downto 0) <= shiftinFrame(7 downto 0);
                      sdaEnaS <= '0';
                      read_char <= '0';
                    end if;
                else 
                  if frameNumber = "00" then
                    addrReceivedint <= "000" & shiftinFrame(7 downto 1);
                  elsif frameNumber = "01" then
                    addrRamReceivedint(7 downto 0) <= shiftinFrame(7 downto 0);
                    if r_w = '1' and address = addrReceivedint then
                      wait for bit_period;
                      sdaEnaS <= '1';
                      wait for bit_period;
                      for i in 0 to 7 loop   
                        sdaInt <= RAM(TO_INTEGER(addrRamReceivedintU))(7-i);
                        wait for bit_period;
                      end loop;
                      sdaInt <= '0';
                      wait for bit_period;
                      sdaEnaS <= '0';
                      read_char <= '0';
                    end if;
                  else 
                    if r_w = '0' and address = addrReceivedint then
                      RAM(TO_INTEGER(addrRamReceivedintU)) <= shiftinFrame(7 downto 0);
                    end if;
                    dataReceived(7 downto 0) <= shiftinFrame(7 downto 0);
                    sdaEnaS <= '0';
                    read_char <= '0';
                  end if;
                end if;
                
                if frameNumber = "00" then
                  r_w <= shiftinFrame(0);
                end if;
                
                incount <= "0000";
                frameNumber <= frameNumber+1;
                -- END HANDEL END OF FRAME
              else
                incount <= incount+1;
              end if;
          end if;
        end if;
      end if;
    end if;
  end process;

  sda <= 'Z' when sdaEnaS = '0' else sdaInt;

end arch;