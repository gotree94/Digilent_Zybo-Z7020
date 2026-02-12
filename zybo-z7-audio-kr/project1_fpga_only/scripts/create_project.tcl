# create_project.tcl
# Vivado project creation script for Zybo Z7-20 Audio

# Set project name and directory
set proj_name "audio_loopback"
set proj_dir "./vivado_project"

# Create project
create_project $proj_name $proj_dir -part xc7z020clg400-1 -force
set_property board_part digilentinc.com:zybo-z7-20:part0:1.1 [current_project]

# Add HDL source files
add_files -norecurse {
    ../hdl/audio_top.v
    ../hdl/i2c_config.v
    ../hdl/i2s_rx.v
    ../hdl/i2s_tx.v
    ../hdl/clk_divider.v
}

# Add constraints
add_files -fileset constrs_1 -norecurse ../constraints/zybo_z7_audio.xdc

# Set top module
set_property top audio_top [current_fileset]

# Update compile order
update_compile_order -fileset sources_1

puts "INFO: Project created successfully!"
puts "INFO: Run 'launch_runs synth_1' to synthesize"
puts "INFO: Run 'launch_runs impl_1' to implement"
puts "INFO: Run 'launch_runs impl_1 -to_step write_bitstream' to generate bitstream"
