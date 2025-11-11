# Vivado Project Creation Script for Zybo Z7-20 ALU with AXI
# Engineer: 나무
# Date: 2025-11-12

# Set project name and directory
set project_name "zybo_alu_axi"
set project_dir "./vivado_project"

# Create project
create_project ${project_name} ${project_dir} -part xc7z020clg400-1 -force

# Set project properties
set_property board_part digilentinc.com:zybo-z7-20:part0:1.2 [current_project]
set_property target_language Verilog [current_project]

# Add source files
add_files -norecurse {
    ../hdl/alu.v
    ../hdl/alu_axi_lite_v1_0.v
}

# Update compile order
update_compile_order -fileset sources_1

# Create block design
create_bd_design "system"

# Add Processing System
create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0

# Configure PS7
apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 \
    -config {make_external "FIXED_IO, DDR" \
             Master "Disable" \
             Slave "Disable" } \
    [get_bd_cells processing_system7_0]

# Enable AXI GP0 interface
set_property -dict [list \
    CONFIG.PCW_USE_M_AXI_GP0 {1} \
    CONFIG.PCW_M_AXI_GP0_ENABLE_STATIC_REMAP {0} \
] [get_bd_cells processing_system7_0]

# Create ALU AXI peripheral
create_bd_cell -type module -reference alu_axi_lite_v1_0 alu_axi_0

# Add AXI Interconnect
create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_interconnect_0
set_property -dict [list \
    CONFIG.NUM_MI {1} \
] [get_bd_cells axi_interconnect_0]

# Connect clock and reset
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] \
               [get_bd_pins processing_system7_0/M_AXI_GP0_ACLK]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] \
               [get_bd_pins axi_interconnect_0/ACLK]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] \
               [get_bd_pins axi_interconnect_0/S00_ACLK]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] \
               [get_bd_pins axi_interconnect_0/M00_ACLK]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_CLK0] \
               [get_bd_pins alu_axi_0/s_axi_aclk]

connect_bd_net [get_bd_pins processing_system7_0/FCLK_RESET0_N] \
               [get_bd_pins axi_interconnect_0/ARESETN]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_RESET0_N] \
               [get_bd_pins axi_interconnect_0/S00_ARESETN]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_RESET0_N] \
               [get_bd_pins axi_interconnect_0/M00_ARESETN]
connect_bd_net [get_bd_pins processing_system7_0/FCLK_RESET0_N] \
               [get_bd_pins alu_axi_0/s_axi_aresetn]

# Connect AXI interfaces
connect_bd_intf_net [get_bd_intf_pins processing_system7_0/M_AXI_GP0] \
                    [get_bd_intf_pins axi_interconnect_0/S00_AXI]
connect_bd_intf_net [get_bd_intf_pins axi_interconnect_0/M00_AXI] \
                    [get_bd_intf_pins alu_axi_0/S_AXI]

# Assign address
assign_bd_address [get_bd_addr_segs {alu_axi_0/S_AXI/reg0 }]
set_property offset 0x43C00000 [get_bd_addr_segs {processing_system7_0/Data/SEG_alu_axi_0_reg0}]
set_property range 4K [get_bd_addr_segs {processing_system7_0/Data/SEG_alu_axi_0_reg0}]

# Validate design
regenerate_bd_layout
validate_bd_design
save_bd_design

# Create HDL wrapper
make_wrapper -files [get_files ${project_dir}/${project_name}.srcs/sources_1/bd/system/system.bd] -top
add_files -norecurse ${project_dir}/${project_name}.gen/sources_1/bd/system/hdl/system_wrapper.v

# Set top module
set_property top system_wrapper [current_fileset]
update_compile_order -fileset sources_1

puts "Block design created successfully!"
puts "ALU AXI base address: 0x43C00000"
puts ""
puts "Next steps:"
puts "1. Generate Bitstream"
puts "2. Export Hardware (including bitstream)"
puts "3. Launch SDK/Vitis for software development"
