################################################################
# Zybo Z7-20 PetaLinux Project with GPIO (JB Pmod) - FIXED
# Project: zybo_7020_gpio
# Block Design: design_top
# Description: PS with AXI GPIO connected to JB Pmod connector
################################################################

# Set project variables
set project_name "zybo_7020_gpio"
set project_dir "C:/Users/Administrator/${project_name}"
set bd_name "design_top"
set part_name "xc7z020clg400-1"
set board_part "digilentinc.com:zybo-z7-20:part0:1.1"

# Create project directory
file mkdir $project_dir

# Create project
puts "INFO: Creating project ${project_name}..."
create_project $project_name $project_dir -part $part_name -force

# Set board part if available
set_property board_part $board_part [current_project]

# Set project properties
set_property target_language Verilog [current_project]
set_property simulator_language Mixed [current_project]

puts "INFO: Project created successfully"

################################################################
# Create Block Design
################################################################
puts "INFO: Creating block design ${bd_name}..."
create_bd_design $bd_name

# Add ZYNQ7 Processing System
puts "INFO: Adding ZYNQ7 Processing System IP..."
set zynq_ps [create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 processing_system7_0]

# Apply board preset first
puts "INFO: Applying board preset..."
apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 \
    -config {make_external "FIXED_IO, DDR" apply_board_preset "1" Master "Disable" Slave "Disable"} \
    $zynq_ps

# Configure PS for AXI GPIO
puts "INFO: Configuring PS with AXI Master interface..."
set_property -dict [list \
    CONFIG.PCW_USE_M_AXI_GP0 {1} \
    CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {100} \
    CONFIG.PCW_USE_FABRIC_INTERRUPT {1} \
    CONFIG.PCW_IRQ_F2P_INTR {1} \
] $zynq_ps

################################################################
# Add AXI GPIO IP for JB Pmod
################################################################
puts "INFO: Adding AXI GPIO IP..."
set axi_gpio [create_bd_cell -type ip -vlnv xilinx.com:ip:axi_gpio:2.0 axi_gpio_0]

# Configure AXI GPIO
# JB Pmod has 8 pins (JB1-JB8)
set_property -dict [list \
    CONFIG.C_GPIO_WIDTH {8} \
    CONFIG.C_ALL_INPUTS {0} \
    CONFIG.C_ALL_OUTPUTS {0} \
    CONFIG.C_IS_DUAL {0} \
    CONFIG.C_INTERRUPT_PRESENT {1} \
] $axi_gpio

################################################################
# Create External Ports (FIXED METHOD)
################################################################
puts "INFO: Creating external GPIO interface..."

# Method 1: Use the GPIO interface directly (RECOMMENDED)
# This creates a proper tri-state GPIO interface
create_bd_intf_port -mode Master -vlnv xilinx.com:interface:gpio_rtl:1.0 jb_gpio
connect_bd_intf_net [get_bd_intf_pins axi_gpio_0/GPIO] [get_bd_intf_ports jb_gpio]

# Method 2 Alternative: Create separate ports (commented out)
# If you need separate control, uncomment this instead:
# puts "INFO: Creating separate I/O/T ports..."
# create_bd_port -dir O -from 7 -to 0 jb_gpio_o
# create_bd_port -dir I -from 7 -to 0 jb_gpio_i  
# create_bd_port -dir O -from 7 -to 0 jb_gpio_t
# connect_bd_net [get_bd_pins axi_gpio_0/gpio_io_o] [get_bd_ports jb_gpio_o]
# connect_bd_net [get_bd_pins axi_gpio_0/gpio_io_i] [get_bd_ports jb_gpio_i]
# connect_bd_net [get_bd_pins axi_gpio_0/gpio_io_t] [get_bd_ports jb_gpio_t]

################################################################
# Connect AXI GPIO to PS
################################################################
puts "INFO: Connecting AXI interfaces..."

# Apply automation for AXI connection
apply_bd_automation -rule xilinx.com:bd_rule:axi4 \
    -config {Master "/processing_system7_0/M_AXI_GP0" intc_ip "New AXI Interconnect" Clk_xbar "Auto" Clk_master "Auto" Clk_slave "Auto"} \
    [get_bd_intf_pins axi_gpio_0/S_AXI]

################################################################
# Connect Interrupt
################################################################
puts "INFO: Connecting interrupt..."

# Create interrupt concatenation block
set concat [create_bd_cell -type ip -vlnv xilinx.com:ip:xlconcat:2.1 xlconcat_0]
set_property -dict [list CONFIG.NUM_PORTS {1}] $concat

# Connect GPIO interrupt to concat
connect_bd_net [get_bd_pins axi_gpio_0/ip2intc_irpt] [get_bd_pins xlconcat_0/In0]

# Connect concat output to PS interrupt
connect_bd_net [get_bd_pins xlconcat_0/dout] [get_bd_pins processing_system7_0/IRQ_F2P]

# Regenerate layout
regenerate_bd_layout

# Validate design
puts "INFO: Validating block design..."
validate_bd_design

# Assign addresses
assign_bd_address

# Save block design
save_bd_design
puts "INFO: Block design created successfully"

# Print address map
puts "\n========== ADDRESS MAP =========="
set gpio_addr [get_property OFFSET [get_bd_addr_segs {processing_system7_0/Data/SEG_axi_gpio_0_Reg}]]
puts "AXI GPIO Base Address: $gpio_addr"
puts "=================================="

################################################################
# Create Constraints File for JB Pmod
################################################################
puts "INFO: Creating constraints file for JB Pmod..."

set constraints_file "${project_dir}/${project_name}.srcs/constrs_1/new/jb_pmod.xdc"
file mkdir [file dirname $constraints_file]

# Using GPIO interface (jb_gpio_tri_io)
set xdc_content "################################################################
# Zybo Z7-20 JB Pmod Connector Constraints
################################################################

# JB Pmod Connector (8 pins)
# Using tri-state GPIO interface

# JB1 (Pin 1)
set_property PACKAGE_PIN V8 \[get_ports {jb_gpio_tri_io\[0\]}\]
set_property IOSTANDARD LVCMOS33 \[get_ports {jb_gpio_tri_io\[0\]}\]

# JB2 (Pin 2)
set_property PACKAGE_PIN W8 \[get_ports {jb_gpio_tri_io\[1\]}\]
set_property IOSTANDARD LVCMOS33 \[get_ports {jb_gpio_tri_io\[1\]}\]

# JB3 (Pin 3)
set_property PACKAGE_PIN U7 \[get_ports {jb_gpio_tri_io\[2\]}\]
set_property IOSTANDARD LVCMOS33 \[get_ports {jb_gpio_tri_io\[2\]}\]

# JB4 (Pin 4)
set_property PACKAGE_PIN V7 \[get_ports {jb_gpio_tri_io\[3\]}\]
set_property IOSTANDARD LVCMOS33 \[get_ports {jb_gpio_tri_io\[3\]}\]

# JB7 (Pin 7)
set_property PACKAGE_PIN Y7 \[get_ports {jb_gpio_tri_io\[4\]}\]
set_property IOSTANDARD LVCMOS33 \[get_ports {jb_gpio_tri_io\[4\]}\]

# JB8 (Pin 8)
set_property PACKAGE_PIN Y6 \[get_ports {jb_gpio_tri_io\[5\]}\]
set_property IOSTANDARD LVCMOS33 \[get_ports {jb_gpio_tri_io\[5\]}\]

# JB9 (Pin 9)
set_property PACKAGE_PIN V6 \[get_ports {jb_gpio_tri_io\[6\]}\]
set_property IOSTANDARD LVCMOS33 \[get_ports {jb_gpio_tri_io\[6\]}\]

# JB10 (Pin 10)
set_property PACKAGE_PIN W6 \[get_ports {jb_gpio_tri_io\[7\]}\]
set_property IOSTANDARD LVCMOS33 \[get_ports {jb_gpio_tri_io\[7\]}\]
"

# Alternative constraints if using separate ports (Method 2):
# Replace jb_gpio_tri_io with jb_gpio_o, jb_gpio_i, jb_gpio_t

set fp [open $constraints_file w]
puts $fp $xdc_content
close $fp

add_files -fileset constrs_1 -norecurse $constraints_file

puts "INFO: Constraints file created successfully"

################################################################
# Create HDL Wrapper
################################################################
puts "INFO: Creating HDL wrapper..."
set bd_file [get_files ${bd_name}.bd]
make_wrapper -files $bd_file -top

set wrapper_file [make_wrapper -files $bd_file -top -import]
set_property top ${bd_name}_wrapper [current_fileset]
update_compile_order -fileset sources_1

puts "INFO: HDL wrapper created successfully"

################################################################
# Generate Bitstream
################################################################
puts "INFO: Starting synthesis..."
reset_run synth_1
launch_runs synth_1 -jobs 4
wait_on_run synth_1

if {[get_property PROGRESS [get_runs synth_1]] != "100%"} {
    error "ERROR: Synthesis failed"
}
puts "INFO: Synthesis completed successfully"

puts "INFO: Starting implementation..."
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1

if {[get_property PROGRESS [get_runs impl_1]] != "100%"} {
    error "ERROR: Implementation failed"
}
puts "INFO: Implementation completed successfully"

################################################################
# Export XSA for PetaLinux
################################################################
puts ""
puts "================================================================"
puts "Exporting Hardware (XSA) for PetaLinux"
puts "================================================================"

set export_dir "${project_dir}/hardware_export"
file mkdir $export_dir

open_run impl_1

set xsa_file "${export_dir}/${bd_name}_wrapper.xsa"
write_hw_platform -fixed -include_bit -force -file $xsa_file

if {[file exists $xsa_file]} {
    set xsa_size [expr [file size $xsa_file] / 1024]
    puts ""
    puts "================================================================"
    puts "✓ XSA FILE CREATED SUCCESSFULLY!"
    puts "================================================================"
    puts "Location: ${xsa_file}"
    puts "Size:     ${xsa_size} KB"
    puts "GPIO Address: $gpio_addr"
    puts "================================================================"
}

set bit_src "${project_dir}/${project_name}.runs/impl_1/${bd_name}_wrapper.bit"
set bit_dst "${export_dir}/${bd_name}_wrapper.bit"
if {[file exists $bit_src]} {
    file copy -force $bit_src $bit_dst
    puts "INFO: ✓ Bitstream copied"
}

################################################################
# Create Device Tree Information File
################################################################
set dt_info_file "${export_dir}/device_tree_info.txt"
set dt_content "================================================================
Device Tree Information for JB Pmod GPIO
================================================================

AXI GPIO Configuration:
  - Base Address: $gpio_addr
  - GPIO Width: 8 bits
  - Interrupt: Yes
  - Pmod Connector: JB

Device Tree Node (add to system-user.dtsi):
----------------------------------------------------------------
&axi_gpio_0 {
    compatible = \"xlnx,axi-gpio-2.0\", \"xlnx,xps-gpio-1.00.a\";
    gpio-controller;
    #gpio-cells = <2>;
    xlnx,gpio-width = <8>;
    xlnx,is-dual = <0>;
    status = \"okay\";
};

Pin Mapping (JB Pmod):
  jb_gpio_tri_io\[0\] = JB1 (V8)
  jb_gpio_tri_io\[1\] = JB2 (W8)
  jb_gpio_tri_io\[2\] = JB3 (U7)
  jb_gpio_tri_io\[3\] = JB4 (V7)
  jb_gpio_tri_io\[4\] = JB7 (Y7)
  jb_gpio_tri_io\[5\] = JB8 (Y6)
  jb_gpio_tri_io\[6\] = JB9 (V6)
  jb_gpio_tri_io\[7\] = JB10 (W6)

Notes:
  - Using tri-state GPIO interface (gpio_tri_io)
  - Supports both input and output
  - Direction controlled via AXI GPIO registers

================================================================
"

set fp [open $dt_info_file w]
puts $fp $dt_content
close $fp

################################################################
# Final Summary
################################################################
puts ""
puts "================================================================"
puts "🎉 PROJECT WITH GPIO COMPLETED SUCCESSFULLY! 🎉"
puts "================================================================"
puts ""
puts "Project:  ${project_name}"
puts "Location: ${project_dir}"
puts ""
puts "Hardware Configuration:"
puts "  ✓ PS (Processing System)"
puts "  ✓ AXI GPIO (8-bit) at address: $gpio_addr"
puts "  ✓ Connected to JB Pmod (tri-state interface)"
puts "  ✓ Interrupt enabled"
puts ""
puts "Files for PetaLinux:"
puts "  XSA File:  ${xsa_file}"
puts "  Bitstream: ${bit_dst}"
puts "  DT Info:   ${dt_info_file}"
puts ""
puts "Next Steps:"
puts "  1. Import XSA to PetaLinux"
puts "  2. Add device tree configuration (see ${dt_info_file})"
puts "  3. Build and test GPIO application"
puts ""
puts "================================================================"
