################################################################
# Zybo Z7-20 PetaLinux Project Creation Script (Final Version)
# Project: zybo_7020_peta
# Block Design: design_top
# Description: Complete PS-only configuration with full hardware export
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
    CONFIG.PCW_FPGA1_PERIPHERAL_FREQMHZ {100} \
    CONFIG.PCW_FPGA2_PERIPHERAL_FREQMHZ {100} \
    CONFIG.PCW_FPGA3_PERIPHERAL_FREQMHZ {100} \
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
# Export Hardware - Multiple Formats
################################################################
puts ""
puts "================================================================"
puts "Exporting Hardware for PetaLinux"
puts "================================================================"

# Create export directory
set export_dir "${project_dir}/hardware_export"
file mkdir $export_dir

# Open implemented design
open_run impl_1

# 1. Export XSA (Xilinx Support Archive) - Main file for PetaLinux
puts "INFO: Exporting XSA file (Xilinx Support Archive)..."
set xsa_file "${export_dir}/${bd_name}_wrapper.xsa"
write_hw_platform -fixed -include_bit -force -file $xsa_file

if {[file exists $xsa_file]} {
    puts "INFO: ✓ XSA file created successfully"
    puts "      Location: ${xsa_file}"
    puts "      Size: [expr [file size $xsa_file] / 1024] KB"
} else {
    error "ERROR: Failed to create XSA file"
}

# 2. Copy Bitstream
puts "INFO: Copying bitstream file..."
set bit_src "${project_dir}/${project_name}.runs/impl_1/${bd_name}_wrapper.bit"
set bit_dst "${export_dir}/${bd_name}_wrapper.bit"
if {[file exists $bit_src]} {
    file copy -force $bit_src $bit_dst
    puts "INFO: ✓ Bitstream copied"
    puts "      Location: ${bit_dst}"
} else {
    puts "WARNING: Bitstream file not found"
}

# 3. Export Block Design as PDF (if possible)
puts "INFO: Exporting block design schematic..."
set pdf_file "${export_dir}/${bd_name}_schematic.pdf"
if {[catch {write_bd_tcl -force ${export_dir}/${bd_name}.tcl} err]} {
    puts "WARNING: Could not export BD TCL: $err"
}

# 4. Copy constraint files (if any exist)
set constr_files [get_files -of_objects [get_filesets constrs_1] *.xdc]
if {[llength $constr_files] > 0} {
    puts "INFO: Copying constraint files..."
    foreach constr $constr_files {
        file copy -force $constr ${export_dir}/
    }
}

# 5. Export Device Tree files (if needed)
# This is typically done in PetaLinux, but we can prepare the directory
set dt_dir "${export_dir}/device_tree"
file mkdir $dt_dir

# 6. Create README for PetaLinux usage
set readme_file "${export_dir}/README.txt"
set readme_content "================================================================
Zybo Z7-20 Hardware Export for PetaLinux
================================================================
Generated: [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]
Project: ${project_name}
Block Design: ${bd_name}

================================================================
Files Included:
================================================================
1. ${bd_name}_wrapper.xsa
   - Main hardware description file
   - Use this with petalinux-config --get-hw-description

2. ${bd_name}_wrapper.bit
   - FPGA bitstream file
   - Already included in XSA file

3. ${bd_name}.tcl (if generated)
   - Block design TCL script for recreation

================================================================
Hardware Configuration:
================================================================
- Device: Zynq-7000 XC7Z020CLG400-1
- Board: Digilent Zybo Z7-20
- Configuration: PS Only (No PL required)

Enabled Peripherals:
  ✓ UART1 (MIO 48-49) - Serial Console
  ✓ SD0 (MIO 40-45, 47) - Boot from SD Card
  ✓ Ethernet0 (MIO 16-27) - Network Interface
  ✓ USB0 (MIO 28-39) - USB Host/Device
  ✓ QSPI (MIO 1-6, 8) - Flash Memory
  ✓ DDR3 - 1GB Memory

================================================================
PetaLinux Workflow:
================================================================
1. Copy XSA file to Linux environment:
   scp ${bd_name}_wrapper.xsa user@linux-host:/path/to/petalinux/

2. Create PetaLinux project:
   cd /path/to/petalinux
   petalinux-create --type project --template zynq --name zybo_petalinux
   cd zybo_petalinux

3. Configure hardware:
   petalinux-config --get-hw-description=/path/to/xsa/directory/

4. Build PetaLinux:
   petalinux-build

5. Package boot files:
   petalinux-package --boot --fsbl images/linux/zynq_fsbl.elf \\
                     --fpga images/linux/${bd_name}_wrapper.bit \\
                     --u-boot --force

================================================================
Notes:
================================================================
- No PL (FPGA) logic is used in this design
- All peripherals use MIO (PS-side connections)
- No constraint files (XDC) are required
- Bitstream is minimal (PS configuration only)

For more information, refer to:
- UG1144: PetaLinux Tools Reference Guide
- Zybo Z7-20 Reference Manual
================================================================
"

set fp [open $readme_file w]
puts $fp $readme_content
close $fp
puts "INFO: ✓ README.txt created"

################################################################
# Generate Reports
################################################################
puts ""
puts "================================================================"
puts "Generating Design Reports"
puts "================================================================"

set report_dir "${project_dir}/reports"
file mkdir $report_dir

# Utilization report
puts "INFO: Generating utilization report..."
report_utilization -file ${report_dir}/utilization.txt
report_utilization -hierarchical -file ${report_dir}/utilization_hierarchical.txt

# Timing report
puts "INFO: Generating timing report..."
report_timing_summary -file ${report_dir}/timing_summary.txt
report_timing -file ${report_dir}/timing_detailed.txt -max_paths 10

# Power report
puts "INFO: Generating power report..."
report_power -file ${report_dir}/power.txt

# Clock report
puts "INFO: Generating clock report..."
report_clocks -file ${report_dir}/clocks.txt

# DRC report
puts "INFO: Generating DRC report..."
report_drc -file ${report_dir}/drc.txt

puts "INFO: ✓ All reports generated in ${report_dir}"

################################################################
# Create Summary Document
################################################################
set summary_file "${project_dir}/PROJECT_SUMMARY.txt"
set summary_content "================================================================
PROJECT SUMMARY: ${project_name}
================================================================
Generated: [clock format [clock seconds] -format "%Y-%m-%d %H:%M:%S"]

================================================================
PROJECT DETAILS
================================================================
Name:           ${project_name}
Location:       ${project_dir}
Block Design:   ${bd_name}
Top Module:     ${bd_name}_wrapper
Part:           ${part_name}
Board:          Digilent Zybo Z7-20

================================================================
GENERATED FILES
================================================================
Hardware Export (for PetaLinux):
  📁 ${export_dir}/
     ├─ ${bd_name}_wrapper.xsa      ⭐ Main file for PetaLinux
     ├─ ${bd_name}_wrapper.bit      💾 Bitstream
     ├─ README.txt                   📝 Usage instructions
     └─ device_tree/                 📂 Device tree directory

Vivado Project Files:
  📁 ${project_dir}/
     ├─ ${project_name}.xpr          🔧 Vivado project
     ├─ ${project_name}.srcs/        📂 Source files
     ├─ ${project_name}.runs/        📂 Build outputs
     └─ reports/                     📊 Design reports

Bitstream:
  ${project_dir}/${project_name}.runs/impl_1/${bd_name}_wrapper.bit

================================================================
HARDWARE CONFIGURATION
================================================================
Configuration Type: PS Only (Processing System)
PL Logic Used:      None (minimal bitstream)

Enabled PS Peripherals:
  ✓ Dual-core ARM Cortex-A9 @ 667 MHz
  ✓ DDR3 Memory: 1GB
  ✓ UART1: 115200 baud (Console)
  ✓ SD Card: Boot device
  ✓ Ethernet: 10/100/1000 Mbps
  ✓ USB 2.0: Host/Device
  ✓ QSPI Flash: 16MB

================================================================
BUILD STATUS
================================================================
Synthesis:       ✓ Completed
Implementation:  ✓ Completed
Bitstream:       ✓ Generated
Hardware Export: ✓ Exported

================================================================
NEXT STEPS: PetaLinux Setup
================================================================
1. Transfer XSA to Linux environment:
   File: ${export_dir}/${bd_name}_wrapper.xsa
   
2. Create PetaLinux project:
   petalinux-create -t project -s <zynq-bsp>
   
3. Import hardware:
   petalinux-config --get-hw-description=<xsa-directory>
   
4. Build system:
   petalinux-build
   
5. Package boot image:
   petalinux-package --boot --fsbl <fsbl> --fpga <bit> --u-boot

================================================================
RESOURCES & DOCUMENTATION
================================================================
- Vivado Project: ${project_name}.xpr
- Hardware Export: ${export_dir}/README.txt
- Design Reports: ${report_dir}/
- Zybo Z7-20 Manual: https://digilent.com/reference/programmable-logic/zybo-z7/
- PetaLinux Guide: UG1144

================================================================
"

set fp [open $summary_file w]
puts $fp $summary_content
close $fp

################################################################
# Final Summary Output
################################################################
puts ""
puts "================================================================"
puts "🎉 PROJECT CREATION COMPLETED SUCCESSFULLY! 🎉"
puts "================================================================"
puts ""
puts "Project Details:"
puts "  Name:     ${project_name}"
puts "  Location: ${project_dir}"
puts "  Design:   ${bd_name}"
puts ""
puts "Generated Files:"
puts "  📦 Hardware Export: ${export_dir}/${bd_name}_wrapper.xsa"
puts "  💾 Bitstream:       ${bit_dst}"
puts "  📊 Reports:         ${report_dir}/"
puts "  📝 Summary:         ${summary_file}"
puts ""
puts "Configuration:"
puts "  ✓ PS Only (No PL required)"
puts "  ✓ UART, SD, Ethernet, USB, QSPI enabled"
puts "  ✓ 1GB DDR3 configured"
puts "  ✓ Ready for PetaLinux"
puts ""
puts "Next Step:"
puts "  → Copy ${export_dir}/${bd_name}_wrapper.xsa to Linux"
puts "  → Run: petalinux-config --get-hw-description=<path>"
puts ""
puts "================================================================"
puts "For detailed instructions, see:"
puts "  ${export_dir}/README.txt"
puts "  ${summary_file}"
puts "================================================================"