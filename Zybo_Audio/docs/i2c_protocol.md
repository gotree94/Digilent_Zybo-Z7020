# I2C Protocol for SSM2603

## Overview

The SSM2603 uses I2C for register configuration. The I2C address is **0x1A** (7-bit).

## I2C Timing

- **Clock Frequency**: 100 kHz (Standard Mode) or 400 kHz (Fast Mode)
- **Setup Time**: 250 ns minimum
- **Hold Time**: 0 ns minimum

## Register Write Sequence

```
START | ADDR+W | ACK | REG[15:9]+DATA[8] | ACK | DATA[7:0] | ACK | STOP
```

1. **START**: Start condition
2. **ADDR+W**: Device address (0x1A) + Write bit (0)
3. **ACK**: Acknowledge from codec
4. **REG[15:9]**: Register address (7 bits) + MSB of data
5. **ACK**: Acknowledge
6. **DATA[7:0]**: Data byte
7. **ACK**: Acknowledge
8. **STOP**: Stop condition

## Register Map

| Register | Address | Description |
|----------|---------|-------------|
| R0 | 0x00 | Left Line In |
| R1 | 0x01 | Right Line In |
| R2 | 0x02 | Left Headphone Out |
| R3 | 0x03 | Right Headphone Out |
| R4 | 0x04 | Analog Audio Path |
| R5 | 0x05 | Digital Audio Path |
| R6 | 0x06 | Power Down Control |
| R7 | 0x07 | Digital Audio Interface |
| R8 | 0x08 | Sample Rate Control |
| R9 | 0x09 | Digital Interface Activation |
| R15 | 0x0F | Reset |

## Initialization Sequence

```c
// 1. Reset
write_register(R15_RESET, 0x00);
delay(10ms);

// 2. Power up
write_register(R6_POWER, 0x00);  // All on

// 3. Configure analog path
write_register(R4_ANALOG, 0x12); // DAC select, bypass off

// 4. Configure digital path
write_register(R5_DIGITAL, 0x00); // Disable mute

// 5. Set interface format
write_register(R7_INTERFACE, 0x0A); // I2S, 24-bit, slave

// 6. Set sample rate
write_register(R8_SRATE, 0x00); // 48kHz

// 7. Set volumes
write_register(R0_LINVOL, 0x17);  // Left line in
write_register(R1_RINVOL, 0x17);  // Right line in
write_register(R2_LHPVOL, 0x79);  // Left HP
write_register(R3_RHPVOL, 0x79);  // Right HP

// 8. Activate
write_register(R9_ACTIVE, 0x01);
```

## Example: Setting Volume

```verilog
// Set left headphone volume to 0dB
// R2 = 0x04, Volume = 0x79
// Register data: 0x0479

// I2C sequence:
START
0x34        // Address 0x1A << 1 = 0x34
ACK
0x08        // R2[6:0] << 1 | DATA[8] = 0x04 << 1 | 0 = 0x08  
ACK
0x79        // Volume data
ACK
STOP
```

## Common Issues

### No ACK from Codec

- Check I2C pullup resistors (typically 4.7kΩ)
- Verify power supply to codec
- Check I2C address (0x1A not 0x34)

### Register Writes Fail

- Ensure proper timing (clock not too fast)
- Check SDA/SCL pins are not swapped
- Verify START/STOP conditions

## Debug with i2cdetect

```bash
# Linux command
i2cdetect -y 0

# Should show:
#      0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f
# 10: -- -- -- -- -- -- -- -- -- -- 1a -- -- -- -- --
```
