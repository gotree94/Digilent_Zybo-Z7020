# zybo_z7_audio.xdc
# Constraints file for Zybo Z7-20 Audio Project
# Reference: Zybo Z7 Master XDC and Schematic Rev B.2

## Clock Signal (125MHz Ethernet PHY clock)
set_property -dict {PACKAGE_PIN K17 IOSTANDARD LVCMOS33} [get_ports clk_100mhz]
create_clock -period 8.000 -name sys_clk -waveform {0.000 4.000} [get_ports clk_100mhz]

## Reset Button (BTN0)
set_property -dict {PACKAGE_PIN K18 IOSTANDARD LVCMOS33} [get_ports rst_n]

## Audio Codec I2S Signals (All connected to PL)
## AC_MCLK - Master Clock Output to Codec
set_property -dict {PACKAGE_PIN R19 IOSTANDARD LVCMOS33} [get_ports ac_mclk]

## AC_ADC_SDATA - Record/Capture Data from Codec ADC
set_property -dict {PACKAGE_PIN D19 IOSTANDARD LVCMOS33} [get_ports ac_recdat]

## AC_DAC_SDATA - Playback Data to Codec DAC  
set_property -dict {PACKAGE_PIN D18 IOSTANDARD LVCMOS33} [get_ports ac_pbdat]

## AC_BCLK - Bit Clock (I2S Serial Clock)
set_property -dict {PACKAGE_PIN R18 IOSTANDARD LVCMOS33} [get_ports ac_bclk]

## AC_PBLRC - Playback Left/Right Clock (DACLRC)
set_property -dict {PACKAGE_PIN R17 IOSTANDARD LVCMOS33} [get_ports ac_pblrc]

## AC_RECLRC - Record Left/Right Clock (ADCLRC)
set_property -dict {PACKAGE_PIN T19 IOSTANDARD LVCMOS33} [get_ports ac_reclrc]

## I2C for Audio Codec Configuration
## NOTE: On Zybo Z7, I2C is connected to PS MIO pins (MIO50/51)
## For pure FPGA implementation, we use Pmod JE as bit-bang I2C
## Pmod JE (top row): JE1=V12, JE2=W16, JE3=J15, JE4=H15
set_property -dict {PACKAGE_PIN V12 IOSTANDARD LVCMOS33 PULLUP true} [get_ports i2c_scl]
set_property -dict {PACKAGE_PIN W16 IOSTANDARD LVCMOS33 PULLUP true} [get_ports i2c_sda]

## LEDs (LD0-LD3)
set_property -dict {PACKAGE_PIN M14 IOSTANDARD LVCMOS33} [get_ports {led[0]}]
set_property -dict {PACKAGE_PIN M15 IOSTANDARD LVCMOS33} [get_ports {led[1]}]
set_property -dict {PACKAGE_PIN G14 IOSTANDARD LVCMOS33} [get_ports {led[2]}]
set_property -dict {PACKAGE_PIN D18 IOSTANDARD LVCMOS33} [get_ports {led[3]}]

## Timing Constraints
## False paths for asynchronous signals
set_false_path -from [get_clocks sys_clk] -to [get_ports {led[*]}]
set_false_path -from [get_ports rst_n] -to [all_registers]

## I2C timing constraints (relaxed for bit-bang implementation)
set_max_delay -from [get_ports i2c_sda] 50.000
set_max_delay -to [get_ports i2c_sda] 50.000
set_max_delay -from [get_ports i2c_scl] 50.000
set_max_delay -to [get_ports i2c_scl] 50.000

## Audio clock domain constraints
## MCLK is generated internally, BCLK and LRCLK derived from MCLK
## These are considered asynchronous to system clock
set_false_path -from [get_clocks sys_clk] -to [get_ports ac_mclk]
set_false_path -from [get_clocks sys_clk] -to [get_ports ac_bclk]
set_false_path -from [get_clocks sys_clk] -to [get_ports ac_pblrc]
set_false_path -from [get_clocks sys_clk] -to [get_ports ac_reclrc]
set_false_path -from [get_clocks sys_clk] -to [get_ports ac_pbdat]
set_false_path -from [get_ports ac_recdat] -to [get_clocks sys_clk]

