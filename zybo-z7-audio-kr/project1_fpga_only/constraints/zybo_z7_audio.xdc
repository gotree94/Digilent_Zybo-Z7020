# zybo_z7_audio.xdc
# Constraints file for Zybo Z7-20 Audio Project

## Clock Signal
set_property -dict {PACKAGE_PIN K17 IOSTANDARD LVCMOS33} [get_ports clk_100mhz]
create_clock -period 10.000 -name sys_clk -waveform {0.000 5.000} [get_ports clk_100mhz]

## Reset (BTN0)
set_property -dict {PACKAGE_PIN K18 IOSTANDARD LVCMOS33} [get_ports rst_n]

## I2C for Audio Codec
set_property -dict {PACKAGE_PIN N18 IOSTANDARD LVCMOS33} [get_ports i2c_scl]
set_property -dict {PACKAGE_PIN N17 IOSTANDARD LVCMOS33} [get_ports i2c_sda]

## Audio Codec Signals
set_property -dict {PACKAGE_PIN T19 IOSTANDARD LVCMOS33} [get_ports ac_mclk]
set_property -dict {PACKAGE_PIN K18 IOSTANDARD LVCMOS33} [get_ports ac_bclk]
set_property -dict {PACKAGE_PIN K17 IOSTANDARD LVCMOS33} [get_ports ac_recdat]
set_property -dict {PACKAGE_PIN M17 IOSTANDARD LVCMOS33} [get_ports ac_reclrc]
set_property -dict {PACKAGE_PIN M18 IOSTANDARD LVCMOS33} [get_ports ac_pbdat]
set_property -dict {PACKAGE_PIN L17 IOSTANDARD LVCMOS33} [get_ports ac_pblrc]

## LEDs
set_property -dict {PACKAGE_PIN M14 IOSTANDARD LVCMOS33} [get_ports {led[0]}]
set_property -dict {PACKAGE_PIN M15 IOSTANDARD LVCMOS33} [get_ports {led[1]}]
set_property -dict {PACKAGE_PIN G14 IOSTANDARD LVCMOS33} [get_ports {led[2]}]
set_property -dict {PACKAGE_PIN D18 IOSTANDARD LVCMOS33} [get_ports {led[3]}]

## Timing Constraints
set_false_path -from [get_clocks sys_clk] -to [get_ports {led[*]}]
set_false_path -from [get_ports rst_n] -to [all_registers]
