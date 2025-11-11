#!/bin/bash

################################################################################
# ALU AXI Quick Test Script
# Engineer: 나무
# Date: 2025-11-12
#
# This script provides quick testing functions for the ALU hardware
################################################################################

# Color definitions
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# ALU base address
ALU_BASE=0x43C00000
REG_A=$((ALU_BASE + 0x00))
REG_B=$((ALU_BASE + 0x04))
REG_OPCODE=$((ALU_BASE + 0x08))
REG_CTRL=$((ALU_BASE + 0x0C))
REG_RESULT=$((ALU_BASE + 0x10))
REG_STATUS=$((ALU_BASE + 0x14))

# Function to print colored messages
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Function to check if running as root
check_root() {
    if [ "$EUID" -ne 0 ]; then
        print_error "This script must be run as root (use sudo)"
        exit 1
    fi
}

# Function to check if ALU hardware is accessible
check_hardware() {
    if ! command -v devmem &> /dev/null; then
        print_error "devmem command not found"
        return 1
    fi
    
    # Try to read from ALU base address
    if ! devmem $ALU_BASE 32 &> /dev/null; then
        print_error "Cannot access ALU hardware at $ALU_BASE"
        print_info "Make sure FPGA is programmed with the correct bitstream"
        return 1
    fi
    
    print_success "ALU hardware is accessible"
    return 0
}

# Function to write to ALU register
alu_write() {
    local addr=$1
    local value=$2
    devmem $addr 32 $value 2>/dev/null
}

# Function to read from ALU register
alu_read() {
    local addr=$1
    devmem $addr 32 2>/dev/null
}

# Function to perform ALU operation
alu_compute() {
    local a=$1
    local b=$2
    local opcode=$3
    
    # Write operands
    alu_write $REG_A $a
    alu_write $REG_B $b
    
    # Write opcode
    alu_write $REG_OPCODE $opcode
    
    # Enable
    alu_write $REG_CTRL 1
    
    # Small delay
    sleep 0.01
    
    # Read result
    local result=$(alu_read $REG_RESULT)
    
    # Disable
    alu_write $REG_CTRL 0
    
    echo $result
}

# Function to dump all registers
dump_registers() {
    echo "================================"
    echo "    ALU Register Dump"
    echo "================================"
    printf "OPERAND_A (0x%08X): " $REG_A
    alu_read $REG_A
    printf "OPERAND_B (0x%08X): " $REG_B
    alu_read $REG_B
    printf "CONTROL   (0x%08X): " $REG_CTRL
    alu_read $REG_CTRL
    printf "RESULT    (0x%08X): " $REG_RESULT
    alu_read $REG_RESULT
    echo "================================"
}

# Function to test a specific operation
test_operation() {
    local a=$1
    local b=$2
    local opcode=$3
    local op_name=$4
    local expected=$5
    
    local result=$(alu_compute $a $b $opcode)
    result=$((result & 0xFFFF))  # Mask to 16 bits
    
    printf "  %s: %3d %-2s %3d = %5d (0x%04X) " "$op_name" $a "$6" $b $result $result
    
    if [ -n "$expected" ]; then
        if [ $result -eq $expected ]; then
            echo -e "${GREEN}✓${NC}"
        else
            echo -e "${RED}✗ (expected $expected)${NC}"
        fi
    else
        echo ""
    fi
}

# Function to run comprehensive tests
run_tests() {
    local a=${1:-25}
    local b=${2:-5}
    
    echo ""
    echo "========================================"
    echo "  Testing ALU with A=$a, B=$b"
    echo "========================================"
    echo ""
    
    # Calculate expected results
    local exp_add=$((a + b))
    local exp_sub=$((a - b))
    local exp_mul=$((a * b))
    local exp_div=$((a / b))
    local exp_mod=$((a % b))
    local exp_eq=$((a == b ? 1 : 0))
    local exp_gt=$((a > b ? 1 : 0))
    local exp_lt=$((a < b ? 1 : 0))
    
    test_operation $a $b 0 "ADD" $exp_add "+"
    test_operation $a $b 1 "SUB" $exp_sub "-"
    test_operation $a $b 2 "MUL" $exp_mul "*"
    test_operation $a $b 3 "DIV" $exp_div "/"
    test_operation $a $b 4 "MOD" $exp_mod "%"
    test_operation $a $b 5 "EQ " $exp_eq "=="
    test_operation $a $b 6 "GT " $exp_gt ">"
    test_operation $a $b 7 "LT " $exp_lt "<"
    
    echo ""
}

# Function to run quick smoke test
smoke_test() {
    print_info "Running smoke test..."
    
    # Test simple addition
    local result=$(alu_compute 10 5 0)
    result=$((result & 0xFFFF))
    
    if [ $result -eq 15 ]; then
        print_success "Smoke test passed (10 + 5 = 15)"
        return 0
    else
        print_error "Smoke test failed (10 + 5 = $result, expected 15)"
        return 1
    fi
}

# Function to run benchmark
benchmark() {
    local iterations=${1:-1000}
    
    print_info "Running benchmark with $iterations iterations..."
    
    local start=$(date +%s.%N)
    
    for ((i=0; i<iterations; i++)); do
        alu_compute 100 50 0 > /dev/null
    done
    
    local end=$(date +%s.%N)
    local duration=$(echo "$end - $start" | bc)
    local ops_per_sec=$(echo "$iterations / $duration" | bc)
    
    echo ""
    echo "Benchmark Results:"
    echo "  Iterations: $iterations"
    echo "  Total time: $duration seconds"
    echo "  Operations/sec: $ops_per_sec"
    echo ""
}

# Function to show help
show_help() {
    echo "ALU AXI Quick Test Script"
    echo ""
    echo "Usage: $0 [command] [options]"
    echo ""
    echo "Commands:"
    echo "  test [a] [b]     - Run comprehensive test (default: a=25, b=5)"
    echo "  smoke            - Run quick smoke test"
    echo "  compute a b op   - Compute single operation"
    echo "                     op: 0=ADD 1=SUB 2=MUL 3=DIV 4=MOD 5=EQ 6=GT 7=LT"
    echo "  dump             - Dump all register values"
    echo "  benchmark [n]    - Run performance benchmark (default: n=1000)"
    echo "  check            - Check if hardware is accessible"
    echo "  help             - Show this help"
    echo ""
    echo "Examples:"
    echo "  sudo $0 test          # Run test with default values (25, 5)"
    echo "  sudo $0 test 100 25   # Run test with custom values"
    echo "  sudo $0 compute 10 5 0  # Compute 10 + 5"
    echo "  sudo $0 smoke         # Quick smoke test"
    echo "  sudo $0 benchmark 5000  # Benchmark with 5000 iterations"
    echo ""
}

################################################################################
# Main script
################################################################################

# Parse command line arguments
case "$1" in
    test)
        check_root
        if ! check_hardware; then
            exit 1
        fi
        run_tests ${2:-25} ${3:-5}
        ;;
    
    smoke)
        check_root
        if ! check_hardware; then
            exit 1
        fi
        smoke_test
        ;;
    
    compute)
        if [ $# -ne 4 ]; then
            print_error "compute requires 3 arguments: a b opcode"
            exit 1
        fi
        check_root
        if ! check_hardware; then
            exit 1
        fi
        result=$(alu_compute $2 $3 $4)
        result=$((result & 0xFFFF))
        echo "Result: $result (0x$(printf %04X $result))"
        ;;
    
    dump)
        check_root
        if ! check_hardware; then
            exit 1
        fi
        dump_registers
        ;;
    
    benchmark)
        check_root
        if ! check_hardware; then
            exit 1
        fi
        benchmark ${2:-1000}
        ;;
    
    check)
        check_root
        check_hardware
        ;;
    
    help|--help|-h)
        show_help
        ;;
    
    *)
        print_error "Unknown command: $1"
        echo ""
        show_help
        exit 1
        ;;
esac
