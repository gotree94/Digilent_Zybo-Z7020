################################################################
# Zybo Z7-20 PetaLinux Project Creation Script
# Project: zybo_7020_peta
# Block Design: design_top
# Description: PS-only configuration with XSA export
################################################################

# Set project variables
set project_name "zybo_7020_peta"
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

# Explicitly disable all PL interfaces for PS-only operation
puts "INFO: Configuring for PS-only operation (no PL/FPGA fabric required)..."
set_property -dict [list \
    CONFIG.PCW_USE_M_AXI_GP0 {0} \
    CONFIG.PCW_USE_M_AXI_GP1 {0} \
    CONFIG.PCW_USE_S_AXI_GP0 {0} \
    CONFIG.PCW_USE_S_AXI_GP1 {0} \
    CONFIG.PCW_USE_S_AXI_HP0 {0} \
    CONFIG.PCW_USE_S_AXI_HP1 {0} \
    CONFIG.PCW_USE_S_AXI_HP2 {0} \
    CONFIG.PCW_USE_S_AXI_HP3 {0} \
    CONFIG.PCW_USE_S_AXI_ACP {0} \
    CONFIG.PCW_FPGA0_PERIPHERAL_FREQMHZ {100} \
] $zynq_ps

# Regenerate layout
regenerate_bd_layout

# Validate design
puts "INFO: Validating block design..."
validate_bd_design

# Save block design
save_bd_design
puts "INFO: Block design created successfully"

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
# Export XSA (Xilinx Support Archive) for PetaLinux
################################################################
puts ""
puts "================================================================"
puts "Exporting Hardware (XSA) for PetaLinux"
puts "================================================================"

# Create export directory
set export_dir "${project_dir}/hardware_export"
file mkdir $export_dir

# Open implemented design
puts "INFO: Opening implemented design..."
open_run impl_1

# Export XSA file with bitstream
puts "INFO: Exporting XSA file (Xilinx Support Archive)..."
set xsa_file "${export_dir}/${bd_name}_wrapper.xsa"
write_hw_platform -fixed -include_bit -force -file $xsa_file

# Verify XSA file creation
if {[file exists $xsa_file]} {
    set xsa_size [expr [file size $xsa_file] / 1024]
    puts ""
    puts "================================================================"
    puts "✓ XSA FILE CREATED SUCCESSFULLY!"
    puts "================================================================"
    puts "Location: ${xsa_file}"
    puts "Size:     ${xsa_size} KB"
    puts "================================================================"
} else {
    error "ERROR: Failed to create XSA file"
}

# Copy bitstream to export directory
puts "INFO: Copying bitstream file..."
set bit_src "${project_dir}/${project_name}.runs/impl_1/${bd_name}_wrapper.bit"
set bit_dst "${export_dir}/${bd_name}_wrapper.bit"
if {[file exists $bit_src]} {
    file copy -force $bit_src $bit_dst
    puts "INFO: ✓ Bitstream copied to: ${bit_dst}"
}

# Create PetaLinux usage instructions
set readme_file "${export_dir}/PETALINUX_README.txt"
set readme_content "================================================================
Zybo Z7-20 Hardware Export for PetaLinux
================================================================
Generated: [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]

XSA File: ${bd_name}_wrapper.xsa

================================================================
PetaLinux Setup Steps:
================================================================

1. Create PetaLinux project:
   petalinux-create --type project --template zynq --name zybo_petalinux
   cd zybo_petalinux

2. Import hardware description (XSA):
   petalinux-config --get-hw-description=${export_dir}

3. Configure kernel (optional):
   petalinux-config -c kernel

4. Build PetaLinux:
   petalinux-build

5. Package boot files:
   petalinux-package --boot --fsbl images/linux/zynq_fsbl.elf \\
                     --fpga images/linux/system.bit \\
                     --u-boot --force

6. Copy to SD card (FAT32 partition):
   - BOOT.BIN
   - image.ub
   - boot.scr

================================================================
Hardware Configuration:
================================================================
- Device: Zynq-7000 XC7Z020CLG400-1
- Board: Digilent Zybo Z7-20
- Configuration: PS Only (No PL fabric used)

Enabled Peripherals:
  ✓ UART1 (MIO 48-49) - Serial Console
  ✓ SD0 (MIO 40-45, 47) - Boot from SD Card
  ✓ Ethernet0 (MIO 16-27) - Network Interface
  ✓ USB0 (MIO 28-39) - USB Host/Device
  ✓ QSPI (MIO 1-6, 8) - Flash Memory
  ✓ DDR3 - 1GB Memory

================================================================
"

set fp [open $readme_file w]
puts $fp $readme_content
close $fp
puts "INFO: ✓ README created: ${readme_file}"

################################################################
# Final Summary
################################################################
puts ""
puts "================================================================"
puts "🎉 PROJECT COMPLETED SUCCESSFULLY! 🎉"
puts "================================================================"
puts ""
puts "Project:  ${project_name}"
puts "Location: ${project_dir}"
puts ""
puts "Files for PetaLinux:"
puts "  XSA File:  ${xsa_file}"
puts "  Bitstream: ${bit_dst}"
puts "  README:    ${readme_file}"
puts ""
puts "Next Step:"
puts "  → Use XSA file with PetaLinux:"
puts "    petalinux-config --get-hw-description=${export_dir}"
puts ""
puts "================================================================"
