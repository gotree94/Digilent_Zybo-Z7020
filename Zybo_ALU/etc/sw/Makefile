# Makefile for ALU AXI Test Programs
# Engineer: 나무
# Date: 2025-11-12

# Compiler settings
CC = gcc
CFLAGS = -Wall -O2
LDFLAGS = -lrt

# Cross-compile settings (uncomment for cross-compilation)
# CROSS_COMPILE = arm-linux-gnueabihf-
# CC = $(CROSS_COMPILE)gcc

# Targets
TARGETS = alu_test_devmem alu_test_sysfs

# Source files
SRC_DEVMEM = alu_test_devmem.c
SRC_SYSFS = alu_test_sysfs.c

# Object files
OBJ_DEVMEM = $(SRC_DEVMEM:.c=.o)
OBJ_SYSFS = $(SRC_SYSFS:.c=.o)

# Default target
all: $(TARGETS)
	@echo "Build complete!"
	@echo "Programs: $(TARGETS)"

# Build devmem version
alu_test_devmem: $(OBJ_DEVMEM)
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)
	@echo "Built: $@"

# Build sysfs version
alu_test_sysfs: $(OBJ_SYSFS)
	$(CC) $(CFLAGS) -o $@ $^ $(LDFLAGS)
	@echo "Built: $@"

# Compile source files
%.o: %.c
	$(CC) $(CFLAGS) -c -o $@ $<

# Clean
clean:
	rm -f $(TARGETS) *.o
	@echo "Clean complete"

# Install (copy to target system)
install: $(TARGETS)
	@echo "Installing to /usr/local/bin..."
	install -m 755 alu_test_devmem /usr/local/bin/
	install -m 755 alu_test_sysfs /usr/local/bin/
	@echo "Installation complete"

# Help
help:
	@echo "ALU AXI Test Programs Makefile"
	@echo ""
	@echo "Targets:"
	@echo "  all              - Build all programs (default)"
	@echo "  alu_test_devmem  - Build /dev/mem version"
	@echo "  alu_test_sysfs   - Build sysfs version"
	@echo "  clean            - Remove build artifacts"
	@echo "  install          - Install programs to /usr/local/bin"
	@echo "  help             - Show this help"
	@echo ""
	@echo "Cross-compilation:"
	@echo "  Edit CROSS_COMPILE variable in Makefile"
	@echo "  Example: CROSS_COMPILE=arm-linux-gnueabihf-"

.PHONY: all clean install help
