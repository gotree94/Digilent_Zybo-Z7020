# Hardware Setup Guide

## Zybo Z7-20 Board Setup

### Power Supply

- Use 5V/2.5A power adapter OR
- USB power (limited functionality)

### Audio Connections

#### J7 - Line In (Light Blue)
- Connect audio source (MP3 player, smartphone, computer)
- 3.5mm stereo jack
- Input level: Line level (≈1V RMS)

#### J6 - Microphone In (Pink)
- Connect electret microphone OR
- External microphone with 3.5mm jack
- Provides 2.5V bias voltage
- Mono input only

#### J5 - Headphone Out (Black)
- Connect headphones or powered speakers
- 3.5mm stereo jack
- Output power: 30mW per channel @ 32Ω

### JTAG/UART Connections

- Micro USB cable to J12
- Provides JTAG programming and UART console
- Drivers: FTDI FT2232H

### SD Card (For PetaLinux)

- Format: FAT32 (BOOT partition) + ext4 (rootfs)
- Minimum 8GB capacity
- Insert into SD card slot

## SSM2603 Audio Codec

### Pin Configuration

```
Pin  | Signal   | Description
-----|----------|-------------
1    | LLINEIN  | Left Line In
2    | LRINEIN  | Right Line In
3    | MICIN    | Microphone In
4    | GND      | Ground
5-6  | Reserved | -
7    | LHPOUT   | Left Headphone Out
8    | RHPOUT   | Right Headphone Out
9    | MCLK     | Master Clock (12MHz)
10   | BCLK     | Bit Clock
11   | PBLRC    | Playback LR Clock
12   | PBDAT    | Playback Data
13   | RECLRC   | Record LR Clock
14   | RECDAT   | Record Data
15   | SDA      | I2C Data
16   | SCL      | I2C Clock
```

### Jumper Settings

No jumpers need to be changed for audio functionality.

## LED Indicators

- **LD0-LD3**: User LEDs (audio status)
- **LD4**: FPGA done (should be ON after programming)
- **LD5**: Power indicator

## Testing Hardware

### Loopback Test

1. Connect headphones to J5
2. Connect audio source to J7
3. Program FPGA
4. Should hear audio immediately

### Microphone Test

1. Connect microphone to J6
2. Connect headphones to J5
3. Select MIC input in software
4. Speak into microphone

## Safety Warnings

⚠️ **Volume Warning**: Start with low volume to prevent hearing damage

⚠️ **Power Warning**: Use only 5V power supply

⚠️ **ESD Warning**: Handle board by edges, avoid touching components
