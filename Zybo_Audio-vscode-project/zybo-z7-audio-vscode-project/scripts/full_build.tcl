#!/usr/bin/tclsh
# full_build.tcl - Complete Build Flow for Zybo Z7-20

puts "=========================================="
puts "Zybo Z7-20 Complete Build Flow"
puts "=========================================="

set start_time [clock seconds]

# Project configuration
set project_name "zybo_z7_audio"
set project_dir "./build"
set part_name "xc7z020clg400-1"

# Clean previous build
puts "\n[1/5] Cleaning previous build..."
file delete -force $project_dir
file mkdir $project_dir
file mkdir ./reports

# Create project
puts "\n[2/5] Creating Vivado project..."
create_project -force $project_name $project_dir -part $part_name

# Set project properties
set_property target_language Verilog [current_project]
set_property simulator_language Mixed [current_project]

# Add source files
puts "\n[3/5] Adding source files..."
add_files [glob -nocomplain ./rtl/*.v]
add_files [glob -nocomplain ./rtl/*.sv]
add_files -fileset constrs_1 [glob -nocomplain ./constraints/*.xdc]

# Set top module
set_property top top [current_fileset]
update_compile_order -fileset sources_1

# Run synthesis
puts "\n[4/5] Running synthesis..."
launch_runs synth_1 -jobs 4
wait_on_run synth_1

if {[get_property PROGRESS [get_runs synth_1]] != "100%"} {
    puts "ERROR: Synthesis failed!"
    exit 1
}

open_run synth_1
report_utilization -file ./reports/post_synth_utilization.rpt
report_timing_summary -file ./reports/post_synth_timing.rpt
write_checkpoint -force ./reports/post_synth.dcp

# Run implementation
puts "\n[5/5] Running implementation..."
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1

if {[get_property PROGRESS [get_runs impl_1]] != "100%"} {
    puts "ERROR: Implementation failed!"
    exit 1
}

open_run impl_1
report_utilization -file ./reports/post_impl_utilization.rpt
report_timing_summary -file ./reports/post_impl_timing.rpt
report_power -file ./reports/post_impl_power.rpt
report_drc -file ./reports/post_impl_drc.rpt

# Check timing
set wns [get_property STATS.WNS [get_runs impl_1]]
set tns [get_property STATS.TNS [get_runs impl_1]]
set whs [get_property STATS.WHS [get_runs impl_1]]
set ths [get_property STATS.THS [get_runs impl_1]]

puts "\n=========================================="
puts "Build Summary:"
puts "=========================================="
puts "Worst Negative Slack (WNS): $wns ns"
puts "Total Negative Slack (TNS): $tns ns"
puts "Worst Hold Slack (WHS): $whs ns"
puts "Total Hold Slack (THS): $ths ns"

if {$wns < 0} {
    puts "WARNING: Setup timing constraints not met!"
}
if {$whs < 0} {
    puts "WARNING: Hold timing constraints not met!"
}

set end_time [clock seconds]
set elapsed_time [expr {$end_time - $start_time}]
set elapsed_min [expr {$elapsed_time / 60}]
set elapsed_sec [expr {$elapsed_time % 60}]

puts "\nTotal build time: ${elapsed_min}m ${elapsed_sec}s"
puts "=========================================="
puts "Build Complete!"
puts "Bitstream: ./build/${project_name}.runs/impl_1/top.bit"
puts "=========================================="

# Close project
close_project
