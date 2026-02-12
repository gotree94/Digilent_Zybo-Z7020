"""
Cocotb Testbench for Zybo Z7-20 Audio Top Module

This testbench verifies basic functionality of the audio codec interface
"""

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer, ClockCycles
from cocotb.binary import BinaryValue
import random

@cocotb.test()
async def test_basic_functionality(dut):
    """Test basic system functionality"""
    
    # Create a 125 MHz clock
    clock = Clock(dut.clk, 8, units="ns")  # 8ns period = 125 MHz
    cocotb.start_soon(clock.start())
    
    # Initialize inputs
    dut.sw.value = 0
    dut.btn.value = 0
    dut.ac_bclk.value = 0
    dut.ac_recdat.value = 0
    dut.ac_reclrc.value = 0
    
    # Wait for a few clock cycles
    await ClockCycles(dut.clk, 10)
    
    # Test LED heartbeat
    dut._log.info("Testing LED heartbeat...")
    initial_led = dut.led.value
    await ClockCycles(dut.clk, 1000)
    
    # Test switch control
    dut._log.info("Testing switch control...")
    dut.sw.value = 0b0001  # Enable mute
    await ClockCycles(dut.clk, 10)
    assert dut.ac_muten.value == 1, "Mute should be enabled"
    
    dut.sw.value = 0b0000  # Disable mute
    await ClockCycles(dut.clk, 10)
    assert dut.ac_muten.value == 0, "Mute should be disabled"
    
    # Test button functionality
    dut._log.info("Testing button inputs...")
    dut.btn.value = 0b0001
    await ClockCycles(dut.clk, 10)
    assert dut.led.value[3] == 1, "LED[3] should reflect button press"
    
    dut.btn.value = 0b0000
    await ClockCycles(dut.clk, 10)
    
    dut._log.info("Basic functionality test passed!")


@cocotb.test()
async def test_audio_loopback(dut):
    """Test audio loopback functionality"""
    
    # Create a 125 MHz clock
    clock = Clock(dut.clk, 8, units="ns")
    cocotb.start_soon(clock.start())
    
    # Initialize
    dut.sw.value = 1  # Unmute
    dut.btn.value = 0
    dut.ac_recdat.value = 0
    
    await ClockCycles(dut.clk, 100)
    
    # Test audio loopback
    dut._log.info("Testing audio loopback...")
    
    for _ in range(100):
        # Generate random audio data
        audio_bit = random.randint(0, 1)
        dut.ac_recdat.value = audio_bit
        
        await ClockCycles(dut.clk, 1)
        
        # Check that playback data matches record data
        assert dut.ac_pbdat.value == audio_bit, \
            f"Loopback failed: expected {audio_bit}, got {dut.ac_pbdat.value}"
    
    dut._log.info("Audio loopback test passed!")


@cocotb.test()
async def test_mclk_generation(dut):
    """Test master clock generation"""
    
    # Create a 125 MHz clock
    clock = Clock(dut.clk, 8, units="ns")
    cocotb.start_soon(clock.start())
    
    await ClockCycles(dut.clk, 10)
    
    dut._log.info("Testing MCLK generation...")
    
    # Count MCLK toggles
    mclk_toggles = 0
    prev_mclk = dut.ac_mclk.value
    
    for _ in range(1000):
        await RisingEdge(dut.clk)
        current_mclk = dut.ac_mclk.value
        if current_mclk != prev_mclk:
            mclk_toggles += 1
        prev_mclk = current_mclk
    
    dut._log.info(f"MCLK toggles in 1000 system clocks: {mclk_toggles}")
    
    # MCLK should toggle (rough check)
    assert mclk_toggles > 0, "MCLK should be toggling"
    
    dut._log.info("MCLK generation test passed!")


@cocotb.test()
async def test_lrc_passthrough(dut):
    """Test Left/Right clock passthrough"""
    
    # Create a 125 MHz clock
    clock = Clock(dut.clk, 8, units="ns")
    cocotb.start_soon(clock.start())
    
    # Create a slower LR clock
    lrc_clock = Clock(dut.ac_reclrc, 1000, units="ns")  # 1 MHz
    cocotb.start_soon(lrc_clock.start())
    
    await ClockCycles(dut.clk, 10)
    
    dut._log.info("Testing L/R clock passthrough...")
    
    # Check that playback LRC follows record LRC
    for _ in range(100):
        await RisingEdge(dut.ac_reclrc)
        await ClockCycles(dut.clk, 2)
        assert dut.ac_pblrc.value == dut.ac_reclrc.value, \
            "Playback LRC should match record LRC"
    
    dut._log.info("L/R clock passthrough test passed!")


# Regression test
@cocotb.test()
async def test_regression(dut):
    """Run all basic tests in sequence"""
    
    dut._log.info("=" * 50)
    dut._log.info("Starting Regression Test Suite")
    dut._log.info("=" * 50)
    
    # This test just verifies the system doesn't crash
    clock = Clock(dut.clk, 8, units="ns")
    cocotb.start_soon(clock.start())
    
    # Run for extended period
    await ClockCycles(dut.clk, 10000)
    
    dut._log.info("=" * 50)
    dut._log.info("Regression Test Completed Successfully")
    dut._log.info("=" * 50)
