# SSM2603 Register Map

## Complete Register Reference

### R0: Left Line In (0x00)

| Bit | Name | Description | Default |
|-----|------|-------------|---------|
| [4:0] | LINVOL | Left line input volume | 10111b (0dB) |
| 7 | LINMUTE | Left line input mute | 1 (muted) |
| 8 | LRINBOTH | Simultaneous load to L/R | 0 |

**Volume Control**: 
- 0x00 = -34.5dB (mute)
- 0x17 = 0dB
- 0x1F = +12dB

### R1: Right Line In (0x01)

Same as R0 but for right channel.

### R2: Left Headphone Out (0x02)

| Bit | Name | Description | Default |
|-----|------|-------------|---------|
| [6:0] | LHPVOL | Left headphone volume | 1111001b (0dB) |
| 7 | LZCEN | Left zero cross enable | 1 |
| 8 | LRHPBOTH | Simultaneous load | 0 |

**Volume Control**:
- 0x30 = -73dB (mute)
- 0x79 = 0dB
- 0x7F = +6dB

### R3: Right Headphone Out (0x03)

Same as R2 but for right channel.

### R4: Analog Audio Path (0x04)

| Bit | Name | Value | Description |
|-----|------|-------|-------------|
| 0 | MICBOOST | 0/1 | Mic boost (0=disable, 1=+20dB) |
| 1 | MUTEMIC | 0/1 | Mic mute |
| 2 | INSEL | 0/1 | Input select (0=Line, 1=Mic) |
| 3 | BYPASS | 0/1 | Bypass switch |
| 4 | DACSEL | 0/1 | DAC select |
| 5 | SIDETONE | 0/1 | Side tone enable |
| [7:6] | SIDEATT | 00-11 | Side tone attenuation |

**Common Settings**:
- Line In to DAC: 0x12 (DACSEL=1, bypass=0)
- Mic In to DAC: 0x15 (DACSEL=1, INSEL=1, MICBOOST=1)

### R5: Digital Audio Path (0x05)

| Bit | Name | Value | Description |
|-----|------|-------|-------------|
| 0 | ADCHPD | 0/1 | ADC high pass filter (0=enable) |
| 1 | DEEMP | 00-11 | De-emphasis (00=disable) |
| 3 | DACMU | 0/1 | DAC soft mute |
| 4 | HPOR | 0/1 | Store DC offset |

**Typical**: 0x00 (all features disabled)

### R6: Power Down Control (0x06)

| Bit | Name | Value | Description |
|-----|------|-------|-------------|
| 0 | LINEINPD | 0/1 | Line input power down |
| 1 | MICPD | 0/1 | Mic input power down |
| 2 | ADCPD | 0/1 | ADC power down |
| 3 | DACPD | 0/1 | DAC power down |
| 4 | OUTPD | 0/1 | Output power down |
| 5 | OSCPD | 0/1 | Oscillator power down |
| 6 | CLKOUTPD | 0/1 | CLKOUT power down |
| 7 | POWEROFF | 0/1 | Complete power off |

**Active State**: 0x00 (all powered on)

### R7: Digital Audio Interface (0x07)

| Bit | Name | Value | Description |
|-----|------|-------|-------------|
| [1:0] | FORMAT | 00-11 | Audio format |
|  |  | 00 | Right justified |
|  |  | 01 | Left justified |
|  |  | 10 | I2S |
|  |  | 11 | DSP mode |
| [3:2] | IWL | 00-11 | Input bit length |
|  |  | 00 | 16-bit |
|  |  | 01 | 20-bit |
|  |  | 10 | 24-bit |
|  |  | 11 | 32-bit |
| 4 | LRP | 0/1 | DACLRC phase |
| 5 | LRSWAP | 0/1 | DAC L/R swap |
| 6 | MS | 0/1 | Master/Slave (0=slave) |
| 7 | BCLKINV | 0/1 | BCLK invert |

**I2S, 24-bit, Slave**: 0x0A

### R8: Sample Rate Control (0x08)

| Bit | Name | Description |
|-----|------|-------------|
| 0 | USB/NORMAL | 0=normal, 1=USB mode |
| 1 | BOSR | Base oversampling rate |
| [5:2] | SR[3:0] | Sample rate |
| 6 | CLKIDIV2 | Core clock divider |
| 7 | CLKODIV2 | CLKOUT divider |

**Sample Rate Values** (Normal mode, 12.288MHz MCLK):

| SR[3:0] | Rate | BOSR |
|---------|------|------|
| 0000 | 48 kHz | X |
| 0001 | 8 kHz | 0 |
| 0010 | 8.021 kHz | 1 |
| 0011 | 32 kHz | 0 |
| 0110 | 96 kHz | 0 |
| 0111 | 96 kHz | 1 |
| 1000 | 44.1 kHz | 0 |

**48kHz Setting**: 0x00

### R9: Digital Interface Activation (0x09)

| Bit | Name | Value | Description |
|-----|------|-------|-------------|
| 0 | ACTIVE | 0/1 | Activate interface |

**Activate**: 0x01

### R15: Reset (0x0F)

Writing any value to this register resets the codec to default state.

## Quick Reference: Common Configurations

### Line In → Line Out (Loopback)

```c
write_reg(0x0F, 0x00);  // Reset
write_reg(0x06, 0x00);  // Power on
write_reg(0x04, 0x12);  // DAC select
write_reg(0x05, 0x00);  // Digital path
write_reg(0x07, 0x0A);  // I2S, 24-bit
write_reg(0x08, 0x00);  // 48kHz
write_reg(0x00, 0x17);  // Left in 0dB
write_reg(0x01, 0x17);  // Right in 0dB
write_reg(0x02, 0x79);  // Left out 0dB
write_reg(0x03, 0x79);  // Right out 0dB
write_reg(0x09, 0x01);  // Activate
```

### Microphone In → Headphone Out

```c
write_reg(0x04, 0x15);  // Mic input, boost +20dB
write_reg(0x00, 0x17);  // Mic volume
// ... (rest same as above)
```

## Bit Field Access Macros

```c
#define REG_ADDR(reg)           ((reg) << 1)
#define SET_BITS(val, mask)     ((val) | (mask))
#define CLR_BITS(val, mask)     ((val) & ~(mask))

// Volume macros
#define LINVOL(db)              ((db) + 0x17)  // -34.5 to +12 dB
#define HPVOL(db)               ((db) + 0x79)  // -73 to +6 dB
```
