## This file is a general .xdc for the Zybo Z7 Rev. B
## It is compatible with the Zybo Z7-20
## Constraint file for audio codec project

## Clock signal (125 MHz)
set_property -dict { PACKAGE_PIN K17   IOSTANDARD LVCMOS33 } [get_ports { clk }]
create_clock -period 8.000 -name sys_clk_pin -waveform {0.000 4.000} -add [get_ports { clk }]

## Switches
set_property -dict { PACKAGE_PIN G15   IOSTANDARD LVCMOS33 } [get_ports { sw[0] }]
set_property -dict { PACKAGE_PIN P15   IOSTANDARD LVCMOS33 } [get_ports { sw[1] }]
set_property -dict { PACKAGE_PIN W13   IOSTANDARD LVCMOS33 } [get_ports { sw[2] }]
set_property -dict { PACKAGE_PIN T16   IOSTANDARD LVCMOS33 } [get_ports { sw[3] }]

## Buttons
set_property -dict { PACKAGE_PIN K18   IOSTANDARD LVCMOS33 } [get_ports { btn[0] }]
set_property -dict { PACKAGE_PIN P16   IOSTANDARD LVCMOS33 } [get_ports { btn[1] }]
set_property -dict { PACKAGE_PIN K19   IOSTANDARD LVCMOS33 } [get_ports { btn[2] }]
set_property -dict { PACKAGE_PIN Y16   IOSTANDARD LVCMOS33 } [get_ports { btn[3] }]

## LEDs
set_property -dict { PACKAGE_PIN M14   IOSTANDARD LVCMOS33 } [get_ports { led[0] }]
set_property -dict { PACKAGE_PIN M15   IOSTANDARD LVCMOS33 } [get_ports { led[1] }]
set_property -dict { PACKAGE_PIN G14   IOSTANDARD LVCMOS33 } [get_ports { led[2] }]
set_property -dict { PACKAGE_PIN D18   IOSTANDARD LVCMOS33 } [get_ports { led[3] }]

## RGB LEDs
#set_property -dict { PACKAGE_PIN Y11   IOSTANDARD LVCMOS33 } [get_ports { led5_r }]
#set_property -dict { PACKAGE_PIN T5    IOSTANDARD LVCMOS33 } [get_ports { led5_g }]
#set_property -dict { PACKAGE_PIN Y12   IOSTANDARD LVCMOS33 } [get_ports { led5_b }]
#set_property -dict { PACKAGE_PIN V6    IOSTANDARD LVCMOS33 } [get_ports { led6_r }]
#set_property -dict { PACKAGE_PIN T6    IOSTANDARD LVCMOS33 } [get_ports { led6_g }]
#set_property -dict { PACKAGE_PIN W6    IOSTANDARD LVCMOS33 } [get_ports { led6_b }]

## ========================================
## Audio Codec - SSM2603
## ========================================
## I2S Audio Interface
set_property -dict { PACKAGE_PIN K18   IOSTANDARD LVCMOS33 } [get_ports { ac_bclk }]
set_property -dict { PACKAGE_PIN T19   IOSTANDARD LVCMOS33 } [get_ports { ac_mclk }]
set_property -dict { PACKAGE_PIN P18   IOSTANDARD LVCMOS33 } [get_ports { ac_muten }]
set_property -dict { PACKAGE_PIN M17   IOSTANDARD LVCMOS33 } [get_ports { ac_pbdat }]
set_property -dict { PACKAGE_PIN L17   IOSTANDARD LVCMOS33 } [get_ports { ac_pblrc }]
set_property -dict { PACKAGE_PIN K17   IOSTANDARD LVCMOS33 } [get_ports { ac_recdat }]
set_property -dict { PACKAGE_PIN M18   IOSTANDARD LVCMOS33 } [get_ports { ac_reclrc }]

## I2C Interface for Audio Codec Control
set_property -dict { PACKAGE_PIN N18   IOSTANDARD LVCMOS33 } [get_ports { ac_scl }]
set_property -dict { PACKAGE_PIN N17   IOSTANDARD LVCMOS33 } [get_ports { ac_sda }]

## ========================================
## Pmod Header JA
## ========================================
#set_property -dict { PACKAGE_PIN N15   IOSTANDARD LVCMOS33 } [get_ports { ja[0] }]
#set_property -dict { PACKAGE_PIN L14   IOSTANDARD LVCMOS33 } [get_ports { ja[1] }]
#set_property -dict { PACKAGE_PIN K16   IOSTANDARD LVCMOS33 } [get_ports { ja[2] }]
#set_property -dict { PACKAGE_PIN K14   IOSTANDARD LVCMOS33 } [get_ports { ja[3] }]
#set_property -dict { PACKAGE_PIN N16   IOSTANDARD LVCMOS33 } [get_ports { ja[4] }]
#set_property -dict { PACKAGE_PIN L15   IOSTANDARD LVCMOS33 } [get_ports { ja[5] }]
#set_property -dict { PACKAGE_PIN J16   IOSTANDARD LVCMOS33 } [get_ports { ja[6] }]
#set_property -dict { PACKAGE_PIN J14   IOSTANDARD LVCMOS33 } [get_ports { ja[7] }]

## ========================================
## HDMI RX
## ========================================
#set_property -dict { PACKAGE_PIN H17   IOSTANDARD TMDS_33  } [get_ports { hdmi_rx_clk_n }]
#set_property -dict { PACKAGE_PIN H16   IOSTANDARD TMDS_33  } [get_ports { hdmi_rx_clk_p }]
#set_property -dict { PACKAGE_PIN D20   IOSTANDARD TMDS_33  } [get_ports { hdmi_rx_n[0] }]
#set_property -dict { PACKAGE_PIN D19   IOSTANDARD TMDS_33  } [get_ports { hdmi_rx_p[0] }]
#set_property -dict { PACKAGE_PIN B20   IOSTANDARD TMDS_33  } [get_ports { hdmi_rx_n[1] }]
#set_property -dict { PACKAGE_PIN C20   IOSTANDARD TMDS_33  } [get_ports { hdmi_rx_p[1] }]
#set_property -dict { PACKAGE_PIN A20   IOSTANDARD TMDS_33  } [get_ports { hdmi_rx_n[2] }]
#set_property -dict { PACKAGE_PIN B19   IOSTANDARD TMDS_33  } [get_ports { hdmi_rx_p[2] }]

## HDMI RX CEC
#set_property -dict { PACKAGE_PIN E19   IOSTANDARD LVCMOS33 } [get_ports { hdmi_rx_cec }]
#set_property -dict { PACKAGE_PIN E18   IOSTANDARD LVCMOS33 } [get_ports { hdmi_rx_hpd }]
#set_property -dict { PACKAGE_PIN F17   IOSTANDARD LVCMOS33 } [get_ports { hdmi_rx_scl }]
#set_property -dict { PACKAGE_PIN G17   IOSTANDARD LVCMOS33 } [get_ports { hdmi_rx_sda }]

## ========================================
## HDMI TX
## ========================================
#set_property -dict { PACKAGE_PIN G15   IOSTANDARD TMDS_33  } [get_ports { hdmi_tx_clk_n }]
#set_property -dict { PACKAGE_PIN H15   IOSTANDARD TMDS_33  } [get_ports { hdmi_tx_clk_p }]
#set_property -dict { PACKAGE_PIN C18   IOSTANDARD TMDS_33  } [get_ports { hdmi_tx_n[0] }]
#set_property -dict { PACKAGE_PIN D18   IOSTANDARD TMDS_33  } [get_ports { hdmi_tx_p[0] }]
#set_property -dict { PACKAGE_PIN E17   IOSTANDARD TMDS_33  } [get_ports { hdmi_tx_n[1] }]
#set_property -dict { PACKAGE_PIN E16   IOSTANDARD TMDS_33  } [get_ports { hdmi_tx_p[1] }]
#set_property -dict { PACKAGE_PIN F16   IOSTANDARD TMDS_33  } [get_ports { hdmi_tx_n[2] }]
#set_property -dict { PACKAGE_PIN F15   IOSTANDARD TMDS_33  } [get_ports { hdmi_tx_p[2] }]

## HDMI TX CEC
#set_property -dict { PACKAGE_PIN G16   IOSTANDARD LVCMOS33 } [get_ports { hdmi_tx_cec }]
#set_property -dict { PACKAGE_PIN F18   IOSTANDARD LVCMOS33 } [get_ports { hdmi_tx_hpd }]

## ========================================
## Timing Constraints
## ========================================
## Async clocks
set_clock_groups -asynchronous -group [get_clocks sys_clk_pin]
