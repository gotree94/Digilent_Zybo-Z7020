# Zynq Z7-20 + PCAM5C HDMI 출력 프로젝트

## 프로젝트 개요

이 프로젝트는 Digilent Zynq Z7-20 보드와 PCAM5C(OV5640 기반) 카메라 모듈을 사용하여 실시간 카메라 영상을 HDMI로 출력하는 시스템을 구현합니다.

### 개발 환경
- Vivado 2022.2
- Vitis 2022.2
- Digilent Zynq Z7-20 보드
- Digilent PCAM5C 카메라 모듈

### 시스템 구성도

```
PCAM5C (MIPI CSI-2) → MIPI D-PHY → Demosaic → Gamma LUT → 
Video Timing Controller → AXI VDMA → DDR Memory → 
AXI VDMA → Video Timing Controller → RGB to DVI → HDMI TX
```

---

## Part 1: Vivado 하드웨어 설계

### 1.1 프로젝트 생성

1. Vivado 2022.2 실행
2. **Create Project** 클릭
3. Project Name: `zynq_z7_pcam_hdmi`
4. Project Type: **RTL Project**
5. Board Selection: **Zynq-Z7-20** (xc7z020clg400-1)

### 1.2 Board Files 설치

Digilent Board Files가 설치되지 않은 경우:

```bash
cd ~/Vivado/2022.2/data/boards/board_files
git clone https://github.com/Digilent/vivado-boards.git
cp -r vivado-boards/new/board_files/* .
```

### 1.3 IP Repository 추가

Digilent의 Vivado Library가 필요합니다:

```bash
cd ~/workspace
git clone https://github.com/Digilent/vivado-library.git
```

Vivado에서:
1. **Settings** → **IP** → **Repository**
2. **+** 클릭 → `vivado-library` 폴더 추가
3. **Apply** → **OK**

---

## Part 2: Block Design 생성

### 2.1 새 Block Design 생성

1. **Create Block Design** → Name: `design_1`
2. **Add IP** (Ctrl+I)

### 2.2 필요한 IP 추가

다음 IP들을 추가합니다:

| IP Name | 용도 |
|---------|------|
| ZYNQ7 Processing System | PS 프로세서 |
| MIPI D-PHY | MIPI 물리 계층 |
| MIPI CSI-2 Rx Subsystem | CSI-2 수신 |
| Sensor Demosaic | Bayer to RGB 변환 |
| Gamma LUT | 감마 보정 |
| AXI Video Direct Memory Access (x2) | 영상 데이터 전송 |
| Video Timing Controller (x2) | 타이밍 생성/검출 |
| AXI4-Stream to Video Out | Stream to Video 변환 |
| RGB to DVI Video Encoder | DVI/HDMI 출력 |
| Clocking Wizard (x2) | 클럭 생성 |
| Processor System Reset (x2) | 리셋 관리 |
| AXI Interconnect | AXI 버스 연결 |
| AXI GPIO | GPIO 제어 |
| AXI IIC | I2C 통신 (카메라 설정) |

### 2.3 ZYNQ Processing System 설정

ZYNQ7 Processing System을 더블클릭하여 설정:

#### PS-PL Configuration
- **HP Slave AXI Interface** → **S AXI HP0** 활성화
- **General** → **Enable Clock Resets** → **FCLK_RESET0_N** 활성화

#### Clock Configuration
- **PL Fabric Clocks**:
  - FCLK_CLK0: 100 MHz (AXI 버스용)
  - FCLK_CLK1: 200 MHz (MIPI D-PHY용)
  - FCLK_CLK2: 50 MHz (예비)

#### DDR Configuration
- **Memory Part**: MT41K256M16RE-125 (기본값 유지)

#### Interrupts
- **Fabric Interrupts** → **PL-PS Interrupt Ports** → **IRQ_F2P** 활성화

### 2.4 Clocking Wizard 설정

#### clk_wiz_0 (HDMI 픽셀 클럭용)
- **Input Clock**: FCLK_CLK0 (100 MHz)
- **Output Clocks**:
  - clk_out1: 148.5 MHz (1080p 픽셀 클럭)
  - clk_out2: 742.5 MHz (TMDS 클럭, 5x 픽셀 클럭)
- **Primitive**: MMCM

#### clk_wiz_1 (카메라용)
- **Input Clock**: FCLK_CLK1 (200 MHz)
- **Output Clocks**:
  - clk_out1: 200 MHz (MIPI D-PHY용)

### 2.5 MIPI CSI-2 Rx Subsystem 설정

- **Lanes**: 2
- **Line Rate (Mbps)**: 672
- **Pixel Format**: RAW10
- **Pixels per Clock**: 1
- **FIFO Depth**: 2048
- **Include Video Format Bridge**: Yes

### 2.6 Video DMA 설정 (Write Channel - 카메라 입력)

- **Enable Read Channel**: No
- **Enable Write Channel**: Yes
- **Write Burst Size**: 16
- **Stream Data Width**: 24
- **Line Buffer Depth**: 4096
- **Frame Buffers**: 3
- **Allow Unaligned Transfers**: Yes
- **GenLock Mode**: Master

### 2.7 Video DMA 설정 (Read Channel - HDMI 출력)

- **Enable Read Channel**: Yes
- **Enable Write Channel**: No
- **Read Burst Size**: 16
- **Stream Data Width**: 24
- **Line Buffer Depth**: 4096
- **Frame Buffers**: 3
- **GenLock Mode**: Slave

### 2.8 Video Timing Controller 설정 (Detector - 입력)

- **Enable Detection**: Yes
- **Enable Generation**: No
- **Maximum Columns**: 1920
- **Maximum Rows**: 1080

### 2.9 Video Timing Controller 설정 (Generator - 출력)

- **Enable Detection**: No
- **Enable Generation**: Yes
- **Maximum Columns**: 1920
- **Maximum Rows**: 1080

### 2.10 AXI4-Stream to Video Out 설정

- **Clock Mode**: Independent
- **FIFO Depth**: 4096
- **Hysteresis Level**: 12

### 2.11 Sensor Demosaic 설정

- **Data Width**: 10
- **Maximum Columns**: 1920
- **Maximum Rows**: 1080
- **Bayer Pattern**: RGGB (OV5640 기본값)

### 2.12 RGB to DVI Video Encoder 설정

- **TMDS Clock Range**: > 120 MHz (HIGH)
- **Generate SerialClk Internally**: Yes

---

## Part 3: Block Design 연결

### 3.1 자동 연결

1. **Run Connection Automation** 클릭
2. 모든 항목 선택 후 **OK**

### 3.2 수동 연결 확인 및 수정

아래 연결을 확인하고 필요시 수동으로 연결합니다.

#### 클럭 연결
```
FCLK_CLK0 (100MHz) → AXI Interconnect, AXI GPIO, AXI IIC
FCLK_CLK1 (200MHz) → MIPI D-PHY
clk_wiz_0/clk_out1 (148.5MHz) → Video Timing Controller (Gen), RGB to DVI (PixelClk)
clk_wiz_0/clk_out2 (742.5MHz) → RGB to DVI (SerialClk)
```

#### 비디오 스트림 연결
```
MIPI CSI-2 Rx → Sensor Demosaic → Gamma LUT → 
Video Timing Controller (Det) → VDMA (Write) → 
DDR Memory → VDMA (Read) → 
AXI4-Stream to Video Out → RGB to DVI → HDMI
```

#### 인터럽트 연결
```
VDMA (Write) mm2s_introut → Concat → IRQ_F2P
VDMA (Read) s2mm_introut → Concat → IRQ_F2P
```

### 3.3 외부 포트 생성

다음 신호들을 외부 포트로 만듭니다:

1. **HDMI 출력**
   - RGB to DVI의 `TMDS_Clk_p`, `TMDS_Clk_n` → 외부 포트 `hdmi_tx_clk_p`, `hdmi_tx_clk_n`
   - RGB to DVI의 `TMDS_Data_p[2:0]`, `TMDS_Data_n[2:0]` → 외부 포트 `hdmi_tx_data_p`, `hdmi_tx_data_n`

2. **MIPI 카메라 입력**
   - MIPI D-PHY의 `clk_rxp`, `clk_rxn` → 외부 포트 `cam_clk_p`, `cam_clk_n`
   - MIPI D-PHY의 `data_rxp[1:0]`, `data_rxn[1:0]` → 외부 포트 `cam_data_p`, `cam_data_n`

3. **카메라 제어**
   - AXI GPIO → 외부 포트 `cam_gpio` (전원/리셋 제어)
   - AXI IIC → 외부 포트 `cam_iic` (SCCB 통신)

---

## Part 4: 제약 조건 파일 (XDC)

### 4.1 XDC 파일 생성

`constraints/zynq_z7_pcam_hdmi.xdc` 파일을 생성합니다:

```tcl
# =============================================================================
# Zynq Z7-20 PCAM5C HDMI Output Constraints
# Bank 35 VCCO = 2.5V Configuration (Set JP6 jumper to 2V5)
# =============================================================================
#
# IMPORTANT HARDWARE SETUP:
# - Set JP6 jumper to "2V5" position on Zybo Z7 board
# - This allows MIPI (LVDS_25) and HDMI TX to coexist in Bank 35
#
# =============================================================================

# =============================================================================
# HDMI TX Output (Bank 35 - VCCO 2.5V)
# Using LVDS_25 for differential TMDS signals
# =============================================================================
set_property -dict {PACKAGE_PIN H16 IOSTANDARD LVDS_25} [get_ports hdmi_tx_clk_p]
set_property -dict {PACKAGE_PIN H17 IOSTANDARD LVDS_25} [get_ports hdmi_tx_clk_n]

set_property -dict {PACKAGE_PIN D19 IOSTANDARD LVDS_25} [get_ports {hdmi_tx_data_p[0]}]
set_property -dict {PACKAGE_PIN D20 IOSTANDARD LVDS_25} [get_ports {hdmi_tx_data_n[0]}]
set_property -dict {PACKAGE_PIN C20 IOSTANDARD LVDS_25} [get_ports {hdmi_tx_data_p[1]}]
set_property -dict {PACKAGE_PIN B20 IOSTANDARD LVDS_25} [get_ports {hdmi_tx_data_n[1]}]
set_property -dict {PACKAGE_PIN B19 IOSTANDARD LVDS_25} [get_ports {hdmi_tx_data_p[2]}]
set_property -dict {PACKAGE_PIN A20 IOSTANDARD LVDS_25} [get_ports {hdmi_tx_data_n[2]}]

# =============================================================================
# PCAM5C MIPI Interface - High Speed Signals (Bank 35 - VCCO 2.5V)
# =============================================================================

# MIPI Clock Lane - High Speed
set_property -dict {PACKAGE_PIN J18 IOSTANDARD LVDS_25 DIFF_TERM TRUE} [get_ports dphy_hs_clock_clk_p]
set_property -dict {PACKAGE_PIN H18 IOSTANDARD LVDS_25 DIFF_TERM TRUE} [get_ports dphy_hs_clock_clk_n]

# MIPI Data Lane 0 - High Speed
set_property -dict {PACKAGE_PIN M19 IOSTANDARD LVDS_25 DIFF_TERM TRUE} [get_ports {dphy_data_hs_p[0]}]
set_property -dict {PACKAGE_PIN M20 IOSTANDARD LVDS_25 DIFF_TERM TRUE} [get_ports {dphy_data_hs_n[0]}]

# MIPI Data Lane 1 - High Speed
set_property -dict {PACKAGE_PIN L16 IOSTANDARD LVDS_25 DIFF_TERM TRUE} [get_ports {dphy_data_hs_p[1]}]
set_property -dict {PACKAGE_PIN L17 IOSTANDARD LVDS_25 DIFF_TERM TRUE} [get_ports {dphy_data_hs_n[1]}]

# =============================================================================
# PCAM5C MIPI Interface - Low Power Signals
# =============================================================================

# MIPI Clock Lane - Low Power
set_property -dict {PACKAGE_PIN H20 IOSTANDARD HSUL_12} [get_ports dphy_clk_lp_p]
set_property -dict {PACKAGE_PIN J19 IOSTANDARD HSUL_12} [get_ports dphy_clk_lp_n]

# MIPI Data Lane 0 - Low Power
set_property -dict {PACKAGE_PIN L19 IOSTANDARD HSUL_12} [get_ports {dphy_data_lp_p[0]}]
set_property -dict {PACKAGE_PIN M18 IOSTANDARD HSUL_12} [get_ports {dphy_data_lp_n[0]}]

# MIPI Data Lane 1 - Low Power
set_property -dict {PACKAGE_PIN J20 IOSTANDARD HSUL_12} [get_ports {dphy_data_lp_p[1]}]
set_property -dict {PACKAGE_PIN L20 IOSTANDARD HSUL_12} [get_ports {dphy_data_lp_n[1]}]

# =============================================================================
# PCAM5C Control Signals (Bank 35 - VCCO 2.5V)
# Must use LVCMOS25 to match bank voltage
# =============================================================================

# Camera Power Enable GPIO
set_property PACKAGE_PIN G20 [get_ports {cam_gpio[0]}]
set_property IOSTANDARD LVCMOS25 [get_ports {cam_gpio[0]}]
set_property PULLUP true [get_ports {cam_gpio[0]}]

# Camera I2C (SCCB)
set_property -dict {PACKAGE_PIN F20 IOSTANDARD LVCMOS25} [get_ports cam_iic_scl_io]
set_property -dict {PACKAGE_PIN F19 IOSTANDARD LVCMOS25} [get_ports cam_iic_sda_io]

# =============================================================================
# Bank 35 INTERNAL_VREF for HSUL_12 standard
# =============================================================================
set_property INTERNAL_VREF 0.6 [get_iobanks 35]

# =============================================================================
# Clock Constraints
# =============================================================================

# MIPI HS Clock from camera
create_clock -period 4.761 -name dphy_hs_clock_p -waveform {0.000 2.380} [get_ports dphy_hs_clock_clk_p]

# =============================================================================
# Physical Constraints
# =============================================================================

# Configuration voltage
set_property CFGBVS VCCO [current_design]
set_property CONFIG_VOLTAGE 3.3 [current_design]

# Unused pins
set_property BITSTREAM.CONFIG.UNUSEDPIN PULLUP [current_design]


```

---

## Part 5: Synthesis 및 Implementation

### 5.1 Validate Design

1. Block Design에서 **Validate Design** (F6) 실행
2. 오류가 없는지 확인

### 5.2 HDL Wrapper 생성

1. Sources 패널에서 `design_1` 우클릭
2. **Create HDL Wrapper** → **Let Vivado manage wrapper and auto-update**

### 5.3 Synthesis 및 Implementation 실행

1. **Run Synthesis** (F11)
2. Synthesis 완료 후 **Run Implementation**
3. Implementation 완료 후 **Generate Bitstream**

### 5.4 Hardware Export

1. **File** → **Export** → **Export Hardware**
2. **Include bitstream** 체크
3. Export 위치: 프로젝트 폴더

---

## Part 6: Vitis 소프트웨어 개발

### 6.1 Vitis Workspace 생성

1. Vitis 2022.2 실행
2. Workspace 선택: `zynq_z7_pcam_hdmi/vitis_workspace`
3. **Create Application Project**

### 6.2 Platform 생성

1. **Create a new platform from hardware (XSA)**
2. XSA 파일 선택: Export된 `.xsa` 파일
3. Platform Name: `zynq_z7_pcam_platform`

### 6.3 Application 프로젝트 생성

1. Application Name: `pcam_hdmi_app`
2. Domain: `standalone_ps7_cortexa9_0`
3. Template: **Empty Application (C)**

---

## Part 7: 소프트웨어 소스 코드

### 7.1 프로젝트 구조

```
pcam_hdmi_app/
├── src/
│   ├── main.c
│   ├── camera/
│   │   ├── ov5640.c
│   │   ├── ov5640.h
│   │   └── ov5640_init.h
│   ├── video/
│   │   ├── video_capture.c
│   │   ├── video_capture.h
│   │   ├── video_display.c
│   │   └── video_display.h
│   ├── hdmi/
│   │   ├── hdmi_output.c
│   │   └── hdmi_output.h
│   └── platform/
│       ├── platform_config.h
│       └── interrupts.c
```

### 7.2 주요 소스 파일

소스 코드는 별도 파일로 제공됩니다:
- `src/main.c` - 메인 애플리케이션
- `src/camera/ov5640.c` - OV5640 카메라 드라이버
- `src/video/video_capture.c` - 비디오 캡처 관리
- `src/video/video_display.c` - 비디오 출력 관리

---

## Part 8: 테스트 및 디버깅

### 8.1 하드웨어 연결 확인

1. Zynq Z7-20 보드 전원 연결
2. PCAM5C를 PCAM 커넥터에 연결
3. HDMI 케이블로 모니터 연결
4. USB-JTAG 케이블 연결

### 8.2 프로그램 다운로드

1. Vitis에서 **Run** → **Run Configurations**
2. **Xilinx Application Debugger** 선택
3. **Run** 클릭

### 8.3 예상 출력

정상 동작 시 시리얼 터미널 출력:
```
=== Zynq Z7-20 PCAM5C HDMI Output Demo ===
Initializing platform...
Initializing OV5640 camera...
  Camera ID: 0x5640
  Resolution: 1920x1080
  Frame Rate: 30fps
Initializing VDMA...
Starting video capture...
Starting HDMI output...
System running. Press any key to exit.
```

### 8.4 일반적인 문제 해결

| 증상 | 원인 | 해결책 |
|------|------|--------|
| HDMI 신호 없음 | 클럭 설정 오류 | Clocking Wizard 출력 확인 |
| 화면 깨짐 | 타이밍 불일치 | Video Timing Controller 설정 확인 |
| 카메라 인식 안됨 | I2C 연결 문제 | cam_iic 핀 연결 확인 |
| 컬러 이상 | Demosaic 설정 | Bayer 패턴 순서 확인 |
| 프레임 끊김 | VDMA 버퍼 부족 | Frame Buffer 수 증가 |

---

## Part 9: 성능 최적화

### 9.1 메모리 대역폭 최적화

- HP0 포트 사용으로 고대역폭 확보
- Burst Size 최적화 (16 권장)
- Triple Buffering으로 프레임 안정성 확보

### 9.2 지연 시간 최소화

- VDMA Line Buffer 크기 조정
- Video Timing Controller의 FIFO Depth 조정

### 9.3 전력 최적화

- 미사용 클럭 비활성화
- Dynamic Clock Gating 적용

---

## 참고 자료

- [Digilent Zynq Z7 Reference Manual](https://digilent.com/reference/programmable-logic/zynq-7000/reference-manual)
- [PCAM 5C Reference Manual](https://digilent.com/reference/add-ons/pcam-5c/reference-manual)
- [Xilinx Video IP Documentation](https://www.xilinx.com/products/intellectual-property/axi_video_direct_memory_access.html)
- [OV5640 Datasheet](https://cdn.sparkfun.com/datasheets/Sensors/LightImaging/OV5640_datasheet.pdf)

---

## 라이선스

이 프로젝트는 MIT 라이선스를 따릅니다.
