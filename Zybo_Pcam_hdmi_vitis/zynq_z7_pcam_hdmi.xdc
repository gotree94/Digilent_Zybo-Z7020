# =============================================================================
# Zynq Z7-20 PCAM5C HDMI Output Constraints
# For Digilent Zynq Z7-20 Board
# =============================================================================

# =============================================================================
# HDMI TX (directly from RGB to DVI outputs)
# =============================================================================
set_property -dict { PACKAGE_PIN H16 IOSTANDARD TMDS_33 } [get_ports hdmi_tx_clk_p]
set_property -dict { PACKAGE_PIN H17 IOSTANDARD TMDS_33 } [get_ports hdmi_tx_clk_n]

set_property -dict { PACKAGE_PIN D19 IOSTANDARD TMDS_33 } [get_ports {hdmi_tx_data_p[0]}]
set_property -dict { PACKAGE_PIN D20 IOSTANDARD TMDS_33 } [get_ports {hdmi_tx_data_n[0]}]
set_property -dict { PACKAGE_PIN C20 IOSTANDARD TMDS_33 } [get_ports {hdmi_tx_data_p[1]}]
set_property -dict { PACKAGE_PIN B20 IOSTANDARD TMDS_33 } [get_ports {hdmi_tx_data_n[1]}]
set_property -dict { PACKAGE_PIN B19 IOSTANDARD TMDS_33 } [get_ports {hdmi_tx_data_p[2]}]
set_property -dict { PACKAGE_PIN A20 IOSTANDARD TMDS_33 } [get_ports {hdmi_tx_data_n[2]}]

# =============================================================================
# PCAM5C MIPI Interface
# Note: MIPI lane locations are configured in the MIPI CSI-2 RX Subsystem IP
# =============================================================================
# MIPI Clock Lane (directly from D-PHY interface)
set_property -dict { PACKAGE_PIN J14 } [get_ports {mipi_phy_if_0_clk_p}]
set_property -dict { PACKAGE_PIN H14 } [get_ports {mipi_phy_if_0_clk_n}]

# MIPI Data Lane 0
set_property -dict { PACKAGE_PIN M15 } [get_ports {mipi_phy_if_0_data_p[0]}]
set_property -dict { PACKAGE_PIN M14 } [get_ports {mipi_phy_if_0_data_n[0]}]

# MIPI Data Lane 1
set_property -dict { PACKAGE_PIN L14 } [get_ports {mipi_phy_if_0_data_p[1]}]
set_property -dict { PACKAGE_PIN L15 } [get_ports {mipi_phy_if_0_data_n[1]}]

# =============================================================================
# PCAM5C Control Signals
# =============================================================================
# Camera Power Enable (directly from AXI GPIO port)
set_property -dict { PACKAGE_PIN G17 IOSTANDARD LVCMOS33 } [get_ports {cam_gpio_tri_o[0]}]

# Camera I2C (SCCB) - directly from AXI IIC port
set_property -dict { PACKAGE_PIN F17 IOSTANDARD LVCMOS33 } [get_ports cam_iic_scl_io]
set_property -dict { PACKAGE_PIN G18 IOSTANDARD LVCMOS33 } [get_ports cam_iic_sda_io]

# =============================================================================
# Clock Constraints
# =============================================================================

# PS Clock (100 MHz)
create_clock -period 10.000 -name clk_fpga_0 [get_pins design_1_i/processing_system7_0/inst/PS7_i/FCLKCLK[0]]

# PS Clock (200 MHz for MIPI)
create_clock -period 5.000 -name clk_fpga_1 [get_pins design_1_i/processing_system7_0/inst/PS7_i/FCLKCLK[1]]

# HDMI Pixel Clock (148.5 MHz for 1080p60)
create_clock -period 6.734 -name hdmi_pix_clk [get_pins design_1_i/clk_wiz_0/inst/mmcm_adv_inst/CLKOUT0]

# HDMI Serial Clock (742.5 MHz)
create_clock -period 1.347 -name hdmi_ser_clk [get_pins design_1_i/clk_wiz_0/inst/mmcm_adv_inst/CLKOUT1]

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

# False paths for CDC
set_false_path -from [get_clocks clk_fpga_0] -to [get_clocks hdmi_pix_clk]
set_false_path -from [get_clocks hdmi_pix_clk] -to [get_clocks clk_fpga_0]

# =============================================================================
# I/O Timing Constraints
# =============================================================================

# HDMI output timing (relaxed for TMDS)
set_output_delay -clock [get_clocks hdmi_pix_clk] -min -1.0 [get_ports hdmi_tx_*]
set_output_delay -clock [get_clocks hdmi_pix_clk] -max 1.0 [get_ports hdmi_tx_*]

# =============================================================================
# Physical Constraints
# =============================================================================

# Configuration voltage
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

# Unused pins
set_property BITSTREAM.CONFIG.UNUSEDPIN PULLUP [current_design]

# =============================================================================
# Debug (Optional - Comment out for production)
# =============================================================================
# set_property MARK_DEBUG true [get_nets {design_1_i/axi_vdma_0/s2mm_frame_ptr*}]
# set_property MARK_DEBUG true [get_nets {design_1_i/v_tc_1/active_video_out}]
