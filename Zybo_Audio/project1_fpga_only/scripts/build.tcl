# build.tcl
# Complete build flow for Zybo Z7-20 Audio project

# Run synthesis
puts "================================================================"
puts "Starting Synthesis..."
puts "================================================================"
launch_runs synth_1 -jobs 4
wait_on_run synth_1

# Check synthesis status
if {[get_property PROGRESS [get_runs synth_1]] != "100%"} {
    puts "ERROR: Synthesis failed!"
    exit 1
}

puts "================================================================"
puts "Synthesis completed successfully"
puts "================================================================"

# Run implementation
puts "================================================================"
puts "Starting Implementation..."
puts "================================================================"
launch_runs impl_1 -jobs 4
wait_on_run impl_1

# Check implementation status
if {[get_property PROGRESS [get_runs impl_1]] != "100%"} {
    puts "ERROR: Implementation failed!"
    exit 1
}

puts "================================================================"
puts "Implementation completed successfully"
puts "================================================================"

# Generate bitstream
puts "================================================================"
puts "Generating Bitstream..."
puts "================================================================"
launch_runs impl_1 -to_step write_bitstream -jobs 4
wait_on_run impl_1

# Check bitstream generation
if {![file exists ./vivado_project/audio_loopback.runs/impl_1/audio_top.bit]} {
    puts "ERROR: Bitstream generation failed!"
    exit 1
}

puts "================================================================"
puts "Build completed successfully!"
puts "================================================================"
puts "Bitstream location: ./vivado_project/audio_loopback.runs/impl_1/audio_top.bit"
puts "================================================================"

# Generate reports
puts "Generating reports..."
open_run impl_1
report_timing_summary -file ./vivado_project/timing_summary.rpt
report_utilization -file ./vivado_project/utilization.rpt
report_power -file ./vivado_project/power.rpt

puts "================================================================"
puts "Reports generated:"
puts "  - timing_summary.rpt"
puts "  - utilization.rpt"
puts "  - power.rpt"
puts "================================================================"
