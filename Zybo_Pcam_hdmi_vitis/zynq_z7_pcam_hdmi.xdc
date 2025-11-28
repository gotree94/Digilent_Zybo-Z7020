# =============================================================================
# Zynq Z7-20 PCAM5C HDMI Output Constraints
# Bank 35 VCCO = 2.5V Configuration (Set JP6 jumper to 2V5)
# =============================================================================
#
# IMPORTANT HARDWARE SETUP:
# - Set JP6 jumper to "2V5" position on Zybo Z7 board
# - This allows MIPI (LVDS_25) and HDMI TX to coexist in Bank 35
#
# =============================================================================

# =============================================================================
# HDMI TX Output (Bank 35 - VCCO 2.5V)
# Using LVDS_25 for differential TMDS signals
# =============================================================================
set_property -dict {PACKAGE_PIN H16 IOSTANDARD LVDS_25} [get_ports hdmi_tx_clk_p]
set_property -dict {PACKAGE_PIN H17 IOSTANDARD LVDS_25} [get_ports hdmi_tx_clk_n]

set_property -dict {PACKAGE_PIN D19 IOSTANDARD LVDS_25} [get_ports {hdmi_tx_data_p[0]}]
set_property -dict {PACKAGE_PIN D20 IOSTANDARD LVDS_25} [get_ports {hdmi_tx_data_n[0]}]
set_property -dict {PACKAGE_PIN C20 IOSTANDARD LVDS_25} [get_ports {hdmi_tx_data_p[1]}]
set_property -dict {PACKAGE_PIN B20 IOSTANDARD LVDS_25} [get_ports {hdmi_tx_data_n[1]}]
set_property -dict {PACKAGE_PIN B19 IOSTANDARD LVDS_25} [get_ports {hdmi_tx_data_p[2]}]
set_property -dict {PACKAGE_PIN A20 IOSTANDARD LVDS_25} [get_ports {hdmi_tx_data_n[2]}]

# =============================================================================
# PCAM5C MIPI Interface - High Speed Signals (Bank 35 - VCCO 2.5V)
# =============================================================================

# MIPI Clock Lane - High Speed
set_property -dict {PACKAGE_PIN J18 IOSTANDARD LVDS_25 DIFF_TERM TRUE} [get_ports dphy_hs_clock_clk_p]
set_property -dict {PACKAGE_PIN H18 IOSTANDARD LVDS_25 DIFF_TERM TRUE} [get_ports dphy_hs_clock_clk_n]

# MIPI Data Lane 0 - High Speed
set_property -dict {PACKAGE_PIN M19 IOSTANDARD LVDS_25 DIFF_TERM TRUE} [get_ports {dphy_data_hs_p[0]}]
set_property -dict {PACKAGE_PIN M20 IOSTANDARD LVDS_25 DIFF_TERM TRUE} [get_ports {dphy_data_hs_n[0]}]

# MIPI Data Lane 1 - High Speed
set_property -dict {PACKAGE_PIN L16 IOSTANDARD LVDS_25 DIFF_TERM TRUE} [get_ports {dphy_data_hs_p[1]}]
set_property -dict {PACKAGE_PIN L17 IOSTANDARD LVDS_25 DIFF_TERM TRUE} [get_ports {dphy_data_hs_n[1]}]

# =============================================================================
# PCAM5C MIPI Interface - Low Power Signals
# =============================================================================

# MIPI Clock Lane - Low Power
set_property -dict {PACKAGE_PIN H20 IOSTANDARD HSUL_12} [get_ports dphy_clk_lp_p]
set_property -dict {PACKAGE_PIN J19 IOSTANDARD HSUL_12} [get_ports dphy_clk_lp_n]

# MIPI Data Lane 0 - Low Power
set_property -dict {PACKAGE_PIN L19 IOSTANDARD HSUL_12} [get_ports {dphy_data_lp_p[0]}]
set_property -dict {PACKAGE_PIN M18 IOSTANDARD HSUL_12} [get_ports {dphy_data_lp_n[0]}]

# MIPI Data Lane 1 - Low Power
set_property -dict {PACKAGE_PIN J20 IOSTANDARD HSUL_12} [get_ports {dphy_data_lp_p[1]}]
set_property -dict {PACKAGE_PIN L20 IOSTANDARD HSUL_12} [get_ports {dphy_data_lp_n[1]}]

# =============================================================================
# PCAM5C Control Signals (Bank 35 - VCCO 2.5V)
# Must use LVCMOS25 to match bank voltage
# =============================================================================

# Camera Power Enable GPIO
set_property PACKAGE_PIN G20 [get_ports {cam_gpio[0]}]
set_property IOSTANDARD LVCMOS25 [get_ports {cam_gpio[0]}]
set_property PULLUP true [get_ports {cam_gpio[0]}]

# Camera I2C (SCCB)
set_property -dict {PACKAGE_PIN F20 IOSTANDARD LVCMOS25} [get_ports cam_iic_scl_io]
set_property -dict {PACKAGE_PIN F19 IOSTANDARD LVCMOS25} [get_ports cam_iic_sda_io]

# =============================================================================
# Bank 35 INTERNAL_VREF for HSUL_12 standard
# =============================================================================
set_property INTERNAL_VREF 0.6 [get_iobanks 35]

# =============================================================================
# Clock Constraints
# =============================================================================

# MIPI HS Clock from camera
create_clock -period 4.761 -name dphy_hs_clock_p -waveform {0.000 2.380} [get_ports dphy_hs_clock_clk_p]

# =============================================================================
# Physical Constraints
# =============================================================================

# Configuration voltage
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

# Unused pins
set_property BITSTREAM.CONFIG.UNUSEDPIN PULLUP [current_design]
