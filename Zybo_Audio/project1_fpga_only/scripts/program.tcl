# program.tcl
# Program the Zybo Z7-20 FPGA with the generated bitstream

# Set bitstream path
set bitstream_path "./vivado_project/audio_loopback.runs/impl_1/audio_top.bit"

# Check if bitstream exists
if {![file exists $bitstream_path]} {
    puts "ERROR: Bitstream not found at $bitstream_path"
    puts "Please run build.tcl first to generate the bitstream"
    exit 1
}

puts "================================================================"
puts "Programming Zybo Z7-20 FPGA"
puts "================================================================"
puts "Bitstream: $bitstream_path"
puts "================================================================"

# Open hardware manager
open_hw_manager

# Connect to hardware server
puts "Connecting to hardware server..."
connect_hw_server -allow_non_jtag

# Open hardware target
puts "Opening hardware target..."
open_hw_target

# Get current hardware device
set hw_device [current_hw_device]
puts "Hardware device: $hw_device"

# Set bitstream file
puts "Setting bitstream file..."
set_property PROGRAM.FILE $bitstream_path $hw_device

# Program device
puts "Programming device..."
program_hw_devices $hw_device

# Refresh device
refresh_hw_device $hw_device

puts "================================================================"
puts "Programming completed successfully!"
puts "================================================================"
puts ""
puts "Testing Instructions:"
puts "  1. Connect audio source to Line In (J7 - Blue)"
puts "  2. Connect headphones to Headphone Out (J5 - Black)"
puts "  3. Check LED status:"
puts "     - LED[0]: I2C configuration complete (should be ON)"
puts "     - LED[1]: Audio data valid (blinks with audio)"
puts "     - LED[2]: LR clock activity (fast blink)"
puts "     - LED[3]: Audio level indicator"
puts "================================================================"

# Close hardware manager
close_hw_manager
