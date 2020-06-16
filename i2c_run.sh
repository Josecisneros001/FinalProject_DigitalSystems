for i in {master,slave,i2c}; do 
ghdl -a --ieee=synopsys $i.vhdl
ghdl -e --ieee=synopsys $i
done
ghdl -r --ieee=synopsys $i --stop-time=10ms --vcd=$i.vcd
gtkwave $i.vcd
