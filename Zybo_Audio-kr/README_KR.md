# Zybo Z7-20 오디오 코덱 프로젝트

Zybo Z7-20 보드의 SSM2603 오디오 코덱을 활용한 3가지 구현 방식을 제공하는 완전한 가이드입니다.

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Vivado](https://img.shields.io/badge/Vivado-2021.1-blue)](https://www.xilinx.com/products/design-tools/vivado.html)
[![PetaLinux](https://img.shields.io/badge/PetaLinux-2021.1-green)](https://www.xilinx.com/products/design-tools/embedded-software/petalinux-sdk.html)

## 📋 목차

- [개요](#개요)
- [하드웨어 사양](#하드웨어-사양)
- [프로젝트 구조](#프로젝트-구조)
- [프로젝트 1: FPGA 전용 구현](#프로젝트-1-fpga-전용-구현)
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

1. **순수 PL (FPGA)** 🔧: Verilog HDL만을 사용한 하드웨어 구현
2. **PS+PL (Vitis)** 🚀: Zynq PS의 ARM 프로세서와 PL을 결합한 베어메탈 구현
3. **Linux 드라이버 (PetaLinux)** 🐧: 완전한 ALSA 드라이버와 Linux 통합

### 주요 기능

- ✅ Line In (J7) 스테레오 입력
- ✅ Microphone In (J6) 모노 입력  
- ✅ Headphone Out (J5) 스테레오 출력
- ✅ 실시간 오디오 처리
- ✅ 다양한 오디오 이펙트 (에코, 리버브, 피치 시프트)
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
| J6 | Microphone In | 🌸 Pink | 3.5mm TRS | 모노 입력 (바이어스 포함) |
| J7 | Line In | 🔵 Light Blue | 3.5mm TRS | 스테레오 입력 |

### 핀 배치

```
I2C 제어 (PS):
├─ SCL: MIO50
└─ SDA: MIO51

I2S 오디오 (PL):
├─ MCLK:   T19 (마스터 클럭 - 12MHz)
├─ BCLK:   K18 (비트 클럭)
├─ PBLRC:  L17 (재생 LR 클럭)
├─ PBDAT:  M18 (재생 데이터)
├─ RECLRC: M17 (녹음 LR 클럭)
└─ RECDAT: K17 (녹음 데이터)
```

## 프로젝트 구조

```
zybo-z7-audio/
├── project1_fpga_only/           # 프로젝트 1: FPGA 전용
│   ├── hdl/                      # Verilog HDL 소스
│   │   ├── audio_top.v           # 최상위 모듈
│   │   ├── i2c_config.v          # I2C 설정
│   │   ├── i2s_rx.v              # I2S 수신기
│   │   ├── i2s_tx.v              # I2S 송신기
│   │   └── clk_divider.v         # 클럭 분주기
│   ├── constraints/              # 제약 조건 파일
│   │   └── zybo_z7_audio.xdc     # 핀 배치
│   ├── scripts/                  # 빌드 스크립트
│   │   └── create_project.tcl    # Vivado 프로젝트 생성
│   └── README.md                 # 프로젝트 문서
│
├── project2_vitis/               # 프로젝트 2: PS+PL
│   ├── vivado/                   # Vivado 설계
│   │   ├── bd/                   # 블록 디자인
│   │   │   └── design_1.tcl      # BD 생성 스크립트
│   │   └── constraints/          # 제약 조건
│   │       └── zybo_audio.xdc    # 핀 배치
│   ├── vitis/                    # Vitis 애플리케이션
│   │   ├── src/                  # C 소스 코드
│   │   │   ├── main.c            # 메인 프로그램
│   │   │   ├── audio_codec.c     # 코덱 드라이버
│   │   │   ├── audio_codec.h     # 헤더 파일
│   │   │   └── audio_effects.c   # 오디오 이펙트
│   │   └── lscript.ld            # 링커 스크립트
│   └── README.md                 # 프로젝트 문서
│
├── project3_petalinux/           # 프로젝트 3: Linux 드라이버
│   ├── project-spec/             # PetaLinux 설정
│   │   ├── meta-user/            # 사용자 레시피
│   │   │   └── recipes-modules/  # 커널 모듈
│   │   │       └── zybo-audio/   # 오디오 드라이버
│   │   │           ├── files/    # 소스 파일
│   │   │           │   ├── zybo_audio.c      # 드라이버 소스
│   │   │           │   ├── Makefile          # 빌드 파일
│   │   │           │   └── devicetree.dtsi   # 디바이스 트리
│   │   │           └── zybo-audio.bb         # BitBake 레시피
│   │   └── configs/              # 설정 파일
│   │       └── config            # 커널 설정
│   ├── test_apps/                # 테스트 애플리케이션
│   │   ├── audio_test.c          # 루프백 테스트
│   │   ├── audio_record.c        # 녹음 프로그램
│   │   └── audio_playback.c      # 재생 프로그램
│   └── README.md                 # 프로젝트 문서
│
├── docs/                         # 문서
│   ├── hardware_setup.md         # 하드웨어 설정 가이드
│   ├── i2c_protocol.md           # I2C 프로토콜 설명
│   ├── i2s_timing.md             # I2S 타이밍 다이어그램
│   └── register_map.md           # 레지스터 맵
│
├── images/                       # 이미지 및 다이어그램
│   ├── block_diagram.png         # 블록 다이어그램
│   ├── timing_diagram.png        # 타이밍 다이어그램
│   └── hardware_setup.jpg        # 하드웨어 사진
│
├── LICENSE                       # MIT 라이선스
└── README.md                     # 프로젝트 메인 문서
```

## 프로젝트 1: FPGA 전용 구현

Line In에서 받은 오디오를 Headphone Out으로 출력하는 순수 PL 루프백 시스템입니다.

### 특징

- 🔧 순수 Verilog HDL 구현
- 🎯 I2C 마스터를 통한 코덱 초기화
- 🔄 I2S 송수신 모듈
- ⏰ 클럭 생성 및 분주 회로
- 💡 LED를 통한 상태 표시

### 주요 모듈

#### 1. 최상위 모듈 (`audio_top.v`)
- 전체 시스템 통합
- 클럭 및 리셋 관리
- I2C 및 I2S 인터페이스 연결

#### 2. I2C 설정 (`i2c_config.v`)
- SSM2603 레지스터 설정
- 자동 초기화 시퀀스
- 상태 머신 기반 제어

#### 3. I2S 송수신기 (`i2s_rx.v`, `i2s_tx.v`)
- 24-bit 오디오 데이터 처리
- 좌/우 채널 분리
- MSB-first 전송

#### 4. 클럭 분주기 (`clk_divider.v`)
- MCLK: 12MHz (100MHz / 8)
- BCLK: 3.072MHz (MCLK / 4)
- LRCLK: 48kHz (BCLK / 64)

### 빌드 방법

#### 방법 1: TCL 스크립트 사용

```bash
cd project1_fpga_only/scripts
vivado -mode batch -source create_project.tcl
```

#### 방법 2: 수동 생성

1. Vivado 실행
2. 새 프로젝트 생성
3. Zybo Z7-20 보드 선택
4. `hdl/` 디렉토리의 모든 HDL 파일 추가
5. `constraints/`의 제약 조건 파일 추가
6. `audio_top`을 최상위 모듈로 설정
7. 비트스트림 생성

### FPGA 프로그래밍

#### Hardware Manager 사용

```tcl
open_hw_manager
connect_hw_server
open_hw_target
current_hw_device [get_hw_devices xc7z020_1]
set_property PROGRAM.FILE {경로/audio_top.bit} [get_hw_devices xc7z020_1]
program_hw_devices [get_hw_devices xc7z020_1]
```

### 테스트

1. Line In (J7 - 하늘색)에 오디오 소스 연결
2. Headphone (J5 - 검정색)에 헤드폰 연결
3. FPGA에 비트스트림 다운로드
4. LED 상태 확인:
   - **LED[0]**: I2C 설정 완료 (항상 켜짐)
   - **LED[1]**: 오디오 데이터 수신 중 (깜박임)
   - **LED[2]**: LR 클럭 동작 (빠른 깜박임 - 48kHz)
   - **LED[3]**: 오디오 레벨 표시

## 프로젝트 2: PS+PL Vitis 구현

PS의 I2C와 DMA를 활용한 고성능 오디오 처리 시스템입니다.

### 특징

- 🚀 ARM 프로세서 활용
- 📊 DMA 기반 고속 데이터 전송
- 🎵 실시간 오디오 이펙트 처리
- 🎛️ 인터럽트 기반 버퍼 관리
- 🔘 버튼으로 이펙트 전환

### 시스템 구조

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
│  │ I2S RX 코어  │────│ AXI Stream   │──> DMA      │
│  └──────────────┘    └──────────────┘             │
│  ┌──────────────┐    ┌──────────────┐             │
│  │ I2S TX 코어  │────│ AXI Stream   │<── DMA      │
│  └──────────────┘    └──────────────┘             │
└─────────────────────────────────────────────────────┘
```

### 오디오 이펙트

| 모드 | 버튼 | 설명 |
|------|------|------|
| 패스스루 | BTN0 | 입력을 그대로 출력 |
| 에코 | BTN1 | 500ms 딜레이 에코 효과 |
| 리버브 | BTN2 | Comb 필터 기반 리버브 |
| 피치 시프트 | BTN3 | 1.5배 피치 변조 |

### 빌드 방법

```bash
cd project2_vitis

# 1. Vivado에서 하드웨어 디자인 생성
cd vivado
vivado -mode batch -source create_bd.tcl

# 2. 하드웨어 내보내기
# File > Export > Export Hardware (비트스트림 포함)

# 3. Vitis 워크스페이스 생성
vitis -workspace ../vitis_workspace

# 4. 플랫폼 생성
# File > New > Platform Project
# XSA 파일 임포트

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

ALSA 드라이버를 통한 Linux 오디오 시스템 완전 통합입니다.

### 특징

- 🐧 완전한 Linux 통합
- 🎵 ALSA 프레임워크 지원
- 🔌 표준 오디오 애플리케이션 호환
- 📝 Device Tree 기반 설정
- 🛠️ 커널 모듈 드라이버

### 소프트웨어 스택

```
┌─────────────────────────────────────┐
│      사용자 공간 애플리케이션        │
│  ┌──────────┐  ┌──────────────┐    │
│  │ aplay    │  │ arecord      │    │
│  └────┬─────┘  └──────┬───────┘    │
│       │                │             │
│  ┌────▼────────────────▼────────┐   │
│  │      ALSA 라이브러리          │   │
│  └────────────┬─────────────────┘   │
└───────────────┼─────────────────────┘
                │
┌───────────────▼─────────────────────┐
│         커널 공간                    │
│  ┌─────────────────────────────┐   │
│  │     ALSA 코어 (snd_pcm)     │   │
│  └──────────┬──────────────────┘   │
│             │                       │
│  ┌──────────▼──────────────────┐   │
│  │   Zybo 오디오 드라이버      │   │
│  │   (zybo_audio.ko)           │   │
│  └──────────┬──────────────────┘   │
│             │                       │
│  ┌──────────▼──────────────────┐   │
│  │   I2C 서브시스템            │   │
│  └─────────────────────────────┘   │
└─────────────────────────────────────┘
                │
                ▼
         SSM2603 하드웨어
```

### PetaLinux 프로젝트 생성

```bash
# PetaLinux 프로젝트 생성
petalinux-create -t project -n zybo_audio --template zynq
cd zybo_audio

# 하드웨어 설정 임포트
petalinux-config --get-hw-description=../project2_vitis/vivado

# 커널 설정
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

### 프로젝트 1 (FPGA 전용) 테스트

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
# === Zybo Z7-20 오디오 코덱 데모 ===
# 오디오 코덱 초기화 완료
# 오디오 처리 시작...
# 이펙트 변경 버튼:
#   BTN0: 패스스루
#   BTN1: 에코
#   BTN2: 리버브
#   BTN3: 피치 시프트

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
[    5.123] Zybo 오디오 드라이버 등록 성공
[    5.456] SSM2603 코덱 초기화 완료

# 4. ALSA 디바이스 확인
root@zybo:~# aplay -l
**** 재생 하드웨어 디바이스 목록 ****
card 0: Zybo [Zybo Z7 Audio], device 0: Zybo PCM [Zybo PCM]
  서브디바이스: 1/1
  서브디바이스 #0: subdevice #0

root@zybo:~# arecord -l
**** 녹음 하드웨어 디바이스 목록 ****
card 0: Zybo [Zybo Z7 Audio], device 0: Zybo PCM [Zybo PCM]
  서브디바이스: 1/1
  서브디바이스 #0: subdevice #0

# 5. 오디오 루프백 테스트
root@zybo:~# ./audio_test
=== Zybo Z7 오디오 테스트 ===
오디오 루프백 시작 (Ctrl+C로 중지)
Line In → Headphone Out

# 6. 녹음 테스트 (10초)
root@zybo:~# ./audio_record recording.raw
10초간 오디오 녹음 중...
녹음 완료

# 7. 재생 테스트
root@zybo:~# ./audio_playback recording.raw
오디오 파일 재생: recording.raw
재생 완료

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
xil_printf("DMA 상태: 0x%08x\n", status);

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

# 트리거 설정
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
- [Zybo Z7 레퍼런스 매뉴얼](https://digilent.com/reference/programmable-logic/zybo-z7/reference-manual)
- [Zybo Z7 회로도](https://digilent.com/reference/_media/reference/programmable-logic/zybo-z7/zybo-z7_sch.pdf)
- [Zybo Z7 Master XDC](https://github.com/Digilent/digilent-xdc/blob/master/Zybo-Z7-Master.xdc)

#### Analog Devices
- [SSM2603 데이터시트](https://www.analog.com/media/en/technical-documentation/data-sheets/SSM2603.pdf)
- [SSM2603 사용자 가이드](https://www.analog.com/media/en/technical-documentation/user-guides/UG-169.pdf)

#### Xilinx
- [Zynq-7000 기술 참조 매뉴얼 (UG585)](https://www.xilinx.com/support/documentation/user_guides/ug585-Zynq-7000-TRM.pdf)
- [Vivado 사용자 가이드 (UG893)](https://www.xilinx.com/support/documentation/sw_manuals/xilinx2021_1/ug893-vivado-ip.pdf)
- [Vitis 사용자 가이드 (UG1400)](https://www.xilinx.com/support/documentation/sw_manuals/xilinx2021_1/ug1400-vitis-embedded.pdf)
- [PetaLinux 참조 가이드 (UG1144)](https://www.xilinx.com/support/documentation/sw_manuals/xilinx2021_1/ug1144-petalinux-tools-reference-guide.pdf)

### 프로토콜 사양

- [I2C 버스 사양](https://www.nxp.com/docs/en/user-guide/UM10204.pdf)
- [I2S 버스 사양](https://www.sparkfun.com/datasheets/BreakoutBoards/I2SBUS.pdf)

### ALSA 문서

- [ALSA 프로젝트](https://www.alsa-project.org/)
- [ALSA 드라이버 API](https://www.kernel.org/doc/html/latest/sound/kernel-api/index.html)
- [ALSA 드라이버 작성 가이드](https://www.kernel.org/doc/html/latest/sound/kernel-api/writing-an-alsa-driver.html)

### 커뮤니티

- [Digilent 포럼](https://forum.digilentinc.com/)
- [Xilinx 커뮤니티](https://support.xilinx.com/s/topic/0TO2E000000YKYAWA4/programmable-devices)

## 기여하기

이 프로젝트에 기여하고 싶으신가요? 환영합니다! 🎉

### 기여 방법

1. 이 저장소를 **Fork** 하세요
2. **Feature branch**를 생성하세요 (`git checkout -b feature/멋진기능`)
3. 변경사항을 **Commit**하세요 (`git commit -m '멋진 기능 추가'`)
4. 브랜치에 **Push**하세요 (`git push origin feature/멋진기능`)
5. **Pull Request**를 열어주세요

### 기여 가이드라인

#### 코드 스타일

**Verilog**
```verilog
// 2칸 들여쓰기
// 신호는 snake_case
// 모듈은 PascalCase
module AudioProcessor (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [23:0] audio_in,
    output reg  [23:0] audio_out
);
```

**C/C++**
```c
// 4칸 들여쓰기
// 함수는 snake_case
// 매크로는 UPPER_CASE
int process_audio_buffer(int32_t *buffer, size_t length)
{
    // 구현
}
```

#### 커밋 메시지

```
feat: 에코 이펙트 구현 추가
fix: I2C 타임아웃 문제 해결
docs: 하드웨어 설정 가이드 업데이트
test: 오디오 이펙트 단위 테스트 추가
refactor: DMA 버퍼 관리 개선
```

## 라이선스

이 프로젝트는 MIT 라이선스 하에 배포됩니다. 자세한 내용은 [LICENSE](LICENSE) 파일을 참조하세요.

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

프로젝트 링크: [https://github.com/yourusername/zybo-z7-audio](https://github.com/yourusername/zybo-z7-audio)

---

## 변경 이력

### v1.0.0 (2024-02-12)
- ✨ 초기 릴리즈
- ✅ 프로젝트 1: FPGA 전용 구현 완료
- ✅ 프로젝트 2: PS+PL Vitis 구현 완료
- ✅ 프로젝트 3: PetaLinux 드라이버 구현 완료
- 📝 완전한 한글 문서화

### 로드맵

#### v1.1.0 (계획)
- [ ] USB Audio 클래스 지원
- [ ] 추가 오디오 이펙트 (코러스, 플랜저)
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

임베디드 시스템 애호가들이 ❤️를 담아 만들었습니다

</div>
