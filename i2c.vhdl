library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;

library std;
use std.textio.all;

entity i2c is
  constant bit_period : time := 20 us ; -- scl clock ~ 50 Khz max
end entity;

architecture arch of i2c is
  component master is
    port(
      send          : in std_logic;
      r_w           : in std_logic;
      addr          : in std_logic_vector(9 downto 0);
      addrData      : in std_logic_vector(7 downto 0);
      dataIn        : in std_logic_vector(7 downto 0);
      sda           : inout std_logic;
      scl           : out std_logic;
      dataOut       : out std_logic_vector(7 downto 0);
      done          : out std_logic;
      ack_error     : out std_logic
    );
  end component;

  signal send          : std_logic;
  signal r_w           : std_logic;
  signal addr          : std_logic_vector(9 downto 0);
  signal addrData      : std_logic_vector(7 downto 0);
  signal dataIn        : std_logic_vector(7 downto 0);
  signal sda           : std_logic := '1';
  signal scl           : std_logic := '1';
  signal dataOut       : std_logic_vector(7 downto 0);
  signal done          : std_logic := '0';
  signal ack_error     : std_logic;
  
  component slave is
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
  end component;
  
  type slavesData is record
    address : std_logic_vector(9 downto 0);
    addrReceived    : std_logic_vector(9 downto 0);
    addrRamReceived : std_logic_vector(7 downto 0);
    dataReceived    : std_logic_vector(7 downto 0);
  end record;

  type slavesArray is array (0 to 1) of slavesData;
  signal slavesSignals : slavesArray := (
                            (address => "1001111111", addrReceived => (others => '0'), addrRamReceived => (others => '0'), dataReceived => (others => '0')),
                            (address => "0001111111", addrReceived => (others => '0'), addrRamReceived => (others => '0'), dataReceived => (others => '0'))
                          );

  type dataRecord is record
    address : std_logic_vector(9 downto 0);
    r_w :     std_logic;
    addrData :std_logic_vector(7 downto 0);
    data :    std_logic_vector(7 downto 0);
  end record;

  begin
    
    MAS : master port map(send,r_w,addr,addrData,dataIn,sda,scl,dataOut,done,ack_error);
    SLV0 : slave  generic map(slavesSignals(0).address)
                  port map(scl,sda,slavesSignals(0).addrReceived,slavesSignals(0).addrRamReceived,slavesSignals(0).dataReceived);
    SLV1 : slave  generic map(slavesSignals(1).address)
                  port map(scl,sda,slavesSignals(1).addrReceived,slavesSignals(1).addrRamReceived,slavesSignals(1).dataReceived);
    

    process
      file fin : TEXT open READ_MODE is "input.txt";
      variable current_read_line : line;
      variable actualRecord : dataRecord := (address => (others=>'0'), r_w => '0', addrData => (others=>'0'), data => (others=>'0'));
    begin
        readline(fin,current_read_line);
        while (not endfile(fin)) loop
            readline(fin,current_read_line);
            read(current_read_line, actualRecord.address);
            read(current_read_line, actualRecord.r_w);
            read(current_read_line, actualRecord.addrData);
            read(current_read_line, actualRecord.data);
            addr <= actualRecord.address;
            r_w <= actualRecord.r_w;
            addrData <= actualRecord.addrData;
            dataIn <= actualRecord.data;
            send <= '1';
            wait for bit_period;
            send <= '0';
            wait until done = '1';
            wait for bit_period*5;
        end loop ; 
        wait;
    end process;


    process
      variable l : line;
      variable slaveIndex : integer := 0;
      variable count : integer := 1;

    begin
        wait until done = '1';
        
        for i in slavesSignals'range loop
          if slavesSignals(i).address = addr then
            slaveIndex := i;
          end if;
        end loop;

        write (l, string'("Command "));
        write (l, count);
        if r_w = '1' then 
          write (l, string'(": Read"));
        else 
          write (l, string'(": Write"));
        end if;
        writeline(output, l);
        
        write (l, string'("Addres Device send (master) -> "));
        write (l, addr);
        writeline(output, l);
        write (l, string'("Addres Memory send (master) -> "));
        write (l, addrData);
        writeline(output, l);
        if r_w = '0' then
          write (l, string'("Data send (master) -> "));
          write (l, dataIn);
          writeline(output, l);
        end if;
        
        if ack_error = '1' then
          write (l, string'("ACKNOWLEDGE ERROR"));
          writeline(output, l);  
        else 

          write (l, string'("Addres Device received (slave) -> "));
          write (l, slavesSignals(slaveIndex).addrReceived);
          writeline(output, l);
          write (l, string'("Addres Memory received (slave) -> "));
          write (l, slavesSignals(slaveIndex).addrRamReceived);
          writeline(output, l);
          
          if r_w = '1' then
            write (l, string'("Data received (master) -> "));
            write (l, dataOut);
            writeline(output, l);
          else 
            write (l, string'("Data received (slave) -> "));
            write (l, slavesSignals(slaveIndex).dataReceived);
            writeline(output, l);
          end if;
            
        end if;
        count := count + 1;
    end process;
        
end arch;