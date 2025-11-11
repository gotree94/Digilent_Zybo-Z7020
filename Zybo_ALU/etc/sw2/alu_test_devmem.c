/*
 * ALU AXI Test Program using Direct Memory Access
 * Engineer: 나무
 * Date: 2025-11-12
 *
 * This program tests the ALU hardware accelerator through /dev/mem
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <sys/mman.h>
#include <stdint.h>

#define ALU_BASE_ADDR   0x43C00000
#define ALU_MAP_SIZE    0x1000

/* Register offsets */
#define REG_OPERAND_A   0x00
#define REG_OPERAND_B   0x04
#define REG_OPCODE      0x08
#define REG_CONTROL     0x0C
#define REG_RESULT      0x10
#define REG_STATUS      0x14

/* ALU Operation codes */
typedef enum {
    ALU_ADD = 0,  // Addition
    ALU_SUB = 1,  // Subtraction
    ALU_MUL = 2,  // Multiplication
    ALU_DIV = 3,  // Division
    ALU_MOD = 4,  // Modulo
    ALU_EQ  = 5,  // Equal
    ALU_GT  = 6,  // Greater than
    ALU_LT  = 7   // Less than
} alu_opcode_t;

const char* opcode_names[] = {
    "ADD (+)",
    "SUB (-)",
    "MUL (*)",
    "DIV (/)",
    "MOD (%)",
    "EQ  (==)",
    "GT  (>)",
    "LT  (<)"
};

/* Global pointer to mapped memory */
volatile uint32_t *alu_regs = NULL;

/* Write to ALU register */
void alu_write_reg(uint32_t offset, uint32_t value)
{
    alu_regs[offset / 4] = value;
}

/* Read from ALU register */
uint32_t alu_read_reg(uint32_t offset)
{
    return alu_regs[offset / 4];
}

/* Initialize ALU hardware access */
int alu_init(void)
{
    int fd;
    void *mapped_base;
    
    // Open /dev/mem
    fd = open("/dev/mem", O_RDWR | O_SYNC);
    if (fd < 0) {
        perror("Failed to open /dev/mem");
        printf("Note: This program requires root privileges\n");
        return -1;
    }
    
    // Map ALU registers
    mapped_base = mmap(NULL, ALU_MAP_SIZE, PROT_READ | PROT_WRITE,
                      MAP_SHARED, fd, ALU_BASE_ADDR);
    close(fd);
    
    if (mapped_base == MAP_FAILED) {
        perror("Failed to mmap");
        return -1;
    }
    
    alu_regs = (volatile uint32_t *)mapped_base;
    
    // Initialize ALU to known state
    alu_write_reg(REG_OPERAND_A, 0);
    alu_write_reg(REG_OPERAND_B, 0);
    alu_write_reg(REG_OPCODE, 0);
    alu_write_reg(REG_CONTROL, 0);
    
    printf("ALU hardware initialized at 0x%08X\n", ALU_BASE_ADDR);
    return 0;
}

/* Cleanup ALU hardware access */
void alu_cleanup(void)
{
    if (alu_regs != NULL) {
        munmap((void *)alu_regs, ALU_MAP_SIZE);
        alu_regs = NULL;
    }
}

/* Perform ALU operation */
uint16_t alu_compute(uint8_t a, uint8_t b, alu_opcode_t opcode)
{
    uint32_t result;
    
    // Write operands
    alu_write_reg(REG_OPERAND_A, a);
    alu_write_reg(REG_OPERAND_B, b);
    
    // Set opcode
    alu_write_reg(REG_OPCODE, opcode);
    
    // Enable ALU
    alu_write_reg(REG_CONTROL, 1);
    
    // Small delay for computation
    usleep(10);
    
    // Read result
    result = alu_read_reg(REG_RESULT);
    
    // Disable ALU
    alu_write_reg(REG_CONTROL, 0);
    
    return (uint16_t)(result & 0xFFFF);
}

/* Read current register values */
void print_registers(void)
{
    uint32_t op_a, op_b, opcode, ctrl, res, status;
    
    op_a = alu_read_reg(REG_OPERAND_A);
    op_b = alu_read_reg(REG_OPERAND_B);
    opcode = alu_read_reg(REG_OPCODE);
    ctrl = alu_read_reg(REG_CONTROL);
    res = alu_read_reg(REG_RESULT);
    status = alu_read_reg(REG_STATUS);
    
    printf("\nRegister Dump:\n");
    printf("  OPERAND_A (0x00): 0x%08X (%u)\n", op_a, op_a & 0xFF);
    printf("  OPERAND_B (0x04): 0x%08X (%u)\n", op_b, op_b & 0xFF);
    printf("  OPCODE    (0x08): 0x%08X (%u)\n", opcode, opcode & 0x7);
    printf("  CONTROL   (0x0C): 0x%08X (enable=%u)\n", ctrl, ctrl & 0x1);
    printf("  RESULT    (0x10): 0x%08X (%u)\n", res, res & 0xFFFF);
    printf("  STATUS    (0x14): 0x%08X (ready=%u)\n\n", status, status & 0x1);
}

/* Test all operations */
void test_all_operations(uint8_t a, uint8_t b)
{
    uint16_t result;
    int i;
    
    printf("\n");
    printf("============================================================\n");
    printf("Testing ALU with A=%u (0x%02X), B=%u (0x%02X)\n", a, a, b, b);
    printf("============================================================\n\n");
    
    for (i = 0; i < 8; i++) {
        result = alu_compute(a, b, i);
        
        if (i < 5) {
            // Arithmetic operations
            printf("  %s: %3u %-2s %3u = %5u (0x%04X)\n", 
                   opcode_names[i], a, 
                   (i==0) ? "+" : (i==1) ? "-" : (i==2) ? "*" : (i==3) ? "/" : "%",
                   b, result, result);
        } else {
            // Comparison operations
            printf("  %s: %3u %-2s %3u = %5u (%s)\n", 
                   opcode_names[i], a,
                   (i==5) ? "==" : (i==6) ? ">" : "<",
                   b, result, result ? "TRUE" : "FALSE");
        }
    }
    printf("\n");
}

/* Benchmark ALU performance */
void benchmark_alu(void)
{
    int i;
    uint16_t result;
    struct timespec start, end;
    double elapsed;
    const int iterations = 100000;
    
    printf("\n");
    printf("============================================================\n");
    printf("ALU Performance Benchmark\n");
    printf("============================================================\n\n");
    
    // Benchmark addition
    clock_gettime(CLOCK_MONOTONIC, &start);
    for (i = 0; i < iterations; i++) {
        result = alu_compute(100, 50, ALU_ADD);
    }
    clock_gettime(CLOCK_MONOTONIC, &end);
    
    elapsed = (end.tv_sec - start.tv_sec) + 
              (end.tv_nsec - start.tv_nsec) / 1e9;
    
    printf("Addition operations:\n");
    printf("  Iterations: %d\n", iterations);
    printf("  Total time: %.3f seconds\n", elapsed);
    printf("  Ops/sec: %.0f\n", iterations / elapsed);
    printf("  Time/op: %.2f µs\n\n", (elapsed / iterations) * 1e6);
}

/* Interactive mode */
void interactive_mode(void)
{
    char input[100];
    unsigned int a, b, op;
    uint16_t result;
    
    printf("\n");
    printf("============================================================\n");
    printf("ALU Interactive Mode\n");
    printf("============================================================\n");
    printf("Operations:\n");
    printf("  0: ADD (+)   1: SUB (-)   2: MUL (*)   3: DIV (/)\n");
    printf("  4: MOD (%%)   5: EQ  (==)  6: GT  (>)   7: LT  (<)\n");
    printf("  r: Read registers   b: Benchmark   q: Quit\n");
    printf("\n");
    
    while (1) {
        printf("Command: ");
        if (fgets(input, sizeof(input), stdin) == NULL)
            break;
        
        if (input[0] == 'q' || input[0] == 'Q')
            break;
        
        if (input[0] == 'r' || input[0] == 'R') {
            print_registers();
            continue;
        }
        
        if (input[0] == 'b' || input[0] == 'B') {
            benchmark_alu();
            continue;
        }
        
        op = atoi(input);
        if (op > 7) {
            printf("Invalid operation!\n");
            continue;
        }
        
        printf("Enter operand A (0-255): ");
        if (fgets(input, sizeof(input), stdin) == NULL)
            break;
        a = atoi(input);
        if (a > 255) {
            printf("Invalid operand! Must be 0-255\n");
            continue;
        }
        
        printf("Enter operand B (0-255): ");
        if (fgets(input, sizeof(input), stdin) == NULL)
            break;
        b = atoi(input);
        if (b > 255) {
            printf("Invalid operand! Must be 0-255\n");
            continue;
        }
        
        result = alu_compute(a, b, op);
        printf("\n>>> Result: %u %s %u = %u (0x%04X)\n\n", 
               a, opcode_names[op], b, result, result);
    }
}

/* Print usage */
void print_usage(const char *prog_name)
{
    printf("Usage: %s [options]\n", prog_name);
    printf("Options:\n");
    printf("  -t           Run all test cases\n");
    printf("  -i           Interactive mode\n");
    printf("  -b           Run performance benchmark\n");
    printf("  -r           Read and display registers\n");
    printf("  -c a b op    Compute: a op b\n");
    printf("               op: 0=ADD 1=SUB 2=MUL 3=DIV 4=MOD 5=EQ 6=GT 7=LT\n");
    printf("  -h           Show this help\n");
    printf("\nExamples:\n");
    printf("  sudo %s -t         # Run all tests\n", prog_name);
    printf("  sudo %s -i         # Interactive mode\n", prog_name);
    printf("  sudo %s -c 10 5 0  # Compute 10 + 5\n", prog_name);
    printf("  sudo %s -b         # Run benchmark\n", prog_name);
    printf("\nNote: This program requires root privileges (sudo)\n");
}

int main(int argc, char *argv[])
{
    unsigned int a, b, op;
    uint16_t result;
    
    printf("\n");
    printf("************************************************************\n");
    printf("  ALU AXI Hardware Accelerator Test Program\n");
    printf("  Direct Memory Access Version\n");
    printf("  Zybo Z7-20 Platform\n");
    printf("  Engineer: 나무\n");
    printf("************************************************************\n\n");
    
    // Initialize hardware
    if (alu_init() < 0) {
        return 1;
    }
    
    if (argc < 2) {
        print_usage(argv[0]);
        alu_cleanup();
        return 1;
    }
    
    // Parse command line arguments
    if (strcmp(argv[1], "-t") == 0) {
        // Test mode
        printf("Running comprehensive ALU tests...\n");
        
        test_all_operations(10, 5);
        test_all_operations(255, 1);
        test_all_operations(100, 25);
        test_all_operations(50, 7);
        test_all_operations(15, 0);  // Division by zero test
        test_all_operations(42, 42); // Equal values
        test_all_operations(200, 100);
        
        printf("All tests completed!\n\n");
        
    } else if (strcmp(argv[1], "-i") == 0) {
        // Interactive mode
        interactive_mode();
        
    } else if (strcmp(argv[1], "-b") == 0) {
        // Benchmark mode
        benchmark_alu();
        
    } else if (strcmp(argv[1], "-r") == 0) {
        // Register dump
        print_registers();
        
    } else if (strcmp(argv[1], "-c") == 0) {
        // Compute mode
        if (argc != 5) {
            printf("Error: -c requires 3 arguments (a b op)\n");
            print_usage(argv[0]);
            alu_cleanup();
            return 1;
        }
        
        a = atoi(argv[2]);
        b = atoi(argv[3]);
        op = atoi(argv[4]);
        
        if (a > 255 || b > 255 || op > 7) {
            printf("Error: Invalid arguments (a,b: 0-255, op: 0-7)\n");
            alu_cleanup();
            return 1;
        }
        
        result = alu_compute(a, b, op);
        printf("\nOperation: %s\n", opcode_names[op]);
        printf("Result: %u %s %u = %u (0x%04X)\n\n", 
               a, opcode_names[op], b, result, result);
        
    } else if (strcmp(argv[1], "-h") == 0) {
        print_usage(argv[0]);
        
    } else {
        printf("Unknown option: %s\n", argv[1]);
        print_usage(argv[0]);
        alu_cleanup();
        return 1;
    }
    
    alu_cleanup();
    return 0;
}
