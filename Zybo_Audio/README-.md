# Zybo Z7-20 Audio Codec Projects

Zybo Z7-20 보드의 SSM2603 오디오 코덱을 활용한 3가지 구현 방식을 제공하는 완전한 가이드입니다.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Vivado](https://img.shields.io/badge/Vivado-2021.1-blue)](https://www.xilinx.com/products/design-tools/vivado.html)
[![PetaLinux](https://img.shields.io/badge/PetaLinux-2021.1-green)](https://www.xilinx.com/products/design-tools/embedded-software/petalinux-sdk.html)

## 📋 목차

- [개요](#개요)
- [하드웨어 사양](#하드웨어-사양)
- [프로젝트 구조](#프로젝트-구조)
- [프로젝트 1: FPGA Only 구현](#프로젝트-1-fpga-only-구현)
- [프로젝트 2: PS+PL Vitis 구현](#프로젝트-2-pspl-vitis-구현)
- [프로젝트 3: PetaLinux 드라이버 구현](#프로젝트-3-petalinux-드라이버-구현)
- [빌드 및 실행](#빌드-및-실행)
- [테스트](#테스트)
- [트러블슈팅](#트러블슈팅)
- [참고 자료](#참고-자료)
- [기여하기](#기여하기)
- [라이선스](#라이선스)

## 개요

이 저장소는 Digilent Zybo Z7-20 보드의 SSM2603 오디오 코덱을 사용하는 세 가지 다른 접근 방식을 제공합니다:

1. **Pure PL (FPGA)** 🔧: Verilog HDL만을 사용한 하드웨어 구현
2. **PS+PL (Vitis)** 🚀: Zynq PS의 ARM 프로세서와 PL을 결합한 베어메탈 구현
3. **Linux Driver (PetaLinux)** 🐧: 완전한 ALSA 드라이버와 Linux 통합

### 주요 기능

- ✅ Line In (J7) 스테레오 입력
- ✅ Microphone In (J6) 모노 입력  
- ✅ Headphone Out (J5) 스테레오 출력
- ✅ 실시간 오디오 처리
- ✅ 다양한 오디오 이펙트 (Echo, Reverb, Pitch Shift)
- ✅ 48kHz 샘플링 레이트 지원
- ✅ I2S 오디오 인터페이스
- ✅ I2C 코덱 제어

## 하드웨어 사양

### Zybo Z7-20 보드

- **FPGA**: Xilinx Zynq-7000 XC7Z020-1CLG400C
- **ARM**: Dual-core ARM Cortex-A9 @ 650MHz
- **메모리**: 1GB DDR3, 16MB QSPI Flash
- **오디오 코덱**: Analog Devices SSM2603

### SSM2603 오디오 코덱

| 사양 | 값 |
|------|-----|
| 제조사 | Analog Devices |
| ADC 해상도 | 24-bit |
| DAC 해상도 | 24-bit |
| 샘플레이트 | 8/32/44.1/48/96 kHz |
| I2C 주소 | 0x1A (7-bit) |
| 인터페이스 | I2C (제어), I2S (오디오) |

### 오디오 커넥터

| 커넥터 | 타입 | 색상 | 핀 | 설명 |
|--------|------|------|-----|------|
| J5 | Headphone Out | ⚫ Black | 3.5mm TRS | 스테레오 출력 |
| J6 | Microphone In | 🌸 Pink | 3.5mm TRS | 모노 입력 (with bias) |
| J7 | Line In | 🔵 Light Blue | 3.5mm TRS | 스테레오 입력 |

### 핀 배치

```
I2C Control (PS):
├─ SCL: MIO50
└─ SDA: MIO51

I2S Audio (PL):
├─ MCLK:   T19 (Master Clock - 12MHz)
├─ BCLK:   K18 (Bit Clock)
├─ PBLRC:  L17 (Playback LR Clock)
├─ PBDAT:  M18 (Playback Data)
├─ RECLRC: M17 (Record LR Clock)
└─ RECDAT: K17 (Record Data)
```

## 프로젝트 구조

```
zybo-z7-audio/
├── project1_fpga_only/
│   ├── hdl/
│   │   ├── audio_top.v
│   │   ├── i2c_config.v
│   │   ├── i2s_rx.v
│   │   ├── i2s_tx.v
│   │   └── clk_divider.v
│   ├── constraints/
│   │   └── zybo_z7_audio.xdc
│   ├── scripts/
│   │   └── create_project.tcl
│   └── README.md
│
├── project2_vitis/
│   ├── vivado/
│   │   ├── bd/
│   │   │   └── design_1.tcl
│   │   └── constraints/
│   │       └── zybo_audio.xdc
│   ├── vitis/
│   │   ├── src/
│   │   │   ├── main.c
│   │   │   ├── audio_codec.c
│   │   │   ├── audio_codec.h
│   │   │   └── audio_effects.c
│   │   └── lscript.ld
│   └── README.md
│
├── project3_petalinux/
│   ├── project-spec/
│   │   ├── meta-user/
│   │   │   └── recipes-modules/
│   │   │       └── zybo-audio/
│   │   │           ├── files/
│   │   │           │   ├── zybo_audio.c
│   │   │           │   ├── Makefile
│   │   │           │   └── devicetree.dtsi
│   │   │           └── zybo-audio.bb
│   │   └── configs/
│   │       └── config
│   ├── test_apps/
│   │   ├── audio_test.c
│   │   ├── audio_record.c
│   │   └── audio_playback.c
│   └── README.md
│
├── docs/
│   ├── hardware_setup.md
│   ├── i2c_protocol.md
│   ├── i2s_timing.md
│   └── register_map.md
│
├── images/
│   ├── block_diagram.png
│   ├── timing_diagram.png
│   └── hardware_setup.jpg
│
├── LICENSE
└── README.md
```

## 프로젝트 1: FPGA Only 구현

Pure PL 구현으로 Line In을 받아서 Headphone Out으로 출력하는 오디오 루프백 시스템입니다.

### 특징

- 🔧 순수 Verilog HDL 구현
- 🎯 I2C 마스터를 통한 코덱 초기화
- 🔄 I2S 송수신 모듈
- ⏰ 클럭 생성 및 분주 회로
- 💡 LED를 통한 상태 표시

### 주요 모듈

#### 1. Top Module (`audio_top.v`)
- 전체 시스템 통합
- 클럭 및 리셋 관리
- I2C 및 I2S 인터페이스 연결

#### 2. I2C Configuration (`i2c_config.v`)
- SSM2603 레지스터 설정
- 자동 초기화 시퀀스
- 상태 머신 기반 제어

#### 3. I2S Transceiver (`i2s_rx.v`, `i2s_tx.v`)
- 24-bit 오디오 데이터 처리
- Left/Right 채널 분리
- MSB-first 전송

#### 4. Clock Divider (`clk_divider.v`)
- MCLK: 12MHz (100MHz / 8)
- BCLK: 3.072MHz (MCLK / 4)
- LRCLK: 48kHz (BCLK / 64)

### 빌드 방법

```bash
cd project1_fpga_only

# Vivado 프로젝트 생성
vivado -mode batch -source scripts/create_project.tcl

# GUI에서 열기
vivado audio_loopback/audio_loopback.xpr

# 비트스트림 생성
vivado -mode batch -source scripts/build.tcl
```

### 프로그래밍

```bash
# Hardware Manager로 프로그래밍
open_hw_manager
connect_hw_server
open_hw_target
program_hw_devices [current_hw_device] audio_top.bit
```

### 테스트

1. Line In (J7)에 오디오 소스 연결
2. Headphone (J5)에 헤드폰 연결
3. 비트스트림 다운로드
4. LED 확인:
   - LED[0]: I2C 설정 완료
   - LED[1]: 오디오 데이터 수신 중
   - LED[2]: LR 클럭 토글
   - LED[3]: 오디오 신호 감지

## 프로젝트 2: PS+PL Vitis 구현

PS의 I2C와 DMA를 활용한 고성능 오디오 처리 시스템입니다.

### 특징

- 🚀 ARM 프로세서 활용
- 📊 DMA 기반 고속 데이터 전송
- 🎵 실시간 오디오 이펙트 처리
- 🎛️ 인터럽트 기반 버퍼 관리
- 🔘 버튼으로 이펙트 전환

### 아키텍처

```
┌─────────────────────────────────────────────────────┐
│                    Zynq PS                          │
│  ┌──────────┐    ┌─────────┐    ┌──────────┐      │
│  │  ARM A9  │────│   DMA   │────│  HP0 AXI │──────┼──> PL
│  └──────────┘    └─────────┘    └──────────┘      │
│       │                                             │
│  ┌────▼────┐                                       │
│  │   I2C   │───────────────────────────────────────┼──> SSM2603
│  └─────────┘                                       │
└─────────────────────────────────────────────────────┘
                        │
                        ▼
┌─────────────────────────────────────────────────────┐
│                    PL (FPGA)                        │
│  ┌──────────────┐    ┌──────────────┐             │
│  │ I2S RX Core  │────│ AXI Stream   │──> DMA      │
│  └──────────────┘    └──────────────┘             │
│  ┌──────────────┐    ┌──────────────┐             │
│  │ I2S TX Core  │────│ AXI Stream   │<── DMA      │
│  └──────────────┘    └──────────────┘             │
└─────────────────────────────────────────────────────┘
```

### 오디오 이펙트

| 모드 | 버튼 | 설명 |
|------|------|------|
| Passthrough | BTN0 | 입력을 그대로 출력 |
| Echo | BTN1 | 500ms 딜레이 에코 효과 |
| Reverb | BTN2 | Comb 필터 기반 리버브 |
| Pitch Shift | BTN3 | 1.5배 피치 시프트 |

### 빌드 방법

```bash
cd project2_vitis

# 1. Vivado에서 하드웨어 디자인 생성
cd vivado
vivado -mode batch -source create_bd.tcl

# 2. Export hardware
# File > Export > Export Hardware (Include Bitstream)

# 3. Vitis 워크스페이스 생성
vitis -workspace ../vitis_workspace

# 4. 플랫폼 생성
# File > New > Platform Project
# Import XSA file

# 5. 애플리케이션 생성
# File > New > Application Project
```

### 실행

```bash
# JTAG으로 다운로드
program_flash -f BOOT.bin -offset 0 -flash_type qspi-x4-single

# 또는 SD 카드 부팅
# BOOT.bin을 SD 카드에 복사
```

## 프로젝트 3: PetaLinux 드라이버 구현

ALSA 드라이버를 통한 Linux 오디오 시스템 통합입니다.

### 특징

- 🐧 완전한 Linux 통합
- 🎵 ALSA 프레임워크 지원
- 🔌 표준 오디오 애플리케이션 호환
- 📝 Device Tree 기반 설정
- 🛠️ 커널 모듈 드라이버

### 소프트웨어 스택

```
┌─────────────────────────────────────┐
│      User Space Applications        │
│  ┌──────────┐  ┌──────────────┐    │
│  │ aplay    │  │ arecord      │    │
│  └────┬─────┘  └──────┬───────┘    │
│       │                │             │
│  ┌────▼────────────────▼────────┐   │
│  │      ALSA Library (libasound)│   │
│  └────────────┬─────────────────┘   │
└───────────────┼─────────────────────┘
                │
┌───────────────▼─────────────────────┐
│         Kernel Space                │
│  ┌─────────────────────────────┐   │
│  │     ALSA Core (snd_pcm)     │   │
│  └──────────┬──────────────────┘   │
│             │                       │
│  ┌──────────▼──────────────────┐   │
│  │   Zybo Audio Driver         │   │
│  │   (zybo_audio.ko)           │   │
│  └──────────┬──────────────────┘   │
│             │                       │
│  ┌──────────▼──────────────────┐   │
│  │   I2C Subsystem (i2c_core)  │   │
│  └─────────────────────────────┘   │
└─────────────────────────────────────┘
                │
                ▼
         SSM2603 Hardware
```

### PetaLinux 프로젝트 생성

```bash
# PetaLinux 프로젝트 생성
petalinux-create -t project -n zybo_audio --template zynq
cd zybo_audio

# Hardware 설정 import
petalinux-config --get-hw-description=../project2_vitis/vivado

# Kernel 설정
petalinux-config -c kernel
# Device Drivers > Sound card support > Advanced Linux Sound Architecture 활성화

# RootFS 설정
petalinux-config -c rootfs
# Filesystem Packages > misc > alsa-utils 활성화

# 커널 모듈 추가
petalinux-create -t modules --name zybo-audio --enable

# 빌드
petalinux-build

# SDK 생성
petalinux-build --sdk
petalinux-package --sysroot
```

### Device Tree 설정

```dts
&i2c0 {
    status = "okay";
    clock-frequency = <100000>;
    
    ssm2603: ssm2603@1a {
        compatible = "adi,ssm2603";
        reg = <0x1a>;
        #sound-dai-cells = <0>;
    };
};

/ {
    sound {
        compatible = "simple-audio-card";
        simple-audio-card,name = "Zybo-Z7-Audio";
        simple-audio-card,format = "i2s";
        simple-audio-card,bitclock-master = <&dailink_master>;
        simple-audio-card,frame-master = <&dailink_master>;
        
        simple-audio-card,cpu {
            sound-dai = <&i2s_controller>;
        };
        
        dailink_master: simple-audio-card,codec {
            sound-dai = <&ssm2603>;
            clocks = <&clkc 15>;
        };
    };
};
```

### 테스트 애플리케이션 빌드

```bash
# SDK 환경 설정
source /opt/petalinux/2021.1/environment-setup-cortexa9t2hf-neon-xilinx-linux-gnueabi

# 테스트 앱 컴파일
cd test_apps
$CC -o audio_test audio_test.c -lasound
$CC -o audio_record audio_record.c -lasound
$CC -o audio_playback audio_playback.c -lasound

# 빌드된 바이너리를 RootFS에 복사
cp audio_test ../images/linux/rootfs/usr/bin/
cp audio_record ../images/linux/rootfs/usr/bin/
cp audio_playback ../images/linux/rootfs/usr/bin/

# 다시 패키징
petalinux-build
```

### SD 카드 이미지 생성

```bash
# BOOT.bin 생성
petalinux-package --boot \
    --fsbl images/linux/zynq_fsbl.elf \
    --fpga images/linux/system.bit \
    --u-boot \
    --force

# SD 카드 파티션 준비
# 파티션 1: FAT32 (BOOT)
# 파티션 2: ext4 (RootFS)

# 파일 복사
cp images/linux/BOOT.bin /media/BOOT/
cp images/linux/boot.scr /media/BOOT/
cp images/linux/image.ub /media/BOOT/

sudo tar xvf images/linux/rootfs.tar.gz -C /media/rootfs/
sync
```

## 빌드 및 실행

### 필수 요구사항

#### 소프트웨어
- **Vivado Design Suite** 2021.1 이상
- **Vitis** 2021.1 이상 (프로젝트 2)
- **PetaLinux Tools** 2021.1 이상 (프로젝트 3)
- **Python** 3.6 이상 (스크립트 실행용)

#### 하드웨어
- Digilent Zybo Z7-20 보드
- Micro USB 케이블 (UART, JTAG)
- Micro SD 카드 (8GB 이상, 프로젝트 3)
- 3.5mm 오디오 케이블
- 오디오 소스 (스마트폰, MP3 플레이어 등)
- 헤드폰 또는 스피커

### 빠른 시작

```bash
# 저장소 클론
git clone https://github.com/yourusername/zybo-z7-audio.git
cd zybo-z7-audio

# 프로젝트 선택
cd project1_fpga_only  # 또는 project2_vitis, project3_petalinux

# 각 프로젝트의 README.md 참조
```

### 환경 설정

```bash
# Xilinx 툴 환경 변수 설정
source /tools/Xilinx/Vivado/2021.1/settings64.sh
source /tools/Xilinx/Vitis/2021.1/settings64.sh  # Vitis 사용 시
source /tools/Xilinx/PetaLinux/2021.1/settings.sh  # PetaLinux 사용 시

# 환경 확인
vivado -version
vitis -version
petalinux-util --version
```

## 테스트

### 프로젝트 1 (FPGA Only) 테스트

```bash
# 1. 비트스트림 프로그래밍
vivado -mode tcl
open_hw_manager
connect_hw_server
open_hw_target
program_hw_devices [current_hw_device] audio_top.bit

# 2. 하드웨어 연결
# - Line In (J7)에 오디오 소스 연결
# - Headphone (J5)에 헤드폰 연결

# 3. LED 확인
# - LED0: I2C 초기화 완료 (항상 켜짐)
# - LED1: 오디오 데이터 수신 (깜박임)
# - LED2: LR 클럭 (빠른 깜박임)
# - LED3: 오디오 레벨 감지
```

### 프로젝트 2 (Vitis) 테스트

```bash
# 1. 애플리케이션 실행 (Vitis IDE에서)
# Run > Run Configurations > Xilinx C/C++ Application
# Run 클릭

# 2. 시리얼 터미널 확인
screen /dev/ttyUSB1 115200

# 예상 출력:
# === Zybo Z7-20 Audio Codec Demo ===
# Audio codec initialized
# Starting audio processing...
# Press buttons to change effects:
#   BTN0: Passthrough
#   BTN1: Echo
#   BTN2: Reverb
#   BTN3: Pitch Shift

# 3. 이펙트 테스트
# - BTN0 누름: 원본 오디오 출력
# - BTN1 누름: 에코 효과 적용
# - BTN2 누름: 리버브 효과 적용
# - BTN3 누름: 피치 시프트 적용
```

### 프로젝트 3 (PetaLinux) 테스트

```bash
# 1. 보드 부팅 (시리얼 콘솔)
screen /dev/ttyUSB1 115200

# 2. 로그인
# Login: root
# Password: root

# 3. 드라이버 확인
root@zybo:~# dmesg | grep -i audio
[    5.123] Zybo audio driver registered successfully
[    5.456] SSM2603 codec initialized

# 4. ALSA 디바이스 확인
root@zybo:~# aplay -l
**** List of PLAYBACK Hardware Devices ****
card 0: Zybo [Zybo Z7 Audio], device 0: Zybo PCM [Zybo PCM]
  Subdevices: 1/1
  Subdevice #0: subdevice #0

root@zybo:~# arecord -l
**** List of CAPTURE Hardware Devices ****
card 0: Zybo [Zybo Z7 Audio], device 0: Zybo PCM [Zybo PCM]
  Subdevices: 1/1
  Subdevice #0: subdevice #0

# 5. 오디오 루프백 테스트
root@zybo:~# ./audio_test
=== Zybo Z7 Audio Test ===
Audio loopback started (Ctrl+C to stop)
Line In → Headphone Out

# 6. 녹음 테스트 (10초)
root@zybo:~# ./audio_record recording.raw
Recording 10 seconds of audio...
Recording complete

# 7. 재생 테스트
root@zybo:~# ./audio_playback recording.raw
Playing audio file: recording.raw
Playback complete

# 8. ALSA 명령어 사용
# 녹음
root@zybo:~# arecord -f S16_LE -r 48000 -c 2 -d 5 test.wav

# 재생
root@zybo:~# aplay test.wav

# 볼륨 조절
root@zybo:~# alsamixer
# 화살표 키로 볼륨 조절, ESC로 종료

# 9. 마이크 입력 테스트 (J6)
root@zybo:~# amixer sset 'Mic' 80%
root@zybo:~# amixer sset 'Mic Boost' 1
root@zybo:~# arecord -f S16_LE -r 48000 -c 1 -d 5 mic_test.wav
root@zybo:~# aplay mic_test.wav
```

### 성능 측정

```bash
# 레이턴시 측정 (프로젝트 3)
root@zybo:~# cat /proc/asound/card0/pcm0p/sub0/hw_params
access: RW_INTERLEAVED
format: S16_LE
subformat: STD
channels: 2
rate: 48000 (48000/1)
period_size: 1024
buffer_size: 4096

# 버퍼 레이턴시: 4096 / 48000 ≈ 85ms

# CPU 사용률 확인
root@zybo:~# top
# audio_test 프로세스 CPU 사용률 확인

# 오디오 품질 테스트
root@zybo:~# speaker-test -c 2 -r 48000 -f 440
# 440Hz 사인파 생성 (좌/우 채널 테스트)
```

## 트러블슈팅

### 일반적인 문제

#### 1. 오디오가 출력되지 않음

**증상**: Headphone Out에서 소리가 들리지 않음

**해결 방법**:
```bash
# I2C 통신 확인
i2cdetect -y 0
#      0  1  2  3  4  5  6  7  8  9  a  b  c  d  e  f
# 00:          -- -- -- -- -- -- -- -- -- -- -- -- --
# 10: -- -- -- -- -- -- -- -- -- -- 1a -- -- -- -- --
# 1a 위치에 디바이스가 보여야 함

# SSM2603 레지스터 읽기
i2cget -y 0 0x1a 0x09  # Active Register
# 0x01이 반환되어야 함 (활성화 상태)

# 볼륨 설정 확인 (PetaLinux)
amixer contents
# 'Headphone Playback Volume' 확인

# 볼륨 증가
amixer sset 'Headphone' 100%
```

#### 2. 노이즈가 심함

**증상**: 출력 오디오에 잡음이 많음

**원인 및 해결**:
1. **MCLK 주파수 확인**
   ```verilog
   // clk_divider.v에서 확인
   // MCLK = 100MHz / 8 = 12.5MHz (12MHz 목표)
   // 더 정확한 분주 필요
   ```

2. **그라운드 연결 확인**
   - 보드와 오디오 소스의 그라운드 연결 확인
   - 전원 노이즈 확인

3. **샘플레이트 미스매치**
   ```c
   // SSM2603 샘플레이트 레지스터 확인
   regmap_write(regmap, SSM2603_SRATE, 0x00);  // 48kHz
   ```

4. **버퍼 언더런/오버런**
   ```bash
   # ALSA 버퍼 상태 확인
   cat /proc/asound/card0/pcm0p/sub0/status
   
   # 버퍼 크기 증가
   aplay -B 8000 test.wav  # 8000 usec 버퍼
   ```

#### 3. I2C 통신 실패

**증상**: I2C 초기화 실패, LED0이 켜지지 않음

**해결 방법**:
```bash
# I2C 버스 스캔
i2cdetect -y 0

# SCL/SDA 핀 확인
cat /sys/kernel/debug/pinctrl/700-pinctrl/pins | grep -E "pin 50|pin 51"

# I2C 클럭 속도 확인/변경
# Device Tree에서:
&i2c0 {
    clock-frequency = <100000>;  # 100kHz로 낮춤
};

# I2C 버스 리셋
echo 0 > /sys/class/i2c-adapter/i2c-0/delete_device
echo 1 > /sys/class/i2c-adapter/i2c-0/new_device
```

#### 4. DMA 전송 오류 (프로젝트 2)

**증상**: DMA 인터럽트가 발생하지 않음

**해결 방법**:
```c
// 1. 메모리 정렬 확인
int32_t rx_buffer[BUFFER_SIZE] __attribute__((aligned(32)));

// 2. 캐시 일관성 확인
Xil_DCacheFlushRange((UINTPTR)buffer, size);
Xil_DCacheInvalidateRange((UINTPTR)buffer, size);

// 3. DMA 상태 확인
u32 status = XAxiDma_ReadReg(DMA_BASEADDR, XAXIDMA_SR_OFFSET);
xil_printf("DMA Status: 0x%08x\n", status);

// 4. 인터럽트 우선순위 확인
XScuGic_SetPriorityTriggerType(&IntcInstance, RX_INTR_ID, 0xA0, 0x3);
```

#### 5. 커널 모듈 로드 실패 (프로젝트 3)

**증상**: `insmod zybo_audio.ko` 실패

**해결 방법**:
```bash
# 커널 로그 확인
dmesg | tail -20

# 모듈 의존성 확인
modinfo zybo_audio.ko

# 심볼 테이블 확인
cat /proc/kallsyms | grep snd_

# Device Tree 확인
dtc -I fs /proc/device-tree > current.dts
cat current.dts | grep -A 20 "sound"

# 수동 디바이스 등록
echo "ssm2603 0x1a" > /sys/bus/i2c/devices/i2c-0/new_device
```

#### 6. 오디오 끊김 현상

**증상**: 재생 중 주기적으로 끊김

**해결 방법**:
```bash
# 1. CPU 부하 확인
top -d 1

# 2. 인터럽트 통계 확인
cat /proc/interrupts

# 3. 버퍼 크기 증가
# ALSA 설정 파일 수정 (/etc/asound.conf)
pcm.!default {
    type hw
    card 0
    device 0
}

ctl.!default {
    type hw
    card 0
}

defaults.pcm.dmix.period_time 80000
defaults.pcm.dmix.periods 4

# 4. 리얼타임 우선순위 설정
chrt -f 50 aplay test.wav

# 5. IRQ affinity 설정 (멀티코어)
echo 2 > /proc/irq/XX/smp_affinity  # XX는 DMA IRQ 번호
```

### 하드웨어 디버깅

#### ILA (Integrated Logic Analyzer) 추가

```tcl
# Vivado TCL Console
create_ip -name ila -vendor xilinx.com -library ip -version 6.2 -module_name ila_0

set_property -dict [list \
    CONFIG.C_NUM_OF_PROBES {8} \
    CONFIG.C_PROBE0_WIDTH {24} \
    CONFIG.C_PROBE1_WIDTH {24} \
    CONFIG.C_PROBE2_WIDTH {1} \
] [get_ips ila_0]

# 프로브 연결
connect_debug_port u_ila_0/probe0 [get_nets {i2s_rx_inst/rx_left[*]}]
connect_debug_port u_ila_0/probe1 [get_nets {i2s_rx_inst/rx_right[*]}]
connect_debug_port u_ila_0/probe2 [get_nets {i2s_rx_inst/rx_valid}]
```

#### ChipScope 사용

```bash
# Vivado Hardware Manager
open_hw_manager
connect_hw_server
open_hw_target
set_property PROBES.FILE {debug_nets.ltx} [current_hw_device]
refresh_hw_device [current_hw_device]

# Trigger 설정
# rx_valid == 1에서 트리거
```

### 추가 디버깅 팁

```bash
# 시스템 로그 모니터링
tail -f /var/log/messages

# ALSA 디버그 활성화
echo 255 > /proc/asound/card0/oss_mixer

# I2S 신호 확인 (오실로스코프)
# BCLK: 3.072MHz 스퀘어 웨이브
# LRCLK: 48kHz 스퀘어 웨이브
# DATA: 변화하는 디지털 신호

# 스펙트럼 분석
ffmpeg -f alsa -i hw:0 -f wav - | sox -t wav - -n spectrogram
```

## 참고 자료

### 공식 문서

#### Digilent
- [Zybo Z7 Reference Manual](https://digilent.com/reference/programmable-logic/zybo-z7/reference-manual)
- [Zybo Z7 Schematic](https://digilent.com/reference/_media/reference/programmable-logic/zybo-z7/zybo-z7_sch.pdf)
- [Zybo Z7 Master XDC](https://github.com/Digilent/digilent-xdc/blob/master/Zybo-Z7-Master.xdc)

#### Analog Devices
- [SSM2603 Datasheet](https://www.analog.com/media/en/technical-documentation/data-sheets/SSM2603.pdf)
- [SSM2603 User Guide](https://www.analog.com/media/en/technical-documentation/user-guides/UG-169.pdf)
- [SSM2603 Evaluation Board](https://www.analog.com/en/design-center/evaluation-hardware-and-software/evaluation-boards-kits/EVAL-SSM2603.html)

#### Xilinx
- [Zynq-7000 Technical Reference Manual (UG585)](https://www.xilinx.com/support/documentation/user_guides/ug585-Zynq-7000-TRM.pdf)
- [Vivado Design Suite User Guide (UG893)](https://www.xilinx.com/support/documentation/sw_manuals/xilinx2021_1/ug893-vivado-ip.pdf)
- [Vitis Unified Software Platform (UG1400)](https://www.xilinx.com/support/documentation/sw_manuals/xilinx2021_1/ug1400-vitis-embedded.pdf)
- [PetaLinux Tools Reference Guide (UG1144)](https://www.xilinx.com/support/documentation/sw_manuals/xilinx2021_1/ug1144-petalinux-tools-reference-guide.pdf)

### 프로토콜 사양

#### I2C
- [I2C Bus Specification](https://www.nxp.com/docs/en/user-guide/UM10204.pdf)
- [Understanding the I2C Bus](https://www.ti.com/lit/an/slva704/slva704.pdf)

#### I2S
- [I2S Bus Specification](https://www.sparkfun.com/datasheets/BreakoutBoards/I2SBUS.pdf)
- [Philips I2S Specification](https://www.nxp.com/docs/en/user-manual/UM10732.pdf)

### ALSA (Advanced Linux Sound Architecture)

- [ALSA Project](https://www.alsa-project.org/)
- [ALSA Driver API](https://www.kernel.org/doc/html/latest/sound/kernel-api/index.html)
- [Writing an ALSA Driver](https://www.kernel.org/doc/html/latest/sound/kernel-api/writing-an-alsa-driver.html)
- [ALSA Programming Tutorial](https://www.linuxjournal.com/article/6735)

### 예제 프로젝트

- [Digilent Zybo Z7 Audio Demo](https://github.com/Digilent/Zybo-Z7-20-pcam-5c)
- [Xilinx Audio Example Designs](https://github.com/Xilinx/linux-xlnx/tree/master/sound/soc/adi)
- [Linux SSM2602 Driver](https://github.com/torvalds/linux/blob/master/sound/soc/codecs/ssm2602.c)

### 유용한 툴

- [PulseView (Logic Analyzer)](https://sigrok.org/wiki/PulseView)
- [Audacity (Audio Editor)](https://www.audacityteam.org/)
- [sox (Sound eXchange)](http://sox.sourceforge.net/)
- [FFmpeg](https://ffmpeg.org/)

### 커뮤니티 및 포럼

- [Digilent Forum](https://forum.digilentinc.com/)
- [Xilinx Community](https://support.xilinx.com/s/topic/0TO2E000000YKYAWA4/programmable-devices)
- [ALSA Mailing List](https://www.alsa-project.org/wiki/MailingLists)
- [Stack Overflow - FPGA](https://stackoverflow.com/questions/tagged/fpga)

### 튜토리얼 및 블로그

- [FPGA Audio Processing Tutorial](https://www.youtube.com/watch?v=example)
- [Zynq SoC Development](https://www.element14.com/community/docs/DOC-76452)
- [Linux Device Driver Tutorial](https://linux-kernel-labs.github.io/refs/heads/master/labs/device_drivers.html)

### 관련 응용 분야

- [Digital Audio Workstation (DAW)](https://wiki.linuxaudio.org/)
- [SDR (Software Defined Radio)](https://www.gnuradio.org/)
- [Real-time Audio Effects](https://github.com/topics/audio-effects)
- [Voice Processing](https://github.com/topics/voice-recognition)

## 기여하기

이 프로젝트에 기여하고 싶으신가요? 환영합니다! 🎉

### 기여 방법

1. **Fork** 이 저장소
2. **Feature branch** 생성 (`git checkout -b feature/AmazingFeature`)
3. **Commit** 변경사항 (`git commit -m 'Add some AmazingFeature'`)
4. **Push** to the branch (`git push origin feature/AmazingFeature`)
5. **Pull Request** 열기

### 기여 가이드라인

#### 코드 스타일

**Verilog/SystemVerilog**
```verilog
// 2-space indentation
// Snake_case for signals
// PascalCase for modules
module AudioProcessor (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [23:0] audio_in,
    output reg  [23:0] audio_out
);
```

**C/C++**
```c
// 4-space indentation
// snake_case for functions
// UPPER_CASE for macros
int process_audio_buffer(int32_t *buffer, size_t length)
{
    // Implementation
}
```

**Python**
```python
# PEP 8 style guide
# 4-space indentation
def generate_test_pattern(frequency, duration):
    """Generate audio test pattern.
    
    Args:
        frequency: Frequency in Hz
        duration: Duration in seconds
    """
    pass
```

#### 커밋 메시지

```
feat: Add echo effect implementation
fix: Resolve I2C timeout issue
docs: Update hardware setup guide
test: Add unit tests for audio effects
refactor: Improve DMA buffer management
```

#### Pull Request 체크리스트

- [ ] 코드가 스타일 가이드를 따름
- [ ] 테스트를 추가/업데이트함
- [ ] 문서를 업데이트함
- [ ] 빌드가 성공함
- [ ] 하드웨어에서 테스트 완료

### 이슈 리포팅

버그를 발견하셨나요? [이슈를 생성](https://github.com/yourusername/zybo-z7-audio/issues)해 주세요.

**이슈 템플릿**:
```markdown
## 설명
문제에 대한 명확한 설명

## 재현 방법
1. '...'로 이동
2. '...' 클릭
3. '...'까지 스크롤
4. 오류 확인

## 예상 동작
예상했던 결과

## 실제 동작
실제로 발생한 결과

## 환경
- 보드: Zybo Z7-20
- Vivado 버전: 2021.1
- OS: Ubuntu 20.04
- 프로젝트: project2_vitis

## 추가 정보
스크린샷, 로그 등
```

### 기능 요청

새로운 기능을 제안하고 싶으신가요?

1. [Discussions](https://github.com/yourusername/zybo-z7-audio/discussions)에서 아이디어 공유
2. 커뮤니티 피드백 수집
3. 구현 계획 작성
4. Pull Request 제출

### 개발 환경 설정

```bash
# 저장소 클론
git clone https://github.com/yourusername/zybo-z7-audio.git
cd zybo-z7-audio

# 개발 브랜치 생성
git checkout -b dev/my-feature

# pre-commit hook 설치 (선택사항)
pip install pre-commit
pre-commit install

# 테스트 실행
./scripts/run_tests.sh
```

## 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다. 자세한 내용은 [LICENSE](LICENSE) 파일을 참조하세요.

```
MIT License

Copyright (c) 2024 [Your Name]

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## 감사의 말

이 프로젝트는 다음의 도움으로 만들어졌습니다:

- **Digilent Inc.** - Zybo Z7 보드 및 참조 디자인
- **Analog Devices** - SSM2603 코덱 문서
- **Xilinx** - 개발 툴 및 문서
- **ALSA 프로젝트** - Linux 오디오 프레임워크
- **오픈소스 커뮤니티** - 수많은 예제와 조언

---

## 연락처

프로젝트 관리자: **나무** (Namoo)

- GitHub: [@yourusername](https://github.com/yourusername)
- Email: your.email@example.com
- 블로그: https://yourblog.com

프로젝트 링크: [https://github.com/yourusername/zybo-z7-audio](https://github.com/yourusername/zybo-z7-audio)

---

## 변경 이력

### v1.0.0 (2024-02-11)
- ✨ 초기 릴리즈
- ✅ 프로젝트 1: FPGA Only 구현 완료
- ✅ 프로젝트 2: PS+PL Vitis 구현 완료
- ✅ 프로젝트 3: PetaLinux 드라이버 구현 완료
- 📝 완전한 문서화

### Roadmap

#### v1.1.0 (계획)
- [ ] USB Audio 클래스 지원
- [ ] 추가 오디오 이펙트 (Chorus, Flanger)
- [ ] 웹 기반 GUI 제어
- [ ] MIDI 인터페이스 지원

#### v2.0.0 (계획)
- [ ] 멀티채널 오디오 (4채널, 8채널)
- [ ] 고해상도 오디오 (24-bit/96kHz, 192kHz)
- [ ] DSP 가속 (FFT, FIR 필터)
- [ ] Bluetooth 오디오 지원

---

<div align="center">

**이 프로젝트가 도움이 되셨다면 ⭐️ Star를 눌러주세요!**

Made with ❤️ by embedded systems enthusiasts

</div>
