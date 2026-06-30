## Two_Digit_Counter.xdc
## Nexys A7-100T constraints
##
## Port usage:
##   CLK        -> 100 MHz board clock
##   START_STOP -> SW0
##   CLR        -> SW1
##   SEG        -> seven segment cathodes, active low
##   AN         -> seven segment anodes, active low
##   DP         -> decimal point, active low

## Clock
set_property -dict { PACKAGE_PIN W5 IOSTANDARD LVCMOS33 } [get_ports CLK]
create_clock -period 10.000 -name sys_clk_pin -waveform {0.000 5.000} [get_ports CLK]

## Switches
set_property -dict { PACKAGE_PIN J15 IOSTANDARD LVCMOS33 } [get_ports START_STOP]
set_property -dict { PACKAGE_PIN L16 IOSTANDARD LVCMOS33 } [get_ports CLR]

## Seven segment cathodes
## VHDL mapping: SEG(6)=CA, SEG(5)=CB, SEG(4)=CC, SEG(3)=CD, SEG(2)=CE, SEG(1)=CF, SEG(0)=CG
set_property -dict { PACKAGE_PIN T10 IOSTANDARD LVCMOS33 } [get_ports {SEG[6]}]
set_property -dict { PACKAGE_PIN R10 IOSTANDARD LVCMOS33 } [get_ports {SEG[5]}]
set_property -dict { PACKAGE_PIN K16 IOSTANDARD LVCMOS33 } [get_ports {SEG[4]}]
set_property -dict { PACKAGE_PIN K13 IOSTANDARD LVCMOS33 } [get_ports {SEG[3]}]
set_property -dict { PACKAGE_PIN P15 IOSTANDARD LVCMOS33 } [get_ports {SEG[2]}]
set_property -dict { PACKAGE_PIN T11 IOSTANDARD LVCMOS33 } [get_ports {SEG[1]}]
set_property -dict { PACKAGE_PIN L18 IOSTANDARD LVCMOS33 } [get_ports {SEG[0]}]

## Decimal point
set_property -dict { PACKAGE_PIN H15 IOSTANDARD LVCMOS33 } [get_ports DP]

## Seven segment anodes
set_property -dict { PACKAGE_PIN U13 IOSTANDARD LVCMOS33 } [get_ports {AN[0]}]
set_property -dict { PACKAGE_PIN K2  IOSTANDARD LVCMOS33 } [get_ports {AN[1]}]
set_property -dict { PACKAGE_PIN T14 IOSTANDARD LVCMOS33 } [get_ports {AN[2]}]
set_property -dict { PACKAGE_PIN P14 IOSTANDARD LVCMOS33 } [get_ports {AN[3]}]
set_property -dict { PACKAGE_PIN J14 IOSTANDARD LVCMOS33 } [get_ports {AN[4]}]
set_property -dict { PACKAGE_PIN T9  IOSTANDARD LVCMOS33 } [get_ports {AN[5]}]
set_property -dict { PACKAGE_PIN J18 IOSTANDARD LVCMOS33 } [get_ports {AN[6]}]
set_property -dict { PACKAGE_PIN J17 IOSTANDARD LVCMOS33 } [get_ports {AN[7]}]
