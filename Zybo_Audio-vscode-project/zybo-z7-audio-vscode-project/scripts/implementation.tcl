#!/usr/bin/tclsh
# implementation.tcl - Vivado Implementation Script for Zybo Z7-20

puts "======================================"
puts "Starting Implementation for Zybo Z7-20"
puts "======================================"

# Open synthesized checkpoint
open_checkpoint ./reports/post_synth.dcp

# Set implementation strategy
set_property strategy Performance_ExplorePostRoutePhysOpt [get_runs impl_1]

# Run optimization
puts "Running optimization..."
opt_design

# Run placement
puts "Running placement..."
place_design
report_utilization -file ./reports/post_place_utilization.rpt
report_timing_summary -file ./reports/post_place_timing.rpt

# Physical optimization (optional)
phys_opt_design

# Run routing
puts "Running routing..."
route_design
report_route_status -file ./reports/post_route_status.rpt
report_timing_summary -file ./reports/post_route_timing.rpt
report_power -file ./reports/post_route_power.rpt
report_drc -file ./reports/post_route_drc.rpt

# Save checkpoint
write_checkpoint -force ./reports/post_route.dcp

# Check timing
set slack [get_property SLACK [get_timing_paths]]
puts "Post-route slack: $slack ns"

if {$slack < 0} {
    puts "WARNING: Timing constraints not met!"
} else {
    puts "SUCCESS: Timing constraints met"
}

puts "======================================"
puts "Implementation Complete!"
puts "======================================"
