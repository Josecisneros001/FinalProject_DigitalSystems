for i in {i2cReceiver,i2cTransceiver,i2c_tb}; do 
ghdl -a --ieee=synopsys $i.vhdl
ghdl -e --ieee=synopsys $i
done
ghdl -r --ieee=synopsys $i --stop-time=4ms --vcd=$i.vcd
gtkwave $i.vcd
