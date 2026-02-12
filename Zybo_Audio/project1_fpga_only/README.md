# Project 1: FPGA Only Audio Loopback

Pure PL (Programmable Logic) implementation using only Verilog HDL.

## Description

This project implements a simple audio loopback system that routes Line In (J7) directly to Headphone Out (J5). All processing is done in the FPGA fabric without using the PS (Processing System).

## Features

- Pure Verilog HDL implementation
- I2C master for SSM2603 codec configuration
- I2S transceiver for audio data
- Clock generation (MCLK, BCLK, LRCLK)
- LED status indicators

## Directory Structure

```
project1_fpga_only/
├── hdl/
│   ├── audio_top.v       # Top module
│   ├── i2c_config.v      # I2C configuration
│   ├── i2s_rx.v          # I2S receiver
│   ├── i2s_tx.v          # I2S transmitter
│   └── clk_divider.v     # Clock generation
├── constraints/
│   └── zybo_z7_audio.xdc # Pin constraints
└── scripts/
    └── create_project.tcl # Project creation script
```

## Building the Project

### Method 1: Using TCL Script

```bash
cd scripts
vivado -mode batch -source create_project.tcl
```

### Method 2: Manual Creation

1. Open Vivado
2. Create New Project
3. Select Zybo Z7-20 board
4. Add all HDL files from `hdl/` directory
5. Add constraints file from `constraints/`
6. Set `audio_top` as top module
7. Generate bitstream

## Programming the FPGA

### Using Hardware Manager

```tcl
open_hw_manager
connect_hw_server
open_hw_target
current_hw_device [get_hw_devices xc7z020_1]
set_property PROGRAM.FILE {path/to/audio_top.bit} [get_hw_devices xc7z020_1]
program_hw_devices [get_hw_devices xc7z020_1]
```

### Using Command Line

```bash
vivado -mode batch -source program.tcl
```

## Testing

1. Connect audio source to Line In (J7 - Light Blue)
2. Connect headphones to Headphone Out (J5 - Black)
3. Program the FPGA with the bitstream
4. Observe LED status:
   - **LED[0]**: I2C configuration complete (should be ON)
   - **LED[1]**: Audio data valid (blinks with audio)
   - **LED[2]**: LR clock activity (fast blink - 48kHz)
   - **LED[3]**: Audio level indicator

## Specifications

- Sample Rate: 48 kHz
- Bit Depth: 24-bit
- Channels: 2 (Stereo)
- Latency: ~1-2 samples (20-40 μs)

## Clock Frequencies

| Clock | Frequency | Purpose |
|-------|-----------|---------|
| MCLK | 12.5 MHz | Master clock to codec |
| BCLK | 3.125 MHz | Bit clock for I2S |
| LRCLK | 48 kHz | Left/Right channel select |

## Troubleshooting

### No Audio Output

1. Check LED[0] - if OFF, I2C configuration failed
2. Verify I2C connections (SCL: N18, SDA: N17)
3. Check power supply voltage

### Distorted Audio

1. Verify clock frequencies with scope
2. Check MCLK is reaching the codec (T19)
3. Ensure proper grounding

### LED[0] Never Turns On

1. Check I2C pullup resistors on board
2. Verify codec I2C address (0x1A)
3. Slow down I2C clock in `i2c_config.v`

## License

MIT License - See root LICENSE file
