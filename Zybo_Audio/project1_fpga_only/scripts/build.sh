#!/bin/bash
# build.sh
# Automated build script for Zybo Z7-20 Audio project

set -e  # Exit on error

echo "================================================================"
echo "Zybo Z7-20 Audio Project Build Script"
echo "================================================================"

# Check if Vivado is in PATH
if ! command -v vivado &> /dev/null; then
    echo "ERROR: Vivado not found in PATH"
    echo "Please source Vivado settings:"
    echo "  source /tools/Xilinx/Vivado/2021.1/settings64.sh"
    exit 1
fi

# Get script directory
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "Project root: $PROJECT_ROOT"
echo "================================================================"

# Step 1: Create project
echo ""
echo "Step 1: Creating Vivado project..."
echo "================================================================"
cd "$SCRIPT_DIR"
vivado -mode batch -source create_project.tcl

if [ $? -ne 0 ]; then
    echo "ERROR: Project creation failed"
    exit 1
fi

echo "Project created successfully"

# Step 2: Build (synthesis, implementation, bitstream)
echo ""
echo "Step 2: Building project..."
echo "================================================================"
vivado -mode batch -source build.tcl ../vivado_project/audio_loopback.xpr

if [ $? -ne 0 ]; then
    echo "ERROR: Build failed"
    exit 1
fi

echo "Build completed successfully"

# Step 3: Copy bitstream to output directory
echo ""
echo "Step 3: Copying bitstream..."
echo "================================================================"
OUTPUT_DIR="$PROJECT_ROOT/output"
mkdir -p "$OUTPUT_DIR"

cp ../vivado_project/audio_loopback.runs/impl_1/audio_top.bit "$OUTPUT_DIR/"

echo "Bitstream copied to: $OUTPUT_DIR/audio_top.bit"

# Summary
echo ""
echo "================================================================"
echo "Build Summary"
echo "================================================================"
echo "✓ Project created"
echo "✓ Synthesis completed"
echo "✓ Implementation completed"
echo "✓ Bitstream generated"
echo ""
echo "Output files:"
echo "  Bitstream:  $OUTPUT_DIR/audio_top.bit"
echo "  Reports:    $PROJECT_ROOT/vivado_project/*.rpt"
echo ""
echo "To program the FPGA:"
echo "  cd $SCRIPT_DIR"
echo "  vivado -mode batch -source program.tcl"
echo ""
echo "Or use GUI:"
echo "  vivado ../vivado_project/audio_loopback.xpr"
echo "================================================================"
