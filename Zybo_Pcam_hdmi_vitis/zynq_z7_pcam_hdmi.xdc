# =============================================================================
# Zynq Z7-20 PCAM5C HDMI Output Constraints
# Based on Digilent Official Zybo-Z7-20-pcam-5c Project
# =============================================================================
#
# IMPORTANT: Bank 35 VCCO = 3.3V (shared by HDMI TX and MIPI)
#   - HDMI TX uses TMDS_33 (requires 3.3V VCCO)
#   - MIPI HS uses LVDS_25 (VCCO-independent differential standard)
#   - MIPI LP uses HSUL_12 with INTERNAL_VREF 0.6V
#   - Camera control (GPIO, I2C) uses LVCMOS33
#
# =============================================================================

# =============================================================================
# HDMI TX Output (Bank 35)
# =============================================================================
set_property -dict {PACKAGE_PIN H16 IOSTANDARD TMDS_33} [get_ports hdmi_tx_clk_p]
set_property -dict {PACKAGE_PIN H17 IOSTANDARD TMDS_33} [get_ports hdmi_tx_clk_n]

set_property -dict {PACKAGE_PIN D19 IOSTANDARD TMDS_33} [get_ports {hdmi_tx_data_p[0]}]
set_property -dict {PACKAGE_PIN D20 IOSTANDARD TMDS_33} [get_ports {hdmi_tx_data_n[0]}]
set_property -dict {PACKAGE_PIN C20 IOSTANDARD TMDS_33} [get_ports {hdmi_tx_data_p[1]}]
set_property -dict {PACKAGE_PIN B20 IOSTANDARD TMDS_33} [get_ports {hdmi_tx_data_n[1]}]
set_property -dict {PACKAGE_PIN B19 IOSTANDARD TMDS_33} [get_ports {hdmi_tx_data_p[2]}]
set_property -dict {PACKAGE_PIN A20 IOSTANDARD TMDS_33} [get_ports {hdmi_tx_data_n[2]}]

# =============================================================================
# PCAM5C MIPI Interface (Bank 35)
# Based on Digilent ZyboZ7_A.xdc from pcam-5c project
# =============================================================================

# MIPI Clock Lane - High Speed (diff_clock_rtl interface)
# LVDS_25 is VCCO-independent for differential input
set_property -dict {PACKAGE_PIN J18 IOSTANDARD LVDS_25 DIFF_TERM TRUE} [get_ports dphy_hs_clock_clk_p]
set_property -dict {PACKAGE_PIN H18 IOSTANDARD LVDS_25 DIFF_TERM TRUE} [get_ports dphy_hs_clock_clk_n]

# MIPI Data Lane 0 - High Speed
set_property -dict {PACKAGE_PIN L15 IOSTANDARD LVDS_25 DIFF_TERM TRUE} [get_ports {dphy_data_hs_p[0]}]
set_property -dict {PACKAGE_PIN L14 IOSTANDARD LVDS_25 DIFF_TERM TRUE} [get_ports {dphy_data_hs_n[0]}]

# MIPI Data Lane 1 - High Speed
set_property -dict {PACKAGE_PIN L16 IOSTANDARD LVDS_25 DIFF_TERM TRUE} [get_ports {dphy_data_hs_p[1]}]
set_property -dict {PACKAGE_PIN L17 IOSTANDARD LVDS_25 DIFF_TERM TRUE} [get_ports {dphy_data_hs_n[1]}]

# MIPI Clock Lane - Low Power (Digilent pinout)
set_property -dict {PACKAGE_PIN H20 IOSTANDARD HSUL_12} [get_ports dphy_clk_lp_p]
set_property -dict {PACKAGE_PIN J19 IOSTANDARD HSUL_12} [get_ports dphy_clk_lp_n]

# MIPI Data Lane 0 - Low Power (Digilent pinout)
set_property -dict {PACKAGE_PIN L19 IOSTANDARD HSUL_12} [get_ports {dphy_data_lp_p[0]}]
set_property -dict {PACKAGE_PIN M18 IOSTANDARD HSUL_12} [get_ports {dphy_data_lp_n[0]}]

# MIPI Data Lane 1 - Low Power (Digilent pinout)
set_property -dict {PACKAGE_PIN J20 IOSTANDARD HSUL_12} [get_ports {dphy_data_lp_p[1]}]
set_property -dict {PACKAGE_PIN L20 IOSTANDARD HSUL_12} [get_ports {dphy_data_lp_n[1]}]

# =============================================================================
# PCAM5C Control Signals (Bank 35 - LVCMOS33)
# =============================================================================

# Camera Power Enable GPIO
set_property PACKAGE_PIN G20 [get_ports {cam_gpio[0]}]
set_property IOSTANDARD LVCMOS33 [get_ports {cam_gpio[0]}]
set_property PULLUP true [get_ports {cam_gpio[0]}]

# Camera I2C (SCCB)
set_property -dict {PACKAGE_PIN F20 IOSTANDARD LVCMOS33} [get_ports cam_iic_scl_io]
set_property -dict {PACKAGE_PIN F19 IOSTANDARD LVCMOS33} [get_ports cam_iic_sda_io]

# =============================================================================
# Bank 35 INTERNAL_VREF for HSUL_12 standard
# =============================================================================
set_property INTERNAL_VREF 0.6 [get_iobanks 35]

# =============================================================================
# Clock Constraints
# =============================================================================

# MIPI HS Clock (Input from camera - 672 Mbps = 336 MHz, period 2.976ns)
# Digilent uses 4.761ns for ~420 Mbps (210 MHz)
create_clock -period 4.761 -name dphy_hs_clock_p -waveform {0.000 2.380} [get_ports dphy_hs_clock_clk_p]

# =============================================================================
# Physical Constraints
# =============================================================================

# Configuration voltage
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

# Unused pins
set_property BITSTREAM.CONFIG.UNUSEDPIN PULLUP [current_design]
