library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;

entity i2cTransceiver is
  port(
    send          : in std_logic;
    r_w           : in std_logic;
    ack           : in std_logic;
    addr          : in std_logic_vector(9 downto 0);
    data          : in std_logic_vector(7 downto 0);
    sda           : out std_logic := '1';
    scl           : out std_logic := '1';
    done          : out std_logic
  );
  constant bit_period : time := 20 us ; -- scl clock ~ 50 Khz max
end entity;

architecture arch of i2cTransceiver is
    constant frame10bitDefault : std_logic_vector(0 to 4) := "11110";
    signal frame10bitA : std_logic_vector(0 to 8);
    signal frame7bitA : std_logic_vector(0 to 8);
    signal frameData : std_logic_vector(0 to 8);
  begin
    frame10bitA <= frame10bitDefault & addr(9 downto 8) & r_w & ack;
    frame7bitA <=  addr(6 downto 0) & r_w & ack;
    frameData <=  data(7 downto 0) & ack;
    process
      begin
        wait until send = '1';
        done <= '0';

        wait for (bit_period);


        sda <= '0'; -- Start bit
        
        wait for (bit_period/2);
        scl <= '0';
        wait for (bit_period/2);
        
        if addr(9 downto 7) /= "000" then
          for i in 0 to 8 loop
            sda <= frame10bitA(i);
            
            wait for (bit_period/2);
            scl <= '1';   
            wait for (bit_period/2);
            scl <= '0';
          end loop;
          
          sda <= '1';
          wait for bit_period;
          sda <= '0';
          wait for bit_period;
        end if;

        for i in 0 to 8 loop
          sda <= frame7bitA(i);
          
          wait for (bit_period/2);
          scl <= '1';   
          wait for (bit_period/2);
          scl <= '0';
        end loop;

        sda <= '1';
        wait for bit_period;
        sda <= '0';
        wait for bit_period;

        for i in 0 to 8 loop
          sda <= frameData(i);
          
          wait for (bit_period/2);
          scl <= '1';   
          wait for (bit_period/2);
          scl <= '0';
        end loop;
      
        sda <= '1'; 
        wait for (bit_period/2);
        sda <= '0';
        wait for (bit_period/2);
        scl <= '1';
        wait for (bit_period/2);
        sda <= '1';

        done <= '1';
        
    end process;

end arch;