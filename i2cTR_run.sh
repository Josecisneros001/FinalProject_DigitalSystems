for i in {i2cTransceiver,i2cReceiver,i2cTR_tb}; do 
ghdl -a --ieee=synopsys $i.vhdl
ghdl -e --ieee=synopsys $i
done
ghdl -r --ieee=synopsys $i --stop-time=10ms --vcd=$i.vcd
gtkwave $i.vcd
