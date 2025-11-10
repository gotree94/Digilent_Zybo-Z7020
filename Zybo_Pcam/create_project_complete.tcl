# Zybo Z7-20 PCAM 5C to HDMI - Complete with XDC

set project_name "zybo_pcam_hdmi"
set project_dir "./vivado_project"
set digilent_ip_dir "./digilent_ip"

puts "=========================================="
puts "Checking Digilent IP"
puts "=========================================="

set rgb2dvi_exists 0
if {[file exists "$digilent_ip_dir/vivado-library/ip"]} {
    puts "Digilent IP found!"
    set rgb2dvi_exists 1
} else {
    puts "WARNING: No Digilent IP"
}

puts "\nCreating Project..."
create_project $project_name $project_dir -part xc7z020clg400-1 -force
set_property board_part digilentinc.com:zybo-z7-20:part0:1.1 [current_project]

if {$rgb2dvi_exists} {
    set_property ip_repo_paths [list $digilent_ip_dir/vivado-library/ip] [current_project]
    update_ip_catalog
}

create_bd_design "system"

# Processing System - 3 clocks: 100/150/200MHz
create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0
set_property -dict [list \
    CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {100} \
    CONFIG.PCW_FPGA1_PERIPHERAL_FREQMHZ {150} \
    CONFIG.PCW_FPGA2_PERIPHERAL_FREQMHZ {200} \
    CONFIG.PCW_EN_CLK1_PORT {1} \
    CONFIG.PCW_EN_CLK2_PORT {1} \
    CONFIG.PCW_USE_S_AXI_HP0 {1} \
    CONFIG.PCW_USE_M_AXI_GP0 {1} \
    CONFIG.PCW_EN_CLK0_PORT {1} \
    CONFIG.PCW_QSPI_GRP_SINGLE_SS_ENABLE {1} \
    CONFIG.PCW_SD0_PERIPHERAL_ENABLE {1} \
    CONFIG.PCW_UART1_PERIPHERAL_ENABLE {1} \
    CONFIG.PCW_I2C0_PERIPHERAL_ENABLE {1} \
    CONFIG.PCW_GPIO_MIO_GPIO_ENABLE {1} \
] [get_bd_cells processing_system7_0]

# MIPI CSI-2 RX
create_bd_cell -type ip -vlnv xilinx.com:ip:mipi_csi2_rx_subsystem:5.2 mipi_csi2_rx_subsystem_0
set_property -dict [list \
    CONFIG.CMN_NUM_LANES {2} \
    CONFIG.CMN_PXL_FORMAT {RAW10} \
    CONFIG.CMN_VC {0} \
    CONFIG.DPY_LINE_RATE {672} \
    CONFIG.C_DPHY_LANES {2} \
    CONFIG.CMN_NUM_PIXELS {1} \
    CONFIG.C_HS_LINE_RATE {672} \
    CONFIG.C_EN_7S_LINERATE_CHECK {true} \
    CONFIG.C_HS_SETTLE_NS {145} \
] [get_bd_cells mipi_csi2_rx_subsystem_0]

# Video Processing
create_bd_cell -type ip -vlnv xilinx.com:ip:v_demosaic:1.1 v_demosaic_0
set_property -dict [list \
    CONFIG.MAX_COLS {1280} \
    CONFIG.MAX_ROWS {720} \
    CONFIG.SAMPLES_PER_CLOCK {1} \
    CONFIG.MAX_DATA_WIDTH {10} \
] [get_bd_cells v_demosaic_0]

create_bd_cell -type ip -vlnv xilinx.com:ip:v_gamma_lut:1.1 v_gamma_lut_0
set_property -dict [list \
    CONFIG.MAX_COLS {1280} \
    CONFIG.MAX_ROWS {720} \
    CONFIG.SAMPLES_PER_CLOCK {1} \
    CONFIG.MAX_DATA_WIDTH {10} \
] [get_bd_cells v_gamma_lut_0]

# Video Timing Controller
create_bd_cell -type ip -vlnv xilinx.com:ip:v_tc:6.2 v_tc_0
set_property -dict [list \
    CONFIG.VIDEO_MODE {720p} \
    CONFIG.GEN_HACTIVE_SIZE {1280} \
    CONFIG.GEN_VACTIVE_SIZE {720} \
    CONFIG.enable_detection {false} \
] [get_bd_cells v_tc_0]

# AXI VDMA
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_vdma:6.3 axi_vdma_0
set_property -dict [list \
    CONFIG.c_m_axi_s2mm_data_width {64} \
    CONFIG.c_m_axi_mm2s_data_width {64} \
    CONFIG.c_m_axis_mm2s_tdata_width {24} \
    CONFIG.c_mm2s_genlock_mode {0} \
    CONFIG.c_include_s2mm {1} \
    CONFIG.c_include_mm2s {1} \
    CONFIG.c_s2mm_max_burst_length {32} \
    CONFIG.c_mm2s_max_burst_length {32} \
    CONFIG.c_num_fstores {3} \
] [get_bd_cells axi_vdma_0]

# Video Out
create_bd_cell -type ip -vlnv xilinx.com:ip:v_axi4s_vid_out:4.0 v_axi4s_vid_out_0
set_property -dict [list \
    CONFIG.C_HAS_ASYNC_CLK {1} \
    CONFIG.C_VTG_MASTER_SLAVE {1} \
] [get_bd_cells v_axi4s_vid_out_0]

# Try rgb2dvi
set rgb2dvi_added 0
if {$rgb2dvi_exists} {
    if {[catch {
        create_bd_cell -type ip -vlnv digilentinc.com:ip:rgb2dvi:1.4 rgb2dvi_0
        set_property -dict [list \
            CONFIG.kGenerateSerialClk {false} \
            CONFIG.kClkPrimitive {MMCM} \
        ] [get_bd_cells rgb2dvi_0]
        set rgb2dvi_added 1
        puts "RGB2DVI added!"
    }]} {
        puts "RGB2DVI failed"
    }
}

# Clock Wizard
create_bd_cell -type ip -vlnv xilinx.com:ip:clk_wiz:6.0 clk_wiz_0
set_property -dict [list \
    CONFIG.PRIM_SOURCE {Global_buffer} \
    CONFIG.PRIM_IN_FREQ {100.000} \
    CONFIG.CLKOUT1_REQUESTED_OUT_FREQ {74.250} \
    CONFIG.CLKOUT2_REQUESTED_OUT_FREQ {371.250} \
    CONFIG.CLKOUT2_USED {true} \
    CONFIG.RESET_TYPE {ACTIVE_LOW} \
    CONFIG.RESET_PORT {resetn} \
] [get_bd_cells clk_wiz_0]

# Interconnects
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_gp
set_property -dict [list CONFIG.NUM_MI {4}] [get_bd_cells axi_interconnect_gp]

create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_hp
set_property -dict [list CONFIG.NUM_SI {2} CONFIG.NUM_MI {1}] [get_bd_cells axi_interconnect_hp]

# Resets
create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_ps7_0_100M
create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_ps7_0_150M

# AXI IIC
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_iic:2.1 axi_iic_0

# Subset Converter - 4 bytes (40-bit) to 3 bytes (24-bit)
create_bd_cell -type ip -vlnv xilinx.com:ip:axis_subset_converter:1.1 axis_subset_converter_0
set_property -dict [list \
    CONFIG.S_TDATA_NUM_BYTES {4} \
    CONFIG.M_TDATA_NUM_BYTES {3} \
    CONFIG.TDATA_REMAP {tdata[23:0]} \
] [get_bd_cells axis_subset_converter_0]

puts "Connecting Clocks..."

# 100MHz
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins rst_ps7_0_100M/slowest_sync_clk]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins clk_wiz_0/clk_in1]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins axi_interconnect_gp/ACLK]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins axi_interconnect_gp/S00_ACLK]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins axi_interconnect_gp/M00_ACLK]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins axi_interconnect_gp/M01_ACLK]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins axi_interconnect_gp/M02_ACLK]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins processing_system7_0/M_AXI_GP0_ACLK]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins axi_iic_0/s_axi_aclk]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins axi_vdma_0/s_axi_lite_aclk]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins v_tc_0/s_axi_aclk]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins axi_vdma_0/m_axi_s2mm_aclk]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins axi_vdma_0/m_axi_mm2s_aclk]

# 150MHz
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK1] [get_bd_pins rst_ps7_0_150M/slowest_sync_clk]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK1] [get_bd_pins mipi_csi2_rx_subsystem_0/video_aclk]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK1] [get_bd_pins mipi_csi2_rx_subsystem_0/lite_aclk]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK1] [get_bd_pins v_demosaic_0/ap_clk]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK1] [get_bd_pins v_gamma_lut_0/ap_clk]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK1] [get_bd_pins axi_vdma_0/s_axis_s2mm_aclk]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK1] [get_bd_pins axis_subset_converter_0/aclk]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK1] [get_bd_pins axi_interconnect_gp/M03_ACLK]

# 200MHz
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK2] [get_bd_pins mipi_csi2_rx_subsystem_0/dphy_clk_200M]

# 74.25MHz
connect_bd_net [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins v_tc_0/clk]
connect_bd_net [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins v_axi4s_vid_out_0/aclk]
connect_bd_net [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins v_axi4s_vid_out_0/vid_io_out_clk]
connect_bd_net [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins axi_vdma_0/m_axis_mm2s_aclk]

if {$rgb2dvi_added} {
    connect_bd_net [get_bd_pins clk_wiz_0/clk_out1] [get_bd_pins rgb2dvi_0/PixelClk]
    connect_bd_net [get_bd_pins clk_wiz_0/clk_out2] [get_bd_pins rgb2dvi_0/SerialClk]
}

# HP interconnect
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins axi_interconnect_hp/ACLK]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins axi_interconnect_hp/S00_ACLK]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins axi_interconnect_hp/S01_ACLK]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins axi_interconnect_hp/M00_ACLK]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] [get_bd_pins processing_system7_0/S_AXI_HP0_ACLK]

puts "Connecting Resets..."

connect_bd_net [get_bd_pins processing_system7_0/FCLK_RESET0_N] [get_bd_pins rst_ps7_0_100M/ext_reset_in]
connect_bd_net [get_bd_pins rst_ps7_0_100M/peripheral_aresetn] [get_bd_pins axi_interconnect_gp/ARESETN]
connect_bd_net [get_bd_pins rst_ps7_0_100M/peripheral_aresetn] [get_bd_pins axi_interconnect_gp/S00_ARESETN]
connect_bd_net [get_bd_pins rst_ps7_0_100M/peripheral_aresetn] [get_bd_pins axi_interconnect_gp/M00_ARESETN]
connect_bd_net [get_bd_pins rst_ps7_0_100M/peripheral_aresetn] [get_bd_pins axi_interconnect_gp/M01_ARESETN]
connect_bd_net [get_bd_pins rst_ps7_0_100M/peripheral_aresetn] [get_bd_pins axi_interconnect_gp/M02_ARESETN]
connect_bd_net [get_bd_pins rst_ps7_0_100M/peripheral_aresetn] [get_bd_pins axi_iic_0/s_axi_aresetn]
connect_bd_net [get_bd_pins rst_ps7_0_100M/peripheral_aresetn] [get_bd_pins axi_vdma_0/axi_resetn]
connect_bd_net [get_bd_pins rst_ps7_0_100M/peripheral_aresetn] [get_bd_pins clk_wiz_0/resetn]
connect_bd_net [get_bd_pins rst_ps7_0_100M/peripheral_aresetn] [get_bd_pins v_tc_0/s_axi_aresetn]
connect_bd_net [get_bd_pins rst_ps7_0_100M/peripheral_aresetn] [get_bd_pins axi_interconnect_hp/ARESETN]
connect_bd_net [get_bd_pins rst_ps7_0_100M/peripheral_aresetn] [get_bd_pins axi_interconnect_hp/S00_ARESETN]
connect_bd_net [get_bd_pins rst_ps7_0_100M/peripheral_aresetn] [get_bd_pins axi_interconnect_hp/S01_ARESETN]
connect_bd_net [get_bd_pins rst_ps7_0_100M/peripheral_aresetn] [get_bd_pins axi_interconnect_hp/M00_ARESETN]

connect_bd_net [get_bd_pins processing_system7_0/FCLK_RESET0_N] [get_bd_pins rst_ps7_0_150M/ext_reset_in]
connect_bd_net [get_bd_pins rst_ps7_0_150M/peripheral_aresetn] [get_bd_pins mipi_csi2_rx_subsystem_0/video_aresetn]
connect_bd_net [get_bd_pins rst_ps7_0_150M/peripheral_aresetn] [get_bd_pins mipi_csi2_rx_subsystem_0/lite_aresetn]
connect_bd_net [get_bd_pins rst_ps7_0_150M/peripheral_aresetn] [get_bd_pins v_demosaic_0/ap_rst_n]
connect_bd_net [get_bd_pins rst_ps7_0_150M/peripheral_aresetn] [get_bd_pins v_gamma_lut_0/ap_rst_n]
connect_bd_net [get_bd_pins rst_ps7_0_150M/peripheral_aresetn] [get_bd_pins axis_subset_converter_0/aresetn]
connect_bd_net [get_bd_pins rst_ps7_0_150M/peripheral_aresetn] [get_bd_pins axi_interconnect_gp/M03_ARESETN]

connect_bd_net [get_bd_pins clk_wiz_0/locked] [get_bd_pins v_tc_0/resetn]
connect_bd_net [get_bd_pins clk_wiz_0/locked] [get_bd_pins v_axi4s_vid_out_0/aresetn]
connect_bd_net [get_bd_pins clk_wiz_0/locked] [get_bd_pins v_axi4s_vid_out_0/vid_io_out_reset]

if {$rgb2dvi_added} {
    connect_bd_net [get_bd_pins clk_wiz_0/locked] [get_bd_pins rgb2dvi_0/aRst_n]
}

puts "Connecting AXI..."

connect_bd_intf_net [get_bd_intf_pins processing_system7_0/M_AXI_GP0] [get_bd_intf_pins axi_interconnect_gp/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_interconnect_gp/M00_AXI] [get_bd_intf_pins axi_vdma_0/S_AXI_LITE]
connect_bd_intf_net [get_bd_intf_pins axi_interconnect_gp/M01_AXI] [get_bd_intf_pins v_tc_0/ctrl]
connect_bd_intf_net [get_bd_intf_pins axi_interconnect_gp/M02_AXI] [get_bd_intf_pins axi_iic_0/S_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_interconnect_gp/M03_AXI] [get_bd_intf_pins mipi_csi2_rx_subsystem_0/csirxss_s_axi]

connect_bd_intf_net [get_bd_intf_pins axi_vdma_0/M_AXI_S2MM] [get_bd_intf_pins axi_interconnect_hp/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_vdma_0/M_AXI_MM2S] [get_bd_intf_pins axi_interconnect_hp/S01_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_interconnect_hp/M00_AXI] [get_bd_intf_pins processing_system7_0/S_AXI_HP0]

puts "Connecting Video Pipeline..."

connect_bd_intf_net [get_bd_intf_pins mipi_csi2_rx_subsystem_0/video_out] [get_bd_intf_pins v_demosaic_0/s_axis_video]
connect_bd_intf_net [get_bd_intf_pins v_demosaic_0/m_axis_video] [get_bd_intf_pins v_gamma_lut_0/s_axis_video]
connect_bd_intf_net [get_bd_intf_pins v_gamma_lut_0/m_axis_video] [get_bd_intf_pins axis_subset_converter_0/S_AXIS]
connect_bd_intf_net [get_bd_intf_pins axis_subset_converter_0/M_AXIS] [get_bd_intf_pins axi_vdma_0/S_AXIS_S2MM]
connect_bd_intf_net [get_bd_intf_pins axi_vdma_0/M_AXIS_MM2S] [get_bd_intf_pins v_axi4s_vid_out_0/video_in]
connect_bd_intf_net [get_bd_intf_pins v_tc_0/vtiming_out] [get_bd_intf_pins v_axi4s_vid_out_0/vtiming_in]

if {$rgb2dvi_added} {
    connect_bd_net [get_bd_pins v_axi4s_vid_out_0/vid_io_out_ce] [get_bd_pins rgb2dvi_0/vid_pVDE]
    connect_bd_net [get_bd_pins v_axi4s_vid_out_0/vid_data] [get_bd_pins rgb2dvi_0/vid_pData]
    connect_bd_net [get_bd_pins v_axi4s_vid_out_0/vid_hsync] [get_bd_pins rgb2dvi_0/vid_pHSync]
    connect_bd_net [get_bd_pins v_axi4s_vid_out_0/vid_vsync] [get_bd_pins rgb2dvi_0/vid_pVSync]
}

puts "Creating External Ports..."

create_bd_intf_port -mode Master -vlnv xilinx.com:interface:iic_rtl:1.0 IIC_0
connect_bd_intf_net [get_bd_intf_pins axi_iic_0/IIC] [get_bd_intf_ports IIC_0]

create_bd_intf_port -mode Slave -vlnv xilinx.com:interface:mipi_phy_rtl:1.0 mipi_phy_if
connect_bd_intf_net [get_bd_intf_pins mipi_csi2_rx_subsystem_0/mipi_phy_if] [get_bd_intf_ports mipi_phy_if]

if {$rgb2dvi_added} {
    create_bd_port -dir O -from 0 -to 0 hdmi_tx_clk_p
    create_bd_port -dir O -from 0 -to 0 hdmi_tx_clk_n
    create_bd_port -dir O -from 2 -to 0 hdmi_tx_p
    create_bd_port -dir O -from 2 -to 0 hdmi_tx_n
    
    connect_bd_net [get_bd_pins rgb2dvi_0/TMDS_Clk_p] [get_bd_ports hdmi_tx_clk_p]
    connect_bd_net [get_bd_pins rgb2dvi_0/TMDS_Clk_n] [get_bd_ports hdmi_tx_clk_n]
    connect_bd_net [get_bd_pins rgb2dvi_0/TMDS_Data_p] [get_bd_ports hdmi_tx_p]
    connect_bd_net [get_bd_pins rgb2dvi_0/TMDS_Data_n] [get_bd_ports hdmi_tx_n]
}

assign_bd_address
save_bd_design
validate_bd_design

regenerate_bd_layout
make_wrapper -files [get_files $project_dir/$project_name.srcs/sources_1/bd/system/system.bd] -top
add_files -norecurse $project_dir/$project_name.gen/sources_1/bd/system/hdl/system_wrapper.v

# Create XDC file with complete constraints
set xdc "$project_dir/$project_name.srcs/constrs_1/new/pins.xdc"
file mkdir $project_dir/$project_name.srcs/constrs_1/new
set fp [open $xdc w]

puts $fp "# Clock constraints"
puts $fp "create_clock -period 10.000 \[get_pins system_i/processing_system7_0/inst/PS7_i/FCLKCLK\[0\]\]"
puts $fp "create_clock -period 6.667 \[get_pins system_i/processing_system7_0/inst/PS7_i/FCLKCLK\[1\]\]"
puts $fp "create_clock -period 5.000 \[get_pins system_i/processing_system7_0/inst/PS7_i/FCLKCLK\[2\]\]"
puts $fp ""
puts $fp "# I2C for camera configuration"
puts $fp "set_property -dict {PACKAGE_PIN L16 IOSTANDARD LVCMOS33} \[get_ports IIC_0_scl_io\]"
puts $fp "set_property -dict {PACKAGE_PIN J16 IOSTANDARD LVCMOS33} \[get_ports IIC_0_sda_io\]"
puts $fp ""
puts $fp "# MIPI CSI-2 D-PHY HS lanes - Use DIFF_HSTL_I_18 for HP banks"
puts $fp "set_property PACKAGE_PIN Y18 \[get_ports mipi_phy_if_clk_hs_n\]"
puts $fp "set_property PACKAGE_PIN Y19 \[get_ports mipi_phy_if_clk_hs_p\]"
puts $fp "set_property PACKAGE_PIN W18 \[get_ports mipi_phy_if_data_hs_n\[0\]\]"
puts $fp "set_property PACKAGE_PIN W19 \[get_ports mipi_phy_if_data_hs_p\[0\]\]"
puts $fp "set_property PACKAGE_PIN V17 \[get_ports mipi_phy_if_data_hs_n\[1\]\]"
puts $fp "set_property PACKAGE_PIN V18 \[get_ports mipi_phy_if_data_hs_p\[1\]\]"
puts $fp ""
puts $fp "# Use DIFF_HSTL_I_18 instead of LVDS for HP banks"
puts $fp "set_property IOSTANDARD DIFF_HSTL_I_18 \[get_ports mipi_phy_if_clk_hs_p\]"
puts $fp "set_property IOSTANDARD DIFF_HSTL_I_18 \[get_ports mipi_phy_if_data_hs_p\[0\]\]"
puts $fp "set_property IOSTANDARD DIFF_HSTL_I_18 \[get_ports mipi_phy_if_data_hs_p\[1\]\]"
puts $fp ""
puts $fp "# Enable differential termination"
puts $fp "set_property DIFF_TERM_ADV TERM_100 \[get_ports mipi_phy_if_clk_hs_p\]"
puts $fp "set_property DIFF_TERM_ADV TERM_100 \[get_ports mipi_phy_if_data_hs_p\[0\]\]"
puts $fp "set_property DIFF_TERM_ADV TERM_100 \[get_ports mipi_phy_if_data_hs_p\[1\]\]"
puts $fp ""
puts $fp "# MIPI LP signals (single-ended, unused - assign to dummy pins)"
puts $fp "set_property -dict {PACKAGE_PIN T10 IOSTANDARD LVCMOS18} \[get_ports mipi_phy_if_clk_lp_n\]"
puts $fp "set_property -dict {PACKAGE_PIN T11 IOSTANDARD LVCMOS18} \[get_ports mipi_phy_if_clk_lp_p\]"
puts $fp "set_property -dict {PACKAGE_PIN U12 IOSTANDARD LVCMOS18} \[get_ports mipi_phy_if_data_lp_n\[0\]\]"
puts $fp "set_property -dict {PACKAGE_PIN V12 IOSTANDARD LVCMOS18} \[get_ports mipi_phy_if_data_lp_p\[0\]\]"
puts $fp "set_property -dict {PACKAGE_PIN V13 IOSTANDARD LVCMOS18} \[get_ports mipi_phy_if_data_lp_n\[1\]\]"
puts $fp "set_property -dict {PACKAGE_PIN W13 IOSTANDARD LVCMOS18} \[get_ports mipi_phy_if_data_lp_p\[1\]\]"
puts $fp ""
puts $fp "# Bitstream generation settings"
puts $fp "set_property BITSTREAM.GENERAL.COMPRESS TRUE \[current_design\]"
puts $fp "set_property BITSTREAM.CONFIG.CONFIGRATE 50 \[current_design\]"
puts $fp "set_property CONFIG_MODE SPIx4 \[current_design\]"

if {$rgb2dvi_added} {
    puts $fp ""
    puts $fp "# HDMI Output"
    puts $fp "set_property PACKAGE_PIN H16 \[get_ports {hdmi_tx_clk_n}\]"
    puts $fp "set_property PACKAGE_PIN H17 \[get_ports {hdmi_tx_clk_p}\]"
    puts $fp "set_property PACKAGE_PIN D19 \[get_ports {hdmi_tx_n\[0\]}\]"
    puts $fp "set_property PACKAGE_PIN D20 \[get_ports {hdmi_tx_p\[0\]}\]"
    puts $fp "set_property PACKAGE_PIN C20 \[get_ports {hdmi_tx_n\[1\]}\]"
    puts $fp "set_property PACKAGE_PIN B20 \[get_ports {hdmi_tx_p\[1\]}\]"
    puts $fp "set_property PACKAGE_PIN B19 \[get_ports {hdmi_tx_n\[2\]}\]"
    puts $fp "set_property PACKAGE_PIN A20 \[get_ports {hdmi_tx_p\[2\]}\]"
    puts $fp "set_property IOSTANDARD TMDS_33 \[get_ports hdmi_tx*\]"
}

close $fp
add_files -fileset constrs_1 $xdc

puts "\n========================================"
if {$rgb2dvi_added} {
    puts "SUCCESS - Complete design with HDMI!"
} else {
    puts "INCOMPLETE - No HDMI (need Digilent IP)"
    puts "git clone https://github.com/Digilent/vivado-library.git ./digilent_ip/vivado-library"
}
puts "========================================"
