/*
 * ALU AXI Test Program using Sysfs Interface
 * Engineer: 나무
 * Date: 2025-11-12
 *
 * This program tests the ALU hardware accelerator through sysfs
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <fcntl.h>
#include <unistd.h>
#include <errno.h>

#define SYSFS_ALU_PATH "/sys/devices/platform/amba/43c00000.alu"
#define SYSFS_OPERAND_A SYSFS_ALU_PATH "/operand_a"
#define SYSFS_OPERAND_B SYSFS_ALU_PATH "/operand_b"
#define SYSFS_OPCODE    SYSFS_ALU_PATH "/opcode"
#define SYSFS_ENABLE    SYSFS_ALU_PATH "/enable"
#define SYSFS_RESULT    SYSFS_ALU_PATH "/result"

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

/* Write value to sysfs file */
int sysfs_write(const char *path, unsigned int value)
{
    int fd;
    char buf[16];
    int len;
    
    fd = open(path, O_WRONLY);
    if (fd < 0) {
        perror("Failed to open sysfs file for writing");
        return -1;
    }
    
    len = snprintf(buf, sizeof(buf), "%u", value);
    if (write(fd, buf, len) != len) {
        perror("Failed to write to sysfs");
        close(fd);
        return -1;
    }
    
    close(fd);
    return 0;
}

/* Read value from sysfs file */
int sysfs_read(const char *path, unsigned int *value)
{
    int fd;
    char buf[16];
    int len;
    
    fd = open(path, O_RDONLY);
    if (fd < 0) {
        perror("Failed to open sysfs file for reading");
        return -1;
    }
    
    len = read(fd, buf, sizeof(buf) - 1);
    if (len < 0) {
        perror("Failed to read from sysfs");
        close(fd);
        return -1;
    }
    buf[len] = '\0';
    
    *value = strtoul(buf, NULL, 10);
    close(fd);
    return 0;
}

/* Perform ALU operation */
int alu_compute(unsigned char a, unsigned char b, alu_opcode_t opcode, unsigned int *result)
{
    // Set operands
    if (sysfs_write(SYSFS_OPERAND_A, a) < 0)
        return -1;
    if (sysfs_write(SYSFS_OPERAND_B, b) < 0)
        return -1;
    
    // Set opcode
    if (sysfs_write(SYSFS_OPCODE, opcode) < 0)
        return -1;
    
    // Enable ALU
    if (sysfs_write(SYSFS_ENABLE, 1) < 0)
        return -1;
    
    // Small delay for computation
    usleep(1000);
    
    // Read result
    if (sysfs_read(SYSFS_RESULT, result) < 0)
        return -1;
    
    // Disable ALU
    sysfs_write(SYSFS_ENABLE, 0);
    
    return 0;
}

/* Test all operations */
void test_all_operations(unsigned char a, unsigned char b)
{
    unsigned int result;
    int i;
    
    printf("\n");
    printf("=" * 60);
    printf("\n");
    printf("Testing ALU with A=%u, B=%u\n", a, b);
    printf("=" * 60);
    printf("\n\n");
    
    for (i = 0; i < 8; i++) {
        if (alu_compute(a, b, i, &result) == 0) {
            printf("  %s: %u %s %u = %u\n", 
                   opcode_names[i], a, 
                   (i <= 4) ? "op" : "cmp",
                   b, result);
        } else {
            printf("  %s: ERROR\n", opcode_names[i]);
        }
    }
    printf("\n");
}

/* Interactive mode */
void interactive_mode(void)
{
    char input[100];
    unsigned int a, b, op, result;
    
    printf("\n");
    printf("=" * 60);
    printf("\n");
    printf("ALU Interactive Mode\n");
    printf("=" * 60);
    printf("\n");
    printf("Operations:\n");
    printf("  0: ADD (+)   1: SUB (-)   2: MUL (*)   3: DIV (/)\n");
    printf("  4: MOD (%%)   5: EQ  (==)  6: GT  (>)   7: LT  (<)\n");
    printf("  q: Quit\n");
    printf("\n");
    
    while (1) {
        printf("Enter operation (0-7) or 'q' to quit: ");
        if (fgets(input, sizeof(input), stdin) == NULL)
            break;
        
        if (input[0] == 'q' || input[0] == 'Q')
            break;
        
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
        
        if (alu_compute(a, b, op, &result) == 0) {
            printf("\nResult: %u %s %u = %u\n\n", a, opcode_names[op], b, result);
        } else {
            printf("Error performing operation!\n");
        }
    }
}

/* Print usage */
void print_usage(const char *prog_name)
{
    printf("Usage: %s [options]\n", prog_name);
    printf("Options:\n");
    printf("  -t           Run all test cases\n");
    printf("  -i           Interactive mode\n");
    printf("  -c a b op    Compute: a op b\n");
    printf("               op: 0=ADD 1=SUB 2=MUL 3=DIV 4=MOD 5=EQ 6=GT 7=LT\n");
    printf("  -h           Show this help\n");
    printf("\nExamples:\n");
    printf("  %s -t              # Run all tests\n", prog_name);
    printf("  %s -i              # Interactive mode\n", prog_name);
    printf("  %s -c 10 5 0       # Compute 10 + 5\n", prog_name);
    printf("  %s -c 20 4 2       # Compute 20 * 4\n", prog_name);
}

int main(int argc, char *argv[])
{
    unsigned int a, b, op, result;
    
    printf("\n");
    printf("*" * 60);
    printf("\n");
    printf("  ALU AXI Hardware Accelerator Test Program\n");
    printf("  Zybo Z7-20 Platform\n");
    printf("  Engineer: 나무\n");
    printf("*" * 60);
    printf("\n");
    
    // Check if driver is loaded
    if (access(SYSFS_ALU_PATH, F_OK) != 0) {
        printf("ERROR: ALU device not found at %s\n", SYSFS_ALU_PATH);
        printf("Please ensure:\n");
        printf("  1. Hardware is programmed with bitstream\n");
        printf("  2. Kernel driver is loaded\n");
        printf("  3. Device tree is properly configured\n");
        return 1;
    }
    
    if (argc < 2) {
        print_usage(argv[0]);
        return 1;
    }
    
    // Parse command line arguments
    if (strcmp(argv[1], "-t") == 0) {
        // Test mode
        printf("\nRunning comprehensive ALU tests...\n");
        
        test_all_operations(10, 5);
        test_all_operations(255, 1);
        test_all_operations(100, 25);
        test_all_operations(15, 0);  // Division by zero test
        test_all_operations(7, 7);   // Equal values
        
        printf("All tests completed!\n\n");
        
    } else if (strcmp(argv[1], "-i") == 0) {
        // Interactive mode
        interactive_mode();
        
    } else if (strcmp(argv[1], "-c") == 0) {
        // Compute mode
        if (argc != 5) {
            printf("Error: -c requires 3 arguments (a b op)\n");
            print_usage(argv[0]);
            return 1;
        }
        
        a = atoi(argv[2]);
        b = atoi(argv[3]);
        op = atoi(argv[4]);
        
        if (a > 255 || b > 255 || op > 7) {
            printf("Error: Invalid arguments (a,b: 0-255, op: 0-7)\n");
            return 1;
        }
        
        if (alu_compute(a, b, op, &result) == 0) {
            printf("\nOperation: %s\n", opcode_names[op]);
            printf("Result: %u %s %u = %u\n\n", a, opcode_names[op], b, result);
        } else {
            printf("Error performing operation!\n");
            return 1;
        }
        
    } else if (strcmp(argv[1], "-h") == 0) {
        print_usage(argv[0]);
        
    } else {
        printf("Unknown option: %s\n", argv[1]);
        print_usage(argv[0]);
        return 1;
    }
    
    return 0;
}
