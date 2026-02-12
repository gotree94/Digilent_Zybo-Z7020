# Makefile for Cocotb Simulation - Zybo Z7-20 Audio Project

# Simulator selection
SIM ?= icarus
TOPLEVEL_LANG ?= verilog

# RTL source files
VERILOG_SOURCES = $(PWD)/rtl/top.v

# Top-level module
TOPLEVEL = top

# Python test module
MODULE = test_top

# Additional simulation parameters
EXTRA_ARGS += --timescale=1ns/1ps

# Waveform dump
WAVES ?= 1
ifeq ($(WAVES), 1)
    EXTRA_ARGS += -DWAVES
endif

# Cocotb makefile
include $(shell cocotb-config --makefiles)/Makefile.sim

# Additional targets
.PHONY: clean waves lint help

waves:
	@echo "Opening waveform viewer..."
	@if [ -f dump.vcd ]; then \
		gtkwave dump.vcd & \
	else \
		echo "No waveform file found. Run 'make' first."; \
	fi

lint:
	@echo "Running Verilator lint check..."
	verilator --lint-only -Wall $(VERILOG_SOURCES)

help:
	@echo "Makefile for Zybo Z7-20 Audio Codec Project"
	@echo ""
	@echo "Targets:"
	@echo "  make          - Run cocotb simulation"
	@echo "  make waves    - Open waveform viewer (GTKWave)"
	@echo "  make lint     - Run Verilator lint check"
	@echo "  make clean    - Clean simulation files"
	@echo ""
	@echo "Options:"
	@echo "  SIM=icarus    - Use Icarus Verilog (default)"
	@echo "  SIM=verilator - Use Verilator"
	@echo "  WAVES=1       - Enable waveform dumping (default)"
	@echo ""
	@echo "Example:"
	@echo "  make SIM=icarus WAVES=1"

# Clean up
clean::
	rm -rf sim_build
	rm -f results.xml
	rm -f dump.vcd dump.fst
	rm -f *.log
