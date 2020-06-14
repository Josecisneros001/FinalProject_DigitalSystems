library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;

library std;
use std.textio.all;

entity i2c_tb is
  constant bit_period : time := 20 us ; -- scl clock ~ 50 Khz max
end entity;

architecture arch of i2c_tb is
  component i2cTransceiver is
    port(
      send          : in std_logic;
      r_w           : in std_logic;
      ack           : in std_logic;
      addr          : in std_logic_vector(9 downto 0);
      data          : in std_logic_vector(7 downto 0);
      sda           : out std_logic;
      scl           : out std_logic;
      done          : out std_logic
    );
  end component;
  signal send       : std_logic;
  signal r_w        : std_logic;
  signal ack        : std_logic;
  signal addr       : std_logic_vector(9 downto 0);
  signal data       : std_logic_vector(7 downto 0);
  signal sda        : std_logic := '1';
  signal scl        : std_logic := '1';
  signal done       : std_logic;

  type dataRecord is record
    address : std_logic_vector(9 downto 0);
    r_w : std_logic;
    ack : std_logic;
    data : std_logic_vector(7 downto 0);
  end record;

  type dataArray is array (natural range <>) of dataRecord;
  constant records : dataArray := (
                            (address => "0001010101", r_w => '0', ack => '1', data => "10101010"),
                            (address => "1100111101", r_w => '1', ack => '1', data => "10101101"),
                            (address => "0010111101", r_w => '0', ack => '1', data => "00011001")
                            );

  begin
    
    UUT : i2cTransceiver port map(send,r_w,ack,addr,data,sda,scl,done);

    process
    procedure send_code( sc : dataRecord ) is
    begin
      addr <= sc.address;
      r_w <= sc.r_w;
      ack <= sc.ack;
      data <= sc.data;
      send <= '1';
      wait for bit_period;
      send <= '0';
      wait until done = '1';
      wait for bit_period*5;
    end procedure send_code;

    begin
        for i in records'range loop
            send_code(records(i));
        end loop;
        wait;
    end process;

end arch;