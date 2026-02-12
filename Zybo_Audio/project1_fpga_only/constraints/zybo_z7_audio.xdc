# zybo_z7_audio.xdc
# Constraints file for Zybo Z7-20 Audio Project
# Based on official Digilent Zybo Z7 Master XDC
# Reference: https://github.com/Digilent/digilent-xdc

## Clock Signal (125MHz Ethernet PHY clock)
set_property -dict {PACKAGE_PIN K17 IOSTANDARD LVCMOS33} [get_ports clk_100mhz]
create_clock -add -name sys_clk_pin -period 8.00 -waveform {0 4} [get_ports clk_100mhz]

## Reset Button (BTN0)
set_property -dict {PACKAGE_PIN K18 IOSTANDARD LVCMOS33} [get_ports rst_n]

## Audio Codec I2S Signals (from official Digilent XDC)
## AC_BCLK - Bit Clock
set_property -dict {PACKAGE_PIN R19 IOSTANDARD LVCMOS33} [get_ports ac_bclk]

## AC_MCLK - Master Clock
set_property -dict {PACKAGE_PIN R17 IOSTANDARD LVCMOS33} [get_ports ac_mclk]

## AC_PBDAT - Playback Data (DAC)
set_property -dict {PACKAGE_PIN R18 IOSTANDARD LVCMOS33} [get_ports ac_pbdat]

## AC_PBLRC - Playback Left/Right Clock
set_property -dict {PACKAGE_PIN T19 IOSTANDARD LVCMOS33} [get_ports ac_pblrc]

## AC_RECDAT - Record Data (ADC)
set_property -dict {PACKAGE_PIN R16 IOSTANDARD LVCMOS33} [get_ports ac_recdat]

## AC_RECLRC - Record Left/Right Clock
set_property -dict {PACKAGE_PIN Y18 IOSTANDARD LVCMOS33} [get_ports ac_reclrc]

## I2C for Audio Codec Configuration
## AC_SCL - I2C Clock
set_property -dict {PACKAGE_PIN N18 IOSTANDARD LVCMOS33} [get_ports i2c_scl]

## AC_SDA - I2C Data
set_property -dict {PACKAGE_PIN N17 IOSTANDARD LVCMOS33} [get_ports i2c_sda]

## LEDs (LD0-LD3)
set_property -dict {PACKAGE_PIN M14 IOSTANDARD LVCMOS33} [get_ports {led[0]}]
set_property -dict {PACKAGE_PIN M15 IOSTANDARD LVCMOS33} [get_ports {led[1]}]
set_property -dict {PACKAGE_PIN G14 IOSTANDARD LVCMOS33} [get_ports {led[2]}]
set_property -dict {PACKAGE_PIN D18 IOSTANDARD LVCMOS33} [get_ports {led[3]}]

## Timing Constraints
## False paths for asynchronous signals
set_false_path -from [get_clocks sys_clk_pin] -to [get_ports {led[*]}]
set_false_path -from [get_ports rst_n] -to [all_registers]

## I2C timing constraints (100kHz I2C)
set_max_delay -from [get_ports i2c_sda] 50.000
set_max_delay -to [get_ports i2c_sda] 50.000
set_max_delay -from [get_ports i2c_scl] 50.000
set_max_delay -to [get_ports i2c_scl] 50.000

## Audio clock domain constraints
## Audio clocks are generated internally and asynchronous to system clock
set_false_path -from [get_clocks sys_clk_pin] -to [get_ports ac_mclk]
set_false_path -from [get_clocks sys_clk_pin] -to [get_ports ac_bclk]
set_false_path -from [get_clocks sys_clk_pin] -to [get_ports ac_pblrc]
set_false_path -from [get_clocks sys_clk_pin] -to [get_ports ac_reclrc]
set_false_path -from [get_clocks sys_clk_pin] -to [get_ports ac_pbdat]
set_false_path -from [get_ports ac_recdat] -to [get_clocks sys_clk_pin]


