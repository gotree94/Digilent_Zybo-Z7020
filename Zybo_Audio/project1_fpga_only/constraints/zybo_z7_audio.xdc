# zybo_z7_audio.xdc
# Constraints file for Zybo Z7-20 Audio Project
# Based on Zybo Z7 Master XDC

## Clock Signal (125MHz from Ethernet PHY)
set_property -dict {PACKAGE_PIN K17 IOSTANDARD LVCMOS33} [get_ports clk_100mhz]
create_clock -period 10.000 -name sys_clk -waveform {0.000 5.000} [get_ports clk_100mhz]

## Reset (BTN0)
set_property -dict {PACKAGE_PIN K18 IOSTANDARD LVCMOS33} [get_ports rst_n]

## I2C for Audio Codec (PS MIO pins - but we'll use PL for FPGA-only design)
## Using PMOD JE pins for I2C
set_property -dict {PACKAGE_PIN V12 IOSTANDARD LVCMOS33} [get_ports i2c_scl]
set_property -dict {PACKAGE_PIN W16 IOSTANDARD LVCMOS33} [get_ports i2c_sda]

## Audio Codec I2S Signals
## AC_MCLK
set_property -dict {PACKAGE_PIN T19 IOSTANDARD LVCMOS33} [get_ports ac_mclk]

## AC_ADC_SDATA (Record Data)
set_property -dict {PACKAGE_PIN K17 IOSTANDARD LVCMOS33} [get_ports ac_recdat]

## AC_BCLK (Bit Clock)
set_property -dict {PACKAGE_PIN K18 IOSTANDARD LVCMOS33} [get_ports ac_bclk]

## AC_PBLRC (Playback Left/Right Clock)
set_property -dict {PACKAGE_PIN L17 IOSTANDARD LVCMOS33} [get_ports ac_pblrc]

## AC_RECLRC (Record Left/Right Clock) 
set_property -dict {PACKAGE_PIN M17 IOSTANDARD LVCMOS33} [get_ports ac_reclrc]

## AC_DAC_SDATA (Playback Data)
set_property -dict {PACKAGE_PIN M18 IOSTANDARD LVCMOS33} [get_ports ac_pbdat]

## LEDs
set_property -dict {PACKAGE_PIN M14 IOSTANDARD LVCMOS33} [get_ports {led[0]}]
set_property -dict {PACKAGE_PIN M15 IOSTANDARD LVCMOS33} [get_ports {led[1]}]
set_property -dict {PACKAGE_PIN G14 IOSTANDARD LVCMOS33} [get_ports {led[2]}]
set_property -dict {PACKAGE_PIN D18 IOSTANDARD LVCMOS33} [get_ports {led[3]}]

## Timing Constraints
set_false_path -from [get_clocks sys_clk] -to [get_ports {led[*]}]
set_false_path -from [get_ports rst_n] -to [all_registers]

## I2C Timing
set_max_delay -from [get_ports i2c_sda] 20.000
set_max_delay -to [get_ports i2c_sda] 20.000
set_max_delay -from [get_ports i2c_scl] 20.000
set_max_delay -to [get_ports i2c_scl] 20.000
