# I2S Timing Specifications

## Overview

I2S (Inter-IC Sound) is the serial bus interface for audio data transfer.

## Signal Description

- **BCLK**: Bit Clock (serial clock)
- **LRCLK**: Left/Right Clock (word select)
- **SDATA**: Serial Data (multiplexed left/right)
- **MCLK**: Master Clock (codec system clock)

## Timing Diagram

```
LRCLK:  ____/‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾\____________________/‾‾‾‾
         Left Channel          Right Channel
         
BCLK:   _|-|_|-|_|-|_|-|_|-|_|-|_|-|_|-|_|-|_|-|_|-|_|

SDATA:  |MSB|...|...|...|...|LSB|x|x|MSB|...|...|LSB|
```

## Clock Frequencies (48kHz Sample Rate)

| Clock | Frequency | Calculation |
|-------|-----------|-------------|
| MCLK | 12.288 MHz | 256 × 48 kHz |
| BCLK | 3.072 MHz | 64 × 48 kHz |
| LRCLK | 48 kHz | Sample rate |

### For 24-bit Audio:
- **BCLK**: 2 channels × 24 bits × 48 kHz = 2.304 MHz (minimum)
- **Actual**: 3.072 MHz (64× LRCLK) provides margin

## Data Format

### Left Justified

```
LRCLK:  ‾‾‾‾‾\________________
BCLK:   _|-|_|-|_|-|_|-|_|-|_
SDATA:  |MSB|23|22|...|0|x|x|
        ↑ Data valid immediately after LRCLK edge
```

### I2S (Standard)

```
LRCLK:  ____/‾‾‾‾‾‾‾‾‾‾‾‾‾‾‾
BCLK:   _|-|_|-|_|-|_|-|_|-|
SDATA:  |x|MSB|23|22|...|0|x|
           ↑ Data delayed 1 BCLK after LRCLK
```

### Right Justified

```
LRCLK:  ‾‾‾‾‾\________________
BCLK:   _|-|_|-|_|-|_|-|_|-|_
SDATA:  |x|x|MSB|23|22|...|0|
              ↑ LSB aligned to last BCLK
```

## SSM2603 I2S Mode Settings

Register R7 (Digital Audio Interface Format):

| Bits | Value | Description |
|------|-------|-------------|
| [1:0] | 10b | I2S format |
| [3:2] | 10b | 24-bit data |
| [6] | 0 | Slave mode (codec) |

## Timing Parameters

### Setup and Hold Times

| Parameter | Min | Typ | Max | Unit |
|-----------|-----|-----|-----|------|
| BCLK Period | 325 | - | - | ns |
| BCLK Duty Cycle | 45 | 50 | 55 | % |
| LRCLK Setup to BCLK | 10 | - | - | ns |
| Data Setup to BCLK | 10 | - | - | ns |
| Data Hold from BCLK | 10 | - | - | ns |

## Verilog Implementation Example

```verilog
// I2S Transmitter
always @(posedge bclk) begin
    if (lrclk != lrclk_prev) begin
        // Load new data on LRCLK edge
        if (lrclk == 0)
            shift_reg <= left_data;
        else
            shift_reg <= right_data;
        bit_count <= 0;
    end else begin
        // Shift out MSB first
        sdata <= shift_reg[23];
        shift_reg <= {shift_reg[22:0], 1'b0};
        bit_count <= bit_count + 1;
    end
end
```

## Common Issues

### Audio Pops/Clicks

- **Cause**: LRCLK/BCLK ratio incorrect
- **Fix**: Ensure BCLK = 64 × LRCLK

### Left/Right Channels Swapped

- **Cause**: LRCLK polarity inverted
- **Fix**: Use LRCLK = 0 for left, LRCLK = 1 for right

### No Audio

- **Cause**: MCLK not running
- **Fix**: Verify MCLK at codec (should be 12.288 MHz)

### Distorted Audio

- **Cause**: Sample rate mismatch
- **Fix**: Match codec sample rate to LRCLK frequency
