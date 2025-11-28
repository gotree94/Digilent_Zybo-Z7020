# =============================================================================
# Zynq Z7-20 PCAM5C HDMI Output - Vivado Block Design TCL Script
# =============================================================================
# 
# Target Board: Digilent Zynq Z7-20
# Vivado Version: 2022.2
# 
# Prerequisites:
#   - Digilent vivado-library added to IP Repository
#
# Key Fix: dphy_hs_clock interface must remain as interface (not individual pins)
#          because Digilent IP's propagate script reads FREQ_HZ from this interface
#
# =============================================================================

set project_name "zynq_z7_pcam_hdmi"
set bd_name "design_1"

puts "============================================================"
puts " Creating Block Design: $bd_name"
puts "============================================================"

create_bd_design $bd_name
update_compile_order -fileset sources_1

# =============================================================================
# 1. ZYNQ7 Processing System
# =============================================================================
puts "\[1/13\] Adding ZYNQ7 Processing System..."

create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0

apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config {
    make_external "FIXED_IO, DDR" 
    apply_board_preset "1" 
    Master "Disable" 
    Slave "Disable" 
} [get_bd_cells processing_system7_0]

set_property -dict [list \
    CONFIG.PCW_USE_S_AXI_HP0 {1} \
    CONFIG.PCW_USE_FABRIC_INTERRUPT {1} \
    CONFIG.PCW_IRQ_F2P_INTR {1} \
    CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {100} \
    CONFIG.PCW_FPGA1_PERIPHERAL_FREQMHZ {200} \
    CONFIG.PCW_FPGA2_PERIPHERAL_FREQMHZ {50} \
    CONFIG.PCW_EN_CLK1_PORT {1} \
    CONFIG.PCW_EN_CLK2_PORT {1} \
    CONFIG.PCW_USE_M_AXI_GP0 {1} \
] [get_bd_cells processing_system7_0]

# =============================================================================
# 2. Clocking Wizards
# =============================================================================
puts "\[2/14\] Adding Clocking Wizards..."

# clk_wiz_0: HDMI 픽셀 클럭용
create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 clk_wiz_0
set_property -dict [list \
    CONFIG.PRIMITIVE {MMCM} \
    CONFIG.PRIM_SOURCE {Global_buffer} \
    CONFIG.PRIM_IN_FREQ {100.000} \
    CONFIG.CLKOUT1_USED {true} \
    CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {148.500} \
    CONFIG.CLKOUT2_USED {true} \
    CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {742.500} \
    CONFIG.USE_LOCKED {true} \
    CONFIG.USE_RESET {true} \
    CONFIG.RESET_TYPE {ACTIVE_LOW} \
    CONFIG.RESET_PORT {resetn} \
] [get_bd_cells clk_wiz_0]

# clk_wiz_1: 카메라용 (선택사항 - FCLK_CLK1 직접 사용 가능)
create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 clk_wiz_1
set_property -dict [list \
    CONFIG.PRIMITIVE {MMCM} \
    CONFIG.PRIM_SOURCE {Global_buffer} \
    CONFIG.PRIM_IN_FREQ {200.000} \
    CONFIG.CLKOUT1_USED {true} \
    CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {200.000} \
    CONFIG.USE_LOCKED {true} \
    CONFIG.USE_RESET {true} \
    CONFIG.RESET_TYPE {ACTIVE_LOW} \
    CONFIG.RESET_PORT {resetn} \
] [get_bd_cells clk_wiz_1]

# =============================================================================
# 3. Processor System Reset
# =============================================================================
puts "\[3/14\] Adding Processor System Reset blocks..."

create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_0
create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_1
create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 proc_sys_reset_2

# =============================================================================
# 4. AXI Interconnect
# =============================================================================
puts "\[4/14\] Adding AXI Interconnect..."

create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_0
set_property -dict [list \
    CONFIG.NUM_SI {1} \
    CONFIG.NUM_MI {9} \
] [get_bd_cells axi_interconnect_0]

create_bd_cell -type ip -vlnv xilinx.com:ip:smartconnect:1.0 axi_smc_0
set_property -dict [list \
    CONFIG.NUM_SI {2} \
    CONFIG.NUM_MI {1} \
    CONFIG.NUM_CLKS {2} \
] [get_bd_cells axi_smc_0]

# =============================================================================
# 5. AXI GPIO - Camera Power Control
# =============================================================================
puts "\[5/14\] Adding AXI GPIO for camera control..."

create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 axi_gpio_0
set_property -dict [list \
    CONFIG.C_GPIO_WIDTH {1} \
    CONFIG.C_ALL_OUTPUTS {1} \
    CONFIG.C_DOUT_DEFAULT {0x00000000} \
] [get_bd_cells axi_gpio_0]

# =============================================================================
# 6. AXI IIC - Camera SCCB Interface
# =============================================================================
puts "\[6/14\] Adding AXI IIC for camera SCCB..."

create_bd_cell -type ip -vlnv xilinx.com:ip:axi_iic:2.1 axi_iic_0
set_property -dict [list \
    CONFIG.IIC_FREQ_KHZ {100} \
] [get_bd_cells axi_iic_0]

# =============================================================================
# 7. Digilent MIPI D-PHY and CSI-2 Receiver
# =============================================================================
puts "\[7/14\] Adding Digilent MIPI D-PHY and CSI-2 Receiver..."

create_bd_cell -type ip -vlnv digilentinc.com:ip:MIPI_D_PHY_RX:1.3 MIPI_D_PHY_RX_0
set_property -dict [list \
    CONFIG.kNoOfDataLanes {2} \
    CONFIG.kGenerateAXIL {true} \
    CONFIG.kAddDelayClk_ps {0} \
    CONFIG.kAddDelayData0_ps {0} \
    CONFIG.kAddDelayData1_ps {0} \
] [get_bd_cells MIPI_D_PHY_RX_0]

create_bd_cell -type ip -vlnv digilentinc.com:ip:MIPI_CSI_2_RX:1.2 MIPI_CSI_2_RX_0
set_property -dict [list \
    CONFIG.kTargetDT {RAW10} \
] [get_bd_cells MIPI_CSI_2_RX_0]

# =============================================================================
# 8. AXI4-Stream Subset Converter (RAW10 to RAW8)
# =============================================================================
puts "\[8/14\] Adding AXI4-Stream Infrastructure..."

create_bd_cell -type ip -vlnv xilinx.com:ip:axis_subset_converter:1.1 axis_subset_converter_0
set_property -dict [list \
    CONFIG.S_TDATA_NUM_BYTES {5} \
    CONFIG.M_TDATA_NUM_BYTES {1} \
    CONFIG.S_HAS_TKEEP {1} \
    CONFIG.S_HAS_TLAST {1} \
    CONFIG.M_HAS_TLAST {1} \
    CONFIG.TDATA_REMAP {tdata[9:2]} \
    CONFIG.TLAST_REMAP {tlast[0]} \
] [get_bd_cells axis_subset_converter_0]

# =============================================================================
# 9. Video Processing Pipeline
# =============================================================================
puts "\[9/14\] Adding Video Processing IPs..."

create_bd_cell -type ip -vlnv xilinx.com:ip:v_demosaic:1.1 v_demosaic_0
set_property -dict [list \
    CONFIG.SAMPLES_PER_CLOCK {1} \
    CONFIG.MAX_COLS {1920} \
    CONFIG.MAX_ROWS {1080} \
    CONFIG.MAX_DATA_WIDTH {8} \
    CONFIG.USE_URAM {0} \
] [get_bd_cells v_demosaic_0]

create_bd_cell -type ip -vlnv xilinx.com:ip:v_gamma_lut:1.1 v_gamma_lut_0
set_property -dict [list \
    CONFIG.SAMPLES_PER_CLOCK {1} \
    CONFIG.MAX_COLS {1920} \
    CONFIG.MAX_ROWS {1080} \
    CONFIG.MAX_DATA_WIDTH {8} \
] [get_bd_cells v_gamma_lut_0]

# Video Timing Controller - Detector (입력)
create_bd_cell -type ip -vlnv xilinx.com:ip:v_tc:6.2 v_tc_in
set_property -dict [list \
    CONFIG.enable_detection {true} \
    CONFIG.enable_generation {false} \
    CONFIG.HAS_INTC_IF {true} \
    CONFIG.max_lines_per_frame {2048} \
] [get_bd_cells v_tc_in]

# Video Timing Controller - Generator (출력)
create_bd_cell -type ip -vlnv xilinx.com:ip:v_tc:6.2 v_tc_out
set_property -dict [list \
    CONFIG.enable_detection {false} \
    CONFIG.enable_generation {true} \
    CONFIG.HAS_INTC_IF {true} \
    CONFIG.max_lines_per_frame {2048} \
    CONFIG.VIDEO_MODE {1080p} \
] [get_bd_cells v_tc_out]

# =============================================================================
# 10. AXI VDMA - Video DMA
# =============================================================================
puts "\[10/14\] Adding AXI VDMA..."

create_bd_cell -type ip -vlnv xilinx.com:ip:axi_vdma:6.3 axi_vdma_0
set_property -dict [list \
    CONFIG.c_num_fstores {3} \
    CONFIG.c_include_mm2s {0} \
    CONFIG.c_include_s2mm {1} \
    CONFIG.c_m_axi_s2mm_data_width {64} \
    CONFIG.c_s2mm_linebuffer_depth {4096} \
    CONFIG.c_s2mm_max_burst_length {256} \
    CONFIG.c_s2mm_genlock_mode {3} \
    CONFIG.c_include_s2mm_dre {1} \
] [get_bd_cells axi_vdma_0]

create_bd_cell -type ip -vlnv xilinx.com:ip:axi_vdma:6.3 axi_vdma_1
set_property -dict [list \
    CONFIG.c_num_fstores {3} \
    CONFIG.c_include_mm2s {1} \
    CONFIG.c_include_s2mm {0} \
    CONFIG.c_m_axi_mm2s_data_width {64} \
    CONFIG.c_mm2s_linebuffer_depth {4096} \
    CONFIG.c_mm2s_max_burst_length {256} \
    CONFIG.c_mm2s_genlock_mode {2} \
    CONFIG.c_include_mm2s_dre {1} \
] [get_bd_cells axi_vdma_1]

# =============================================================================
# 11. AXI4-Stream to Video Out
# =============================================================================
puts "\[11/14\] Adding AXI4-Stream to Video Out..."

create_bd_cell -type ip -vlnv xilinx.com:ip:v_axi4s_vid_out:4.0 v_axi4s_vid_out_0
set_property -dict [list \
    CONFIG.C_HAS_ASYNC_CLK {1} \
    CONFIG.C_VTG_MASTER_SLAVE {1} \
    CONFIG.C_S_AXIS_VIDEO_DATA_WIDTH {8} \
    CONFIG.C_S_AXIS_VIDEO_FORMAT {2} \
    CONFIG.C_NATIVE_COMPONENT_WIDTH {8} \
    CONFIG.C_ADDR_WIDTH {12} \
    CONFIG.C_HYSTERESIS_LEVEL {12} \
] [get_bd_cells v_axi4s_vid_out_0]

# =============================================================================
# 12. RGB to DVI Video Encoder (Digilent IP)
# =============================================================================
puts "\[12/14\] Adding RGB to DVI Video Encoder..."

create_bd_cell -type ip -vlnv digilentinc.com:ip:rgb2dvi:1.4 rgb2dvi_0
set_property -dict [list \
    CONFIG.kGenerateSerialClk {true} \
    CONFIG.kClkPrimitive {MMCM} \
    CONFIG.kClkRange {1} \
    CONFIG.kRstActiveHigh {false} \
    CONFIG.TMDS_BOARD_INTERFACE {Custom} \
] [get_bd_cells rgb2dvi_0]
# kClkRange: 1 = 120-160 MHz (for 1080p @ 148.5MHz)
#            2 = 60-120 MHz (for 720p @ 74.25MHz)
#            3 = 40-60 MHz (for lower resolutions)
# Note: TMDS_BOARD_INTERFACE set to Custom to allow LVDS_25 in XDC

# =============================================================================
# 13. Utility IPs
# =============================================================================
puts "\[13/14\] Adding Utility IPs..."

create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat_0
set_property -dict [list \
    CONFIG.NUM_PORTS {2} \
] [get_bd_cells xlconcat_0]

create_bd_cell -type ip -vlnv xilinx.com:ip:xlconstant:1.1 const_vcc
set_property -dict [list \
    CONFIG.CONST_VAL {1} \
    CONFIG.CONST_WIDTH {1} \
] [get_bd_cells const_vcc]

# =============================================================================
# EXTERNAL PORTS - Create HDMI and Camera control ports
# =============================================================================
puts "Creating external ports..."

# HDMI TX Output
create_bd_port -dir O -from 2 -to 0 hdmi_tx_data_p
create_bd_port -dir O -from 2 -to 0 hdmi_tx_data_n
create_bd_port -dir O hdmi_tx_clk_p
create_bd_port -dir O hdmi_tx_clk_n

# Camera Power GPIO
create_bd_port -dir O -from 0 -to 0 cam_gpio

# Camera I2C (SCCB)
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:iic_rtl:1.0 cam_iic

# =============================================================================
# MIPI D-PHY External Ports
# CRITICAL: dphy_hs_clock must be exported as INTERFACE (not individual pins)
#           because Digilent IP reads FREQ_HZ from this interface in propagate()
# =============================================================================
puts "Creating MIPI external ports..."

# Create interface port for HS Clock with FREQ_HZ property
# This is required by Digilent IP's propagate script
create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:diff_clock_rtl:1.0 dphy_hs_clock
set_property CONFIG.FREQ_HZ 336000000 [get_bd_intf_ports dphy_hs_clock]

# HS Data - individual pins (no interface dependency)
create_bd_port -dir I -from 1 -to 0 dphy_data_hs_p
create_bd_port -dir I -from 1 -to 0 dphy_data_hs_n

# LP Clock - individual pins
create_bd_port -dir I dphy_clk_lp_p
create_bd_port -dir I dphy_clk_lp_n

# LP Data - individual pins
create_bd_port -dir I -from 1 -to 0 dphy_data_lp_p
create_bd_port -dir I -from 1 -to 0 dphy_data_lp_n

# =============================================================================
# CONNECTIONS - MIPI D-PHY External
# =============================================================================
puts "Connecting MIPI external ports..."

# Connect HS Clock as interface
connect_bd_intf_net [get_bd_intf_ports dphy_hs_clock] [get_bd_intf_pins MIPI_D_PHY_RX_0/dphy_hs_clock]

# Connect HS Data
connect_bd_net [get_bd_ports dphy_data_hs_p] [get_bd_pins MIPI_D_PHY_RX_0/dphy_data_hs_p]
connect_bd_net [get_bd_ports dphy_data_hs_n] [get_bd_pins MIPI_D_PHY_RX_0/dphy_data_hs_n]

# Connect LP Clock
connect_bd_net [get_bd_ports dphy_clk_lp_p] [get_bd_pins MIPI_D_PHY_RX_0/dphy_clk_lp_p]
connect_bd_net [get_bd_ports dphy_clk_lp_n] [get_bd_pins MIPI_D_PHY_RX_0/dphy_clk_lp_n]

# Connect LP Data
connect_bd_net [get_bd_ports dphy_data_lp_p] [get_bd_pins MIPI_D_PHY_RX_0/dphy_data_lp_p]
connect_bd_net [get_bd_ports dphy_data_lp_n] [get_bd_pins MIPI_D_PHY_RX_0/dphy_data_lp_n]

# =============================================================================
# CONNECTIONS - Clock Network
# =============================================================================
puts "Connecting clocks..."

# FCLK_CLK0 (100 MHz) - AXI bus and video processing clock
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] \
    [get_bd_pins clk_wiz_0/clk_in1] \
    [get_bd_pins proc_sys_reset_0/slowest_sync_clk] \
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
    [get_bd_pins axi_interconnect_0/M08_ACLK] \
    [get_bd_pins axi_gpio_0/s_axi_aclk] \
    [get_bd_pins axi_iic_0/s_axi_aclk] \
    [get_bd_pins axi_vdma_0/s_axi_lite_aclk] \
    [get_bd_pins axi_vdma_1/s_axi_lite_aclk] \
    [get_bd_pins v_tc_in/s_axi_aclk] \
    [get_bd_pins v_tc_out/s_axi_aclk] \
    [get_bd_pins axis_subset_converter_0/aclk] \
    [get_bd_pins v_demosaic_0/ap_clk] \
    [get_bd_pins v_gamma_lut_0/ap_clk] \
    [get_bd_pins axi_vdma_0/s_axis_s2mm_aclk] \
    [get_bd_pins axi_vdma_0/m_axi_s2mm_aclk] \
    [get_bd_pins axi_smc_0/aclk] \
    [get_bd_pins processing_system7_0/S_AXI_HP0_ACLK] \
    [get_bd_pins processing_system7_0/M_AXI_GP0_ACLK] \
    [get_bd_pins MIPI_CSI_2_RX_0/video_aclk] \
    [get_bd_pins MIPI_D_PHY_RX_0/s_axi_lite_aclk] \
    [get_bd_pins v_tc_in/clk]

# FCLK_CLK1 (200 MHz) - clk_wiz_1 input
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK1] \
    [get_bd_pins clk_wiz_1/clk_in1] \
    [get_bd_pins proc_sys_reset_2/slowest_sync_clk]

# clk_wiz_1 output (200 MHz) - MIPI D-PHY reference clock
connect_bd_net [get_bd_pins clk_wiz_1/clk_out1] \
    [get_bd_pins MIPI_D_PHY_RX_0/RefClk]

# Pixel clock (148.5 MHz) - HDMI output path
connect_bd_net [get_bd_pins clk_wiz_0/clk_out1] \
    [get_bd_pins proc_sys_reset_1/slowest_sync_clk] \
    [get_bd_pins v_tc_out/clk] \
    [get_bd_pins v_axi4s_vid_out_0/vid_io_out_clk] \
    [get_bd_pins v_axi4s_vid_out_0/aclk] \
    [get_bd_pins axi_vdma_1/m_axis_mm2s_aclk] \
    [get_bd_pins axi_vdma_1/m_axi_mm2s_aclk] \
    [get_bd_pins rgb2dvi_0/PixelClk] \
    [get_bd_pins axi_smc_0/aclk1]

# MIPI RxByteClkHS to CSI-2 receiver
connect_bd_net [get_bd_pins MIPI_D_PHY_RX_0/RxByteClkHS] \
    [get_bd_pins MIPI_CSI_2_RX_0/RxByteClkHS]

# =============================================================================
# CONNECTIONS - Reset Network
# =============================================================================
puts "Connecting resets..."

# Master reset from PS
connect_bd_net [get_bd_pins processing_system7_0/FCLK_RESET0_N] \
    [get_bd_pins proc_sys_reset_0/ext_reset_in] \
    [get_bd_pins proc_sys_reset_1/ext_reset_in] \
    [get_bd_pins proc_sys_reset_2/ext_reset_in] \
    [get_bd_pins clk_wiz_0/resetn] \
    [get_bd_pins clk_wiz_1/resetn]

# Clock locked signals
connect_bd_net [get_bd_pins clk_wiz_0/locked] \
    [get_bd_pins proc_sys_reset_1/dcm_locked]

connect_bd_net [get_bd_pins clk_wiz_1/locked] \
    [get_bd_pins proc_sys_reset_2/dcm_locked]

# AXI peripheral resets (active low)
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
    [get_bd_pins axi_interconnect_0/M08_ARESETN] \
    [get_bd_pins axi_gpio_0/s_axi_aresetn] \
    [get_bd_pins axi_iic_0/s_axi_aresetn] \
    [get_bd_pins axi_vdma_0/axi_resetn] \
    [get_bd_pins axi_vdma_1/axi_resetn] \
    [get_bd_pins v_tc_in/s_axi_aresetn] \
    [get_bd_pins v_tc_out/s_axi_aresetn] \
    [get_bd_pins axi_smc_0/aresetn] \
    [get_bd_pins axis_subset_converter_0/aresetn] \
    [get_bd_pins v_demosaic_0/ap_rst_n] \
    [get_bd_pins v_gamma_lut_0/ap_rst_n] \
    [get_bd_pins MIPI_CSI_2_RX_0/video_aresetn] \
    [get_bd_pins MIPI_D_PHY_RX_0/s_axi_lite_aresetn] \
    [get_bd_pins v_tc_in/resetn]

# MIPI D-PHY aRst - use proc_sys_reset_2 (RefClk domain)
connect_bd_net [get_bd_pins proc_sys_reset_2/peripheral_aresetn] \
    [get_bd_pins MIPI_D_PHY_RX_0/aRst]

# Pixel clock domain reset
connect_bd_net [get_bd_pins proc_sys_reset_1/peripheral_aresetn] \
    [get_bd_pins v_axi4s_vid_out_0/aresetn] \
    [get_bd_pins rgb2dvi_0/aRst_n]

# VTC Generator reset (needs ACTIVE_LOW reset)
connect_bd_net [get_bd_pins proc_sys_reset_1/peripheral_aresetn] \
    [get_bd_pins v_tc_out/resetn]

# =============================================================================
# CONNECTIONS - AXI Interfaces
# =============================================================================
puts "Connecting AXI interfaces..."

# PS GP0 Master to Interconnect
connect_bd_intf_net [get_bd_intf_pins processing_system7_0/M_AXI_GP0] \
    [get_bd_intf_pins axi_interconnect_0/S00_AXI]

# Interconnect to peripherals
connect_bd_intf_net [get_bd_intf_pins axi_interconnect_0/M00_AXI] \
    [get_bd_intf_pins axi_gpio_0/S_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_interconnect_0/M01_AXI] \
    [get_bd_intf_pins axi_iic_0/S_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_interconnect_0/M02_AXI] \
    [get_bd_intf_pins axi_vdma_0/S_AXI_LITE]
connect_bd_intf_net [get_bd_intf_pins axi_interconnect_0/M03_AXI] \
    [get_bd_intf_pins axi_vdma_1/S_AXI_LITE]
connect_bd_intf_net [get_bd_intf_pins axi_interconnect_0/M04_AXI] \
    [get_bd_intf_pins v_tc_in/ctrl]
connect_bd_intf_net [get_bd_intf_pins axi_interconnect_0/M05_AXI] \
    [get_bd_intf_pins v_tc_out/ctrl]
connect_bd_intf_net [get_bd_intf_pins axi_interconnect_0/M06_AXI] \
    [get_bd_intf_pins v_demosaic_0/s_axi_CTRL]
connect_bd_intf_net [get_bd_intf_pins axi_interconnect_0/M07_AXI] \
    [get_bd_intf_pins v_gamma_lut_0/s_axi_CTRL]
connect_bd_intf_net [get_bd_intf_pins axi_interconnect_0/M08_AXI] \
    [get_bd_intf_pins MIPI_D_PHY_RX_0/S_AXI_LITE]

# VDMA to SmartConnect to HP0
connect_bd_intf_net [get_bd_intf_pins axi_vdma_0/M_AXI_S2MM] \
    [get_bd_intf_pins axi_smc_0/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_vdma_1/M_AXI_MM2S] \
    [get_bd_intf_pins axi_smc_0/S01_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_smc_0/M00_AXI] \
    [get_bd_intf_pins processing_system7_0/S_AXI_HP0]

# =============================================================================
# CONNECTIONS - MIPI Pipeline (D-PHY to CSI-2)
# =============================================================================
puts "Connecting MIPI pipeline..."

# Connect D-PHY to CSI-2 using interface connection (PPI interface)
connect_bd_intf_net [get_bd_intf_pins MIPI_D_PHY_RX_0/D_PHY_PPI] \
    [get_bd_intf_pins MIPI_CSI_2_RX_0/rx_mipi_ppi]

# =============================================================================
# CONNECTIONS - Video Pipeline
# =============================================================================
puts "Connecting video pipeline..."

# CSI-2 RX -> Subset Converter (RAW10 to RAW8)
connect_bd_intf_net [get_bd_intf_pins MIPI_CSI_2_RX_0/m_axis_video] \
    [get_bd_intf_pins axis_subset_converter_0/S_AXIS]

# Subset Converter -> Demosaic
connect_bd_intf_net [get_bd_intf_pins axis_subset_converter_0/M_AXIS] \
    [get_bd_intf_pins v_demosaic_0/s_axis_video]

# Demosaic -> Gamma LUT
connect_bd_intf_net [get_bd_intf_pins v_demosaic_0/m_axis_video] \
    [get_bd_intf_pins v_gamma_lut_0/s_axis_video]

# Gamma LUT -> VDMA Write
connect_bd_intf_net [get_bd_intf_pins v_gamma_lut_0/m_axis_video] \
    [get_bd_intf_pins axi_vdma_0/S_AXIS_S2MM]

# VDMA Read -> Video Out
connect_bd_intf_net [get_bd_intf_pins axi_vdma_1/M_AXIS_MM2S] \
    [get_bd_intf_pins v_axi4s_vid_out_0/video_in]

# VTC Generator -> Video Out timing
connect_bd_intf_net [get_bd_intf_pins v_tc_out/vtiming_out] \
    [get_bd_intf_pins v_axi4s_vid_out_0/vtiming_in]

# Video Out -> RGB2DVI
connect_bd_net [get_bd_pins v_axi4s_vid_out_0/vid_data] \
    [get_bd_pins rgb2dvi_0/vid_pData]
connect_bd_net [get_bd_pins v_axi4s_vid_out_0/vid_hsync] \
    [get_bd_pins rgb2dvi_0/vid_pHSync]
connect_bd_net [get_bd_pins v_axi4s_vid_out_0/vid_vsync] \
    [get_bd_pins rgb2dvi_0/vid_pVSync]
connect_bd_net [get_bd_pins v_axi4s_vid_out_0/vid_active_video] \
    [get_bd_pins rgb2dvi_0/vid_pVDE]

# VTC clock enables
connect_bd_net [get_bd_pins const_vcc/dout] \
    [get_bd_pins v_tc_in/clken] \
    [get_bd_pins v_tc_in/det_clken] \
    [get_bd_pins v_tc_out/clken] \
    [get_bd_pins v_tc_out/gen_clken] \
    [get_bd_pins v_axi4s_vid_out_0/aclken] \
    [get_bd_pins v_axi4s_vid_out_0/vid_io_out_ce]

# Video Out locked feedback
connect_bd_net [get_bd_pins v_axi4s_vid_out_0/locked] \
    [get_bd_pins v_tc_out/fsync_in]

# =============================================================================
# CONNECTIONS - Other External Ports
# =============================================================================
puts "Connecting other external ports..."

# HDMI
connect_bd_net [get_bd_pins rgb2dvi_0/TMDS_Clk_p] [get_bd_ports hdmi_tx_clk_p]
connect_bd_net [get_bd_pins rgb2dvi_0/TMDS_Clk_n] [get_bd_ports hdmi_tx_clk_n]
connect_bd_net [get_bd_pins rgb2dvi_0/TMDS_Data_p] [get_bd_ports hdmi_tx_data_p]
connect_bd_net [get_bd_pins rgb2dvi_0/TMDS_Data_n] [get_bd_ports hdmi_tx_data_n]

# Camera GPIO
connect_bd_net [get_bd_pins axi_gpio_0/gpio_io_o] [get_bd_ports cam_gpio]

# Camera I2C
connect_bd_intf_net [get_bd_intf_pins axi_iic_0/IIC] [get_bd_intf_ports cam_iic]

# =============================================================================
# CONNECTIONS - Interrupts
# =============================================================================
puts "Connecting interrupts..."

connect_bd_net [get_bd_pins axi_vdma_0/s2mm_introut] \
    [get_bd_pins xlconcat_0/In0]
connect_bd_net [get_bd_pins axi_vdma_1/mm2s_introut] \
    [get_bd_pins xlconcat_0/In1]

connect_bd_net [get_bd_pins xlconcat_0/dout] \
    [get_bd_pins processing_system7_0/IRQ_F2P]

# =============================================================================
# ADDRESS ASSIGNMENT
# =============================================================================
puts "Assigning addresses..."

assign_bd_address

# =============================================================================
# VALIDATE AND SAVE
# =============================================================================
puts "Validating design..."

regenerate_bd_layout
validate_bd_design
save_bd_design

# =============================================================================
# CREATE HDL WRAPPER
# =============================================================================
puts "Creating HDL wrapper..."

make_wrapper -files [get_files ${bd_name}.bd] -top
set wrapper_file [get_files -filter {FILE_TYPE == "Verilog Header" || FILE_TYPE == "Verilog"} *${bd_name}_wrapper*]
if {$wrapper_file ne ""} {
    add_files -norecurse $wrapper_file
    set_property top ${bd_name}_wrapper [current_fileset]
}

# =============================================================================
# COMPLETION MESSAGE
# =============================================================================
puts ""
puts "============================================================"
puts " Block Design Created Successfully!"
puts "============================================================"
puts ""
puts " Design Summary:"
puts "   - ZYNQ PS: 100MHz AXI, 200MHz MIPI ref clock, 50MHz reserve"
puts "   - Clocking Wizards: clk_wiz_0 (148.5/742.5 MHz), clk_wiz_1 (200 MHz)"
puts "   - Pixel Clock: 148.5 MHz (generated by clk_wiz_0)"
puts "   - Serial Clock: 742.5 MHz (generated by RGB2DVI or clk_wiz_0)"
puts "   - Video Resolution: 1920x1080 @ 60Hz"
puts "   - Frame Buffers: 3 (Triple buffering)"
puts "   - Video Timing Controllers: v_tc_in (Detector), v_tc_out (Generator)"
puts ""
puts " MIPI External Ports:"
puts "   - dphy_hs_clock: HS Clock interface (diff_clock_rtl)"
puts "   - dphy_data_hs_p/n[1:0]: HS Data differential pairs"
puts "   - dphy_clk_lp_p/n: LP Clock signals"
puts "   - dphy_data_lp_p/n[1:0]: LP Data signals"
puts ""
puts " Next Steps:"
puts "   1. Add XDC constraints file"
puts "   2. Run Synthesis"
puts "   3. Run Implementation"
puts "   4. Generate Bitstream"
puts "   5. Export Hardware (Include bitstream)"
puts "   6. Launch Vitis for software development"
puts ""
puts "============================================================"