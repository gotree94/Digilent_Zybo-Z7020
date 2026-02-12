#!/usr/bin/tclsh
# bitstream.tcl - Vivado Bitstream Generation Script for Zybo Z7-20

puts "======================================"
puts "Generating Bitstream for Zybo Z7-20"
puts "======================================"

# Open routed checkpoint
open_checkpoint ./reports/post_route.dcp

# Generate bitstream
puts "Writing bitstream..."
write_bitstream -force ./build/design.bit

# Generate debug probes (if any ILA cores exist)
if {[llength [get_debug_cores]] > 0} {
    write_debug_probes -force ./build/design.ltx
    puts "Debug probes file generated: design.ltx"
}

# Generate other programming files
write_cfgmem -format bin -interface SMAPx32 -disablebitswap -loadbit "up 0x0 ./build/design.bit" -force ./build/design.bin

puts "======================================"
puts "Bitstream Generation Complete!"
puts "Output files:"
puts "  - ./build/design.bit (Bitstream)"
puts "  - ./build/design.bin (Binary format)"
puts "======================================"
