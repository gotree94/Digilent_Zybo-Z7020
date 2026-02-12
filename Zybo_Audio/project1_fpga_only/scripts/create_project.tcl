# create_project.tcl
# Vivado project creation script for Zybo Z7-20 Audio

# Set the reference directory for source file relative paths
set origin_dir [file dirname [info script]]
set project_dir [file join $origin_dir ".." "vivado_project"]

# Set project name
set proj_name "audio_loopback"

# Create project
create_project $proj_name $project_dir -part xc7z020clg400-1 -force
set_property board_part digilentinc.com:zybo-z7-20:part0:1.1 [current_project]

# Set the directory path for the HDL sources
set hdl_dir [file normalize [file join $origin_dir ".." "hdl"]]
set constr_dir [file normalize [file join $origin_dir ".." "constraints"]]

# Add HDL source files
add_files -norecurse [glob $hdl_dir/*.v]

# Add constraints
add_files -fileset constrs_1 -norecurse [glob $constr_dir/*.xdc]

# Set top module
set_property top audio_top [current_fileset]

# Update compile order
update_compile_order -fileset sources_1

puts "================================================================"
puts "INFO: Project created successfully!"
puts "================================================================"
puts "Project Name: $proj_name"
puts "Project Location: $project_dir"
puts "HDL Files: [glob $hdl_dir/*.v]"
puts "Constraints: [glob $constr_dir/*.xdc]"
puts "================================================================"
puts ""
puts "Next Steps:"
puts "  1. Run synthesis:         launch_runs synth_1 -jobs 4"
puts "  2. Run implementation:    launch_runs impl_1 -jobs 4"
puts "  3. Generate bitstream:    launch_runs impl_1 -to_step write_bitstream -jobs 4"
puts "  4. Open GUI:              start_gui"
puts "================================================================"
