library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;

entity master is
  port(
    send          : in std_logic;
    r_w           : in std_logic;
    addr          : in std_logic_vector(9 downto 0);
    addrData      : in std_logic_vector(7 downto 0);
    dataIn        : in std_logic_vector(7 downto 0);
    sda           : inout std_logic := '1';
    scl           : out std_logic := '1';
    dataOut       : out std_logic_vector(7 downto 0);
    done          : out std_logic;
    ack_error     : out std_logic := '0'
  );
  constant bit_period : time := 20 us ; -- scl clock ~ 50 Khz max
end entity;

architecture arch of master is
    constant frame10bitDefault  : std_logic_vector(0 to 4) := "11110";
    signal sdaInt               : std_logic := '1';
    signal sdaEnaM              : std_logic := '1';
    signal frame10bitAddress1   : std_logic_vector(0 to 7);
    signal frame10bitAddress2   : std_logic_vector(0 to 7);
    signal frame7bitAddress     : std_logic_vector(0 to 7);
    signal frameRegAddress      : std_logic_vector(0 to 7);
    signal frameData            : std_logic_vector(0 to 7);
  begin
    frame10bitAddress1 <= frame10bitDefault & addr(9 downto 8) & r_w;
    frame10bitAddress2 <= addr(7 downto 0);
    frame7bitAddress <=  addr(6 downto 0) & r_w;
    frameRegAddress <=  addrData(7 downto 0);
    frameData <=  dataIn(7 downto 0);
    process
      begin
        wait until send = '1';
        done <= '0';
        ack_error <= '0';
        sdaEnaM <= '1';

        wait for (bit_period);

        sdaInt <= '0'; -- Start bit
        
        wait for (bit_period/2);
        scl <= '0';
        wait for (bit_period/2);
        
        if addr(9 downto 7) /= "000" then
          for i in 0 to 7 loop
            sdaInt <= frame10bitAddress1(i);
            
            wait for (bit_period/2);
            scl <= '1';  
            if i = 7 then
              wait for (bit_period/8);
              sdaInt <= '1';
              wait for (bit_period/8);
              sdaEnaM <= '0';
              wait for (bit_period/4);
            else
              wait for (bit_period/2);
            end if; 
            scl <= '0';
          end loop;
          
          wait for (bit_period/2);
          
          if sda /= '0' then
            ack_error <= '1';
          end if;

          scl <= '1';   
          wait for (bit_period/2);
          scl <= '0';
          sdaEnaM <= '1';
          
          sdaInt <= '1';
          wait for bit_period;
          --END FRAME
          sdaInt <= '0';
          wait for bit_period;
        end if;

        for i in 0 to 7 loop
          if addr(9 downto 7) /= "000" then
            sdaInt <= frame10bitAddress2(i);
          else
            sdaInt <= frame7bitAddress(i);
          end if;

          wait for (bit_period/2);
          scl <= '1';  
          if i = 7 then
            wait for (bit_period/8);
            sdaInt <= '1';
            wait for (bit_period/8);
            sdaEnaM <= '0';
            wait for (bit_period/4);
          else
            wait for (bit_period/2);
          end if; 
          scl <= '0';
        end loop;
        
        
        wait for (bit_period/2);
        
        if sda /= '0' then
          ack_error <= '1';
        end if;

        scl <= '1';   
        wait for (bit_period/2);
        scl <= '0';
        sdaEnaM <= '1';
        
        sdaInt <= '1';
        wait for bit_period;
        --END FRAME
        sdaInt <= '0';
        wait for bit_period;

        for i in 0 to 7 loop
          sdaInt <= frameRegAddress(i);
          
          wait for (bit_period/2);
          scl <= '1';   
          if i = 7 then
            wait for (bit_period/8);
            sdaInt <= '1';
            wait for (bit_period/8);
            sdaEnaM <= '0';
            wait for (bit_period/4);
          else
            wait for (bit_period/2);
          end if;
          scl <= '0';
        end loop;

        wait for (bit_period/2);
        
        if sda /= '0' then
          ack_error <= '1';
        end if;

        scl <= '1';   
        wait for (bit_period/2);
        scl <= '0';
        sdaEnaM <= '1';
        
        sdaInt <= '1';
        wait for bit_period;
        --END FRAME
        sdaInt <= '0';
        if r_w = '1' then
          sdaEnaM <= '0';
        end if;
        wait for bit_period;

        if r_w = '1' then
          for i in 0 to 7 loop   
            wait for (bit_period/2);
            dataOut(7-i) <= sda;
            scl <= '1';   
            wait for (bit_period/2);
            scl <= '0';
          end loop;
        else 
          for i in 0 to 7 loop   
            sdaInt <= frameData(i);
            wait for (bit_period/2);
            scl <= '1';   
            if i = 7 then
              wait for (bit_period/8);
              sdaInt <= '1';
              wait for (bit_period/8);
              sdaEnaM <= '0';
              wait for (bit_period/4);
            else
              wait for (bit_period/2);
            end if;
            scl <= '0';
          end loop;
        end if;
        

        wait for (bit_period/2);
        
        if sda /= '0' then
          ack_error <= '1';
        end if;

        scl <= '1';   
        wait for (bit_period/2);
        scl <= '0';
        sdaEnaM <= '1';    
        
        sdaInt <= '1'; 
        wait for (bit_period/2);
        --END FRAME
        sdaInt <= '0';
        wait for (bit_period/2);
        scl <= '1';
        wait for (bit_period/2);
        sdaInt <= '1';

        done <= '1';
        
    end process;
    
    sda <= 'Z' when sdaEnaM = '0' else sdaInt;

end arch;