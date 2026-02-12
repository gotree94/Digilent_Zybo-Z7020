#!/usr/bin/tclsh
# synthesis.tcl - Vivado Synthesis Script for Zybo Z7-20

puts "======================================"
puts "Starting Synthesis for Zybo Z7-20"
puts "======================================"

# Set project variables
set project_name "zybo_z7_audio"
set project_dir "./build"
set part_name "xc7z020clg400-1"

# Create project directory if it doesn't exist
file mkdir $project_dir
file mkdir ./reports

# Create project
create_project -force $project_name $project_dir -part $part_name

# Set project properties
set_property target_language Verilog [current_project]
set_property simulator_language Mixed [current_project]

# Add RTL source files
puts "Adding RTL source files..."
add_files [glob -nocomplain ./rtl/*.v]
add_files [glob -nocomplain ./rtl/*.sv]

# Add constraint files
puts "Adding constraint files..."
add_files -fileset constrs_1 [glob -nocomplain ./constraints/*.xdc]

# Set top module
set_property top top [current_fileset]

# Update compile order
update_compile_order -fileset sources_1

# Run synthesis
puts "Running synthesis..."
launch_runs synth_1 -jobs 4
wait_on_run synth_1

# Open synthesized design
open_run synth_1

# Generate reports
puts "Generating reports..."
report_utilization -file ./reports/post_synth_utilization.rpt
report_timing_summary -file ./reports/post_synth_timing.rpt
report_power -file ./reports/post_synth_power.rpt

# Check timing
set slack [get_property SLACK [get_timing_paths]]
puts "Post-synthesis slack: $slack ns"

if {$slack < 0} {
    puts "WARNING: Timing constraints not met!"
} else {
    puts "SUCCESS: Timing constraints met"
}

# Save checkpoint
write_checkpoint -force ./reports/post_synth.dcp

puts "======================================"
puts "Synthesis Complete!"
puts "======================================"

# Close project (optional)
# close_project
