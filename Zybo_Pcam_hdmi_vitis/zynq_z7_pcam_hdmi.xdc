# =============================================================================
# Zynq Z7-20 PCAM5C HDMI Output Constraints
# For Digilent Zynq Z7-20 Board with PCAM5C Camera
# =============================================================================
#
# MIPI HS Clock is connected as diff_clock_rtl interface
# Interface port name: dphy_hs_clock
# Actual pin names: dphy_hs_clock_clk_p, dphy_hs_clock_clk_n
#
# =============================================================================

# =============================================================================
# HDMI TX Output
# =============================================================================
# TMDS Clock
set_property -dict { PACKAGE_PIN H16 IOSTANDARD TMDS_33 } [get_ports hdmi_tx_clk_p]
set_property -dict { PACKAGE_PIN H17 IOSTANDARD TMDS_33 } [get_ports hdmi_tx_clk_n]

# TMDS Data
set_property -dict { PACKAGE_PIN D19 IOSTANDARD TMDS_33 } [get_ports {hdmi_tx_data_p[0]}]
set_property -dict { PACKAGE_PIN D20 IOSTANDARD TMDS_33 } [get_ports {hdmi_tx_data_n[0]}]
set_property -dict { PACKAGE_PIN C20 IOSTANDARD TMDS_33 } [get_ports {hdmi_tx_data_p[1]}]
set_property -dict { PACKAGE_PIN B20 IOSTANDARD TMDS_33 } [get_ports {hdmi_tx_data_n[1]}]
set_property -dict { PACKAGE_PIN B19 IOSTANDARD TMDS_33 } [get_ports {hdmi_tx_data_p[2]}]
set_property -dict { PACKAGE_PIN A20 IOSTANDARD TMDS_33 } [get_ports {hdmi_tx_data_n[2]}]

# =============================================================================
# PCAM5C MIPI Interface
# =============================================================================

# MIPI Clock Lane - High Speed (diff_clock_rtl interface)
# Interface name: dphy_hs_clock -> pins: dphy_hs_clock_clk_p, dphy_hs_clock_clk_n
set_property -dict { PACKAGE_PIN J14 IOSTANDARD LVDS_25 DIFF_TERM 1 } [get_ports dphy_hs_clock_clk_p]
set_property -dict { PACKAGE_PIN H14 IOSTANDARD LVDS_25 DIFF_TERM 1 } [get_ports dphy_hs_clock_clk_n]

# MIPI Clock Lane - Low Power (individual pins)
set_property -dict { PACKAGE_PIN J15 IOSTANDARD HSUL_12 } [get_ports dphy_clk_lp_p]
set_property -dict { PACKAGE_PIN H15 IOSTANDARD HSUL_12 } [get_ports dphy_clk_lp_n]

# MIPI Data Lane 0 - High Speed (individual pins)
set_property -dict { PACKAGE_PIN M15 IOSTANDARD LVDS_25 DIFF_TERM 1 } [get_ports {dphy_data_hs_p[0]}]
set_property -dict { PACKAGE_PIN M14 IOSTANDARD LVDS_25 DIFF_TERM 1 } [get_ports {dphy_data_hs_n[0]}]

# MIPI Data Lane 1 - High Speed (individual pins)
set_property -dict { PACKAGE_PIN L16 IOSTANDARD LVDS_25 DIFF_TERM 1 } [get_ports {dphy_data_hs_p[1]}]
set_property -dict { PACKAGE_PIN L17 IOSTANDARD LVDS_25 DIFF_TERM 1 } [get_ports {dphy_data_hs_n[1]}]

# MIPI Data Lane 0 - Low Power (individual pins)
set_property -dict { PACKAGE_PIN L15 IOSTANDARD HSUL_12 } [get_ports {dphy_data_lp_p[0]}]
set_property -dict { PACKAGE_PIN L14 IOSTANDARD HSUL_12 } [get_ports {dphy_data_lp_n[0]}]

# MIPI Data Lane 1 - Low Power (individual pins)
set_property -dict { PACKAGE_PIN M17 IOSTANDARD HSUL_12 } [get_ports {dphy_data_lp_p[1]}]
set_property -dict { PACKAGE_PIN M18 IOSTANDARD HSUL_12 } [get_ports {dphy_data_lp_n[1]}]

# =============================================================================
# PCAM5C Control Signals
# =============================================================================

# Camera Power Enable (directly from AXI GPIO port)
set_property -dict { PACKAGE_PIN G17 IOSTANDARD LVCMOS33 } [get_ports {cam_gpio[0]}]

# Camera I2C (SCCB) - directly from AXI IIC port
set_property -dict { PACKAGE_PIN F17 IOSTANDARD LVCMOS33 } [get_ports cam_iic_scl_io]
set_property -dict { PACKAGE_PIN G18 IOSTANDARD LVCMOS33 } [get_ports cam_iic_sda_io]

# =============================================================================
# Clock Constraints
# =============================================================================

# PS Clock (100 MHz) - AXI and Video Processing
create_clock -period 10.000 -name clk_fpga_0 [get_pins design_1_i/processing_system7_0/inst/PS7_i/FCLKCLK[0]]

# PS Clock (200 MHz) - MIPI D-PHY Reference
create_clock -period 5.000 -name clk_fpga_1 [get_pins design_1_i/processing_system7_0/inst/PS7_i/FCLKCLK[1]]

# HDMI Pixel Clock (148.5 MHz for 1080p60)
create_clock -period 6.734 -name hdmi_pix_clk [get_pins design_1_i/clk_wiz_0/inst/mmcm_adv_inst/CLKOUT0]

# MIPI HS Clock (Input from camera - approximately 336 MHz for 672 Mbps)
create_clock -period 2.976 -name mipi_hs_clk [get_ports dphy_hs_clock_clk_p]

# =============================================================================
# Clock Groups and False Paths
# =============================================================================

# Asynchronous clock groups
set_clock_groups -asynchronous \
    -group [get_clocks clk_fpga_0] \
    -group [get_clocks hdmi_pix_clk]

set_clock_groups -asynchronous \
    -group [get_clocks clk_fpga_1] \
    -group [get_clocks hdmi_pix_clk]

set_clock_groups -asynchronous \
    -group [get_clocks mipi_hs_clk] \
    -group [get_clocks clk_fpga_0]

set_clock_groups -asynchronous \
    -group [get_clocks mipi_hs_clk] \
    -group [get_clocks hdmi_pix_clk]

# False paths for CDC (Clock Domain Crossing)
set_false_path -from [get_clocks clk_fpga_0] -to [get_clocks hdmi_pix_clk]
set_false_path -from [get_clocks hdmi_pix_clk] -to [get_clocks clk_fpga_0]

# =============================================================================
# Physical Constraints
# =============================================================================

# Configuration voltage
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

# Unused pins
set_property BITSTREAM.CONFIG.UNUSEDPIN PULLUP [current_design]

# =============================================================================
# I/O Delays (Optional - for timing closure)
# =============================================================================

# HDMI output timing (relaxed for TMDS)
# set_output_delay -clock [get_clocks hdmi_pix_clk] -min -1.0 [get_ports hdmi_tx_*]
# set_output_delay -clock [get_clocks hdmi_pix_clk] -max 1.0 [get_ports hdmi_tx_*]

# =============================================================================
# Debug (Optional - Uncomment for ILA debugging)
# =============================================================================
# set_property MARK_DEBUG true [get_nets {design_1_i/axi_vdma_0/s2mm_frame_ptr*}]
# set_property MARK_DEBUG true [get_nets {design_1_i/v_axi4s_vid_out_0/vid_active_video}]
# set_property MARK_DEBUG true [get_nets {design_1_i/MIPI_D_PHY_RX_0/aRxClkActiveHS}]
