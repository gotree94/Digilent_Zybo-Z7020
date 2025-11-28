# =============================================================================
# Zynq Z7-20 PCAM5C HDMI Output - Vivado Block Design TCL Script
# =============================================================================
# 
# Usage:
#   1. Open Vivado 2022.2
#   2. Create new project for Zynq-Z7-20 board
#   3. Add Digilent vivado-library to IP repositories
#   4. Run this script: source create_bd.tcl
#
# Prerequisites:
#   - Vivado 2022.2 or later
#   - Digilent Board Files installed
#   - Digilent vivado-library in IP repository
# =============================================================================

# Create block design
create_bd_design "design_1"
update_compile_order -fileset sources_1

# =============================================================================
# Add IP Cores
# =============================================================================

# ZYNQ Processing System
create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0

# Apply board preset
apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config {
    make_external "FIXED_IO, DDR" 
    apply_board_preset "1" 
    Master "Disable" 
    Slave "Disable" 
} [get_bd_cells processing_system7_0]

# Configure ZYNQ PS
set_property -dict [list \
    CONFIG.PCW_USE_S_AXI_HP0 {1} \
    CONFIG.PCW_USE_FABRIC_INTERRUPT {1} \
    CONFIG.PCW_IRQ_F2P_INTR {1} \
    CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {100} \
    CONFIG.PCW_FPGA1_PERIPHERAL_FREQMHZ {200} \
    CONFIG.PCW_EN_CLK1_PORT {1} \
    CONFIG.PCW_USE_M_AXI_GP0 {1} \
] [get_bd_cells processing_system7_0]

# Clocking Wizards
create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 clk_wiz_0
set_property -dict [list \
    CONFIG.PRIM_SOURCE {Global_buffer} \
    CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {148.5} \
    CONFIG.CLKOUT2_USED {true} \
    CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {742.5} \
    CONFIG.USE_LOCKED {true} \
    CONFIG.USE_RESET {true} \
    CONFIG.RESET_TYPE {ACTIVE_LOW} \
] [get_bd_cells clk_wiz_0]

create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 clk_wiz_1
set_property -dict [list \
    CONFIG.PRIM_SOURCE {Global_buffer} \
    CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {200} \
    CONFIG.USE_LOCKED {true} \
    CONFIG.USE_RESET {true} \
    CONFIG.RESET_TYPE {ACTIVE_LOW} \
] [get_bd_cells clk_wiz_1]

# Processor System Reset
create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_0
create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_1

# AXI Interconnect
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_0
set_property -dict [list CONFIG.NUM_MI {8}] [get_bd_cells axi_interconnect_0]

# AXI GPIO for camera power control
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 axi_gpio_0
set_property -dict [list \
    CONFIG.C_GPIO_WIDTH {1} \
    CONFIG.C_ALL_OUTPUTS {1} \
] [get_bd_cells axi_gpio_0]

# AXI IIC for camera control (SCCB)
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_iic:2.1 axi_iic_0

# =============================================================================
# Video IP Cores
# =============================================================================

# MIPI CSI-2 RX Subsystem
create_bd_cell -type ip -vlnv xilinx.com:ip:mipi_csi2_rx_subsystem:5.1 mipi_csi2_rx_subsystem_0
set_property -dict [list \
    CONFIG.CMN_NUM_LANES {2} \
    CONFIG.CMN_PXL_FORMAT {RAW10} \
    CONFIG.CMN_NUM_PIXELS {1} \
    CONFIG.C_DPHY_LANES {2} \
    CONFIG.DPY_LINE_RATE {672} \
    CONFIG.CLK_LANE_IO_LOC {J14} \
    CONFIG.DATA_LANE0_IO_LOC {M15} \
    CONFIG.DATA_LANE1_IO_LOC {L14} \
    CONFIG.SupportLevel {1} \
] [get_bd_cells mipi_csi2_rx_subsystem_0]

# Sensor Demosaic
create_bd_cell -type ip -vlnv xilinx.com:ip:v_demosaic:1.1 v_demosaic_0
set_property -dict [list \
    CONFIG.SAMPLES_PER_CLOCK {1} \
    CONFIG.MAX_COLS {1920} \
    CONFIG.MAX_ROWS {1080} \
    CONFIG.MAX_DATA_WIDTH {10} \
] [get_bd_cells v_demosaic_0]

# Gamma LUT
create_bd_cell -type ip -vlnv xilinx.com:ip:v_gamma_lut:1.1 v_gamma_lut_0
set_property -dict [list \
    CONFIG.SAMPLES_PER_CLOCK {1} \
    CONFIG.MAX_COLS {1920} \
    CONFIG.MAX_ROWS {1080} \
    CONFIG.MAX_DATA_WIDTH {10} \
] [get_bd_cells v_gamma_lut_0]

# Video Timing Controller - Detector (for camera input)
create_bd_cell -type ip -vlnv xilinx.com:ip:v_tc:6.2 v_tc_0
set_property -dict [list \
    CONFIG.enable_detection {true} \
    CONFIG.enable_generation {false} \
    CONFIG.max_lines_per_frame {1125} \
    CONFIG.max_pixels_per_line {2200} \
] [get_bd_cells v_tc_0]

# Video Timing Controller - Generator (for HDMI output)
create_bd_cell -type ip -vlnv xilinx.com:ip:v_tc:6.2 v_tc_1
set_property -dict [list \
    CONFIG.enable_detection {false} \
    CONFIG.enable_generation {true} \
    CONFIG.max_lines_per_frame {1125} \
    CONFIG.max_pixels_per_line {2200} \
] [get_bd_cells v_tc_1]

# AXI VDMA - Write Channel (camera to memory)
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_vdma:6.3 axi_vdma_0
set_property -dict [list \
    CONFIG.c_m_axi_mm2s_data_width {64} \
    CONFIG.c_m_axis_mm2s_tdata_width {24} \
    CONFIG.c_mm2s_genlock_mode {0} \
    CONFIG.c_mm2s_linebuffer_depth {4096} \
    CONFIG.c_mm2s_max_burst_length {16} \
    CONFIG.c_include_mm2s {0} \
    CONFIG.c_include_s2mm {1} \
    CONFIG.c_m_axi_s2mm_data_width {64} \
    CONFIG.c_s_axis_s2mm_tdata_width {24} \
    CONFIG.c_s2mm_genlock_mode {3} \
    CONFIG.c_s2mm_linebuffer_depth {4096} \
    CONFIG.c_s2mm_max_burst_length {16} \
    CONFIG.c_num_fstores {3} \
] [get_bd_cells axi_vdma_0]

# AXI VDMA - Read Channel (memory to HDMI)
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_vdma:6.3 axi_vdma_1
set_property -dict [list \
    CONFIG.c_m_axi_mm2s_data_width {64} \
    CONFIG.c_m_axis_mm2s_tdata_width {24} \
    CONFIG.c_mm2s_genlock_mode {2} \
    CONFIG.c_mm2s_linebuffer_depth {4096} \
    CONFIG.c_mm2s_max_burst_length {16} \
    CONFIG.c_include_mm2s {1} \
    CONFIG.c_include_s2mm {0} \
    CONFIG.c_num_fstores {3} \
] [get_bd_cells axi_vdma_1]

# AXI4-Stream to Video Out
create_bd_cell -type ip -vlnv xilinx.com:ip:v_axi4s_vid_out:4.0 v_axi4s_vid_out_0
set_property -dict [list \
    CONFIG.C_HAS_ASYNC_CLK {1} \
    CONFIG.C_VTG_MASTER_SLAVE {1} \
    CONFIG.C_S_AXIS_VIDEO_DATA_WIDTH {8} \
    CONFIG.C_S_AXIS_VIDEO_FORMAT {2} \
] [get_bd_cells v_axi4s_vid_out_0]

# RGB to DVI Video Encoder (Digilent IP)
create_bd_cell -type ip -vlnv digilentinc.com:ip:rgb2dvi:1.4 rgb2dvi_0
set_property -dict [list \
    CONFIG.kGenerateSerialClk {false} \
    CONFIG.kClkPrimitive {MMCM} \
    CONFIG.kClkRange {2} \
] [get_bd_cells rgb2dvi_0]

# Concat for interrupts
create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat_0
set_property -dict [list CONFIG.NUM_PORTS {2}] [get_bd_cells xlconcat_0]

# =============================================================================
# Connections
# =============================================================================

# Clock connections
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] \
    [get_bd_pins clk_wiz_0/clk_in1] \
    [get_bd_pins axi_interconnect_0/ACLK] \
    [get_bd_pins axi_interconnect_0/S00_ACLK] \
    [get_bd_pins axi_interconnect_0/M00_ACLK] \
    [get_bd_pins axi_interconnect_0/M01_ACLK] \
    [get_bd_pins axi_interconnect_0/M02_ACLK] \
    [get_bd_pins axi_interconnect_0/M03_ACLK] \
    [get_bd_pins axi_interconnect_0/M04_ACLK] \
    [get_bd_pins axi_interconnect_0/M05_ACLK] \
    [get_bd_pins axi_interconnect_0/M06_ACLK] \
    [get_bd_pins axi_interconnect_0/M07_ACLK] \
    [get_bd_pins proc_sys_reset_0/slowest_sync_clk] \
    [get_bd_pins axi_gpio_0/s_axi_aclk] \
    [get_bd_pins axi_iic_0/s_axi_aclk] \
    [get_bd_pins axi_vdma_0/s_axi_lite_aclk] \
    [get_bd_pins axi_vdma_1/s_axi_lite_aclk] \
    [get_bd_pins v_tc_0/s_axi_aclk] \
    [get_bd_pins v_tc_1/s_axi_aclk] \
    [get_bd_pins v_demosaic_0/ap_clk] \
    [get_bd_pins v_gamma_lut_0/ap_clk]

connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK1] \
    [get_bd_pins clk_wiz_1/clk_in1] \
    [get_bd_pins mipi_csi2_rx_subsystem_0/dphy_clk_200M]

connect_bd_net [get_bd_pins clk_wiz_0/clk_out1] \
    [get_bd_pins v_tc_1/clk] \
    [get_bd_pins v_axi4s_vid_out_0/vid_io_out_clk] \
    [get_bd_pins rgb2dvi_0/PixelClk] \
    [get_bd_pins axi_vdma_1/m_axis_mm2s_aclk] \
    [get_bd_pins proc_sys_reset_1/slowest_sync_clk]

connect_bd_net [get_bd_pins clk_wiz_0/clk_out2] \
    [get_bd_pins rgb2dvi_0/SerialClk]

# Reset connections
connect_bd_net [get_bd_pins processing_system7_0/FCLK_RESET0_N] \
    [get_bd_pins proc_sys_reset_0/ext_reset_in] \
    [get_bd_pins proc_sys_reset_1/ext_reset_in] \
    [get_bd_pins clk_wiz_0/resetn] \
    [get_bd_pins clk_wiz_1/resetn]

connect_bd_net [get_bd_pins proc_sys_reset_0/peripheral_aresetn] \
    [get_bd_pins axi_interconnect_0/ARESETN] \
    [get_bd_pins axi_interconnect_0/S00_ARESETN] \
    [get_bd_pins axi_interconnect_0/M00_ARESETN] \
    [get_bd_pins axi_interconnect_0/M01_ARESETN] \
    [get_bd_pins axi_interconnect_0/M02_ARESETN] \
    [get_bd_pins axi_interconnect_0/M03_ARESETN] \
    [get_bd_pins axi_interconnect_0/M04_ARESETN] \
    [get_bd_pins axi_interconnect_0/M05_ARESETN] \
    [get_bd_pins axi_interconnect_0/M06_ARESETN] \
    [get_bd_pins axi_interconnect_0/M07_ARESETN] \
    [get_bd_pins axi_gpio_0/s_axi_aresetn] \
    [get_bd_pins axi_iic_0/s_axi_aresetn] \
    [get_bd_pins axi_vdma_0/axi_resetn] \
    [get_bd_pins axi_vdma_1/axi_resetn] \
    [get_bd_pins v_tc_0/s_axi_aresetn] \
    [get_bd_pins v_tc_1/s_axi_aresetn] \
    [get_bd_pins v_demosaic_0/ap_rst_n] \
    [get_bd_pins v_gamma_lut_0/ap_rst_n]

connect_bd_net [get_bd_pins proc_sys_reset_1/peripheral_aresetn] \
    [get_bd_pins v_axi4s_vid_out_0/aresetn]

# AXI connections
connect_bd_intf_net [get_bd_intf_pins processing_system7_0/M_AXI_GP0] \
    [get_bd_intf_pins axi_interconnect_0/S00_AXI]

connect_bd_intf_net [get_bd_intf_pins axi_interconnect_0/M00_AXI] \
    [get_bd_intf_pins axi_gpio_0/S_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_interconnect_0/M01_AXI] \
    [get_bd_intf_pins axi_iic_0/S_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_interconnect_0/M02_AXI] \
    [get_bd_intf_pins axi_vdma_0/S_AXI_LITE]
connect_bd_intf_net [get_bd_intf_pins axi_interconnect_0/M03_AXI] \
    [get_bd_intf_pins axi_vdma_1/S_AXI_LITE]
connect_bd_intf_net [get_bd_intf_pins axi_interconnect_0/M04_AXI] \
    [get_bd_intf_pins v_tc_0/ctrl]
connect_bd_intf_net [get_bd_intf_pins axi_interconnect_0/M05_AXI] \
    [get_bd_intf_pins v_tc_1/ctrl]
connect_bd_intf_net [get_bd_intf_pins axi_interconnect_0/M06_AXI] \
    [get_bd_intf_pins v_demosaic_0/s_axi_CTRL]
connect_bd_intf_net [get_bd_intf_pins axi_interconnect_0/M07_AXI] \
    [get_bd_intf_pins v_gamma_lut_0/s_axi_CTRL]

# HP0 connections for VDMA
connect_bd_intf_net [get_bd_intf_pins axi_vdma_0/M_AXI_S2MM] \
    [get_bd_intf_pins processing_system7_0/S_AXI_HP0]
connect_bd_intf_net [get_bd_intf_pins axi_vdma_1/M_AXI_MM2S] \
    [get_bd_intf_pins processing_system7_0/S_AXI_HP0]

# Video stream connections (simplified - actual connections depend on IP configuration)
# MIPI → Demosaic → Gamma → VTC (detect) → VDMA (write)
# VDMA (read) → VTC (gen) → AXI4S to Video Out → RGB to DVI → HDMI

# Interrupt connections
connect_bd_net [get_bd_pins axi_vdma_0/s2mm_introut] [get_bd_pins xlconcat_0/In0]
connect_bd_net [get_bd_pins axi_vdma_1/mm2s_introut] [get_bd_pins xlconcat_0/In1]
connect_bd_net [get_bd_pins xlconcat_0/dout] [get_bd_pins processing_system7_0/IRQ_F2P]

# =============================================================================
# External Ports
# =============================================================================

# HDMI output
create_bd_port -dir O -from 2 -to 0 hdmi_tx_data_p
create_bd_port -dir O -from 2 -to 0 hdmi_tx_data_n
create_bd_port -dir O hdmi_tx_clk_p
create_bd_port -dir O hdmi_tx_clk_n

connect_bd_net [get_bd_pins rgb2dvi_0/TMDS_Clk_p] [get_bd_ports hdmi_tx_clk_p]
connect_bd_net [get_bd_pins rgb2dvi_0/TMDS_Clk_n] [get_bd_ports hdmi_tx_clk_n]
connect_bd_net [get_bd_pins rgb2dvi_0/TMDS_Data_p] [get_bd_ports hdmi_tx_data_p]
connect_bd_net [get_bd_pins rgb2dvi_0/TMDS_Data_n] [get_bd_ports hdmi_tx_data_n]

# Camera GPIO (directly from AXI GPIO port)
make_bd_pins_external [get_bd_pins axi_gpio_0/gpio_io_o]
set_property name cam_gpio_tri_o [get_bd_ports gpio_io_o_0]

# Camera I2C (directly from AXI IIC port)
make_bd_intf_pins_external [get_bd_intf_pins axi_iic_0/IIC]
set_property name cam_iic [get_bd_intf_ports IIC_0]

# MIPI camera interface (directly from MIPI CSI-2 port)
# Note: MIPI connections are handled internally by the MIPI CSI-2 subsystem

# =============================================================================
# Address Assignment
# =============================================================================

assign_bd_address

# =============================================================================
# Validate and Save
# =============================================================================

validate_bd_design
save_bd_design

# Create HDL wrapper
make_wrapper -files [get_files design_1.bd] -top
add_files -norecurse [get_files design_1_wrapper.v]

puts "Block design created successfully!"
puts "Next steps:"
puts "1. Add XDC constraints file"
puts "2. Run Synthesis"
puts "3. Run Implementation"
puts "4. Generate Bitstream"
puts "5. Export Hardware (Include Bitstream)"
