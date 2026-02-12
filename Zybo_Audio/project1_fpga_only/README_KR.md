# 프로젝트 1: FPGA 전용 오디오 루프백 (Zybo Z7-20)

Verilog HDL만을 사용한 순수 PL (Programmable Logic) 구현입니다.

## ⚠️ 중요: Zybo Z7-20 하드웨어 제약사항

**I2C 연결 문제:**
Zybo Z7-20에서 SSM2603 오디오 코덱의 I2C는 **PS MIO 핀(MIO50/51)에 연결**되어 있습니다.
순수 FPGA 구현에서는 PS MIO에 접근할 수 없으므로 다음 방법 중 하나를 사용해야 합니다:

### 해결 방법

#### 방법 1 (권장): 코덱 사전 초기화
```bash
# 1단계: 프로젝트 2로 코덱 초기화
cd ../project2_vitis
# PS를 통해 I2C로 코덱 설정

# 2단계: 전원을 끄지 말고 프로젝트 1 로드
cd ../project1_fpga_only/scripts
./build.sh

# 코덱 설정이 유지되어 작동
```

#### 방법 2: Pmod 점퍼선 연결 (고급)
Pmod JE 커넥터(V12, W16)를 보드의 I2C 라인에 점퍼선으로 연결
(하드웨어 수정 필요 - 상세 내용은 HARDWARE_CONNECTION.md 참조)

#### 방법 3: 프로젝트 2/3 사용
PS를 사용하는 프로젝트 2 또는 3을 사용하면 I2C 문제 없음

## 설명

이 프로젝트는 Line In (J7)의 입력을 Headphone Out (J5)으로 직접 연결하는 간단한 오디오 루프백 시스템을 구현합니다. 모든 처리는 PS (Processing System)를 사용하지 않고 FPGA 패브릭에서만 수행됩니다.

## 주요 기능

- 순수 Verilog HDL 구현
- SSM2603 코덱을 위한 I2C 마스터 (Pmod를 통해)
- 오디오 데이터용 I2S 송수신기
- 125MHz 입력 클럭에서 오디오 클럭 생성
- LED 상태 표시

## Zybo Z7-20 사양

- **FPGA**: Xilinx Zynq-7000 XC7Z020-1CLG400C
- **입력 클럭**: 125MHz (이더넷 PHY 클럭, K17 핀)
- **보드 버전**: Rev. B.2 이상

## 디렉토리 구조

```
project1_fpga_only/
├── hdl/
│   ├── audio_top.v       # 최상위 모듈
│   ├── i2c_config.v      # I2C 설정
│   ├── i2s_rx.v          # I2S 수신기
│   ├── i2s_tx.v          # I2S 송신기
│   └── clk_divider.v     # 클럭 생성 (125MHz 기준)
├── constraints/
│   └── zybo_z7_audio.xdc # Zybo Z7-20 전용 핀 제약
├── scripts/
│   ├── create_project.tcl # 프로젝트 생성
│   ├── build.tcl          # 빌드 스크립트
│   ├── build.sh           # 자동 빌드
│   └── program.tcl        # FPGA 프로그래밍
├── README.md              # 영문 문서
├── README_KR.md           # 한글 문서 (이 파일)
├── HARDWARE_CONNECTION.md # 하드웨어 연결 상세 가이드
└── TROUBLESHOOTING.md     # 문제 해결 가이드
```

## 핀 배치 (Zybo Z7-20 실제 하드웨어)

### 오디오 I2S 신호
| 신호 | FPGA 핀 | 설명 |
|------|---------|------|
| AC_MCLK | R19 | 마스터 클럭 출력 |
| AC_BCLK | R18 | 비트 클럭 |
| AC_PBLRC | R17 | 재생 LR 클럭 |
| AC_RECLRC | T19 | 녹음 LR 클럭 |
| AC_DAC_SDATA | D18 | 재생 데이터 (출력) |
| AC_ADC_SDATA | D19 | 녹음 데이터 (입력) |

### I2C 신호 (Pmod JE 사용)
| 신호 | FPGA 핀 | 설명 |
|------|---------|------|
| I2C_SCL | V12 | Pmod JE1 |
| I2C_SDA | W16 | Pmod JE2 |

## 프로젝트 빌드

### 방법 1: 자동 빌드 (권장)

```bash
cd project1_fpga_only/scripts

# Vivado 환경 설정
source /tools/Xilinx/Vivado/2021.1/settings64.sh

# 원클릭 빌드
./build.sh
```

### 방법 2: 단계별 빌드

```bash
cd project1_fpga_only/scripts

# 1. 프로젝트 생성
vivado -mode batch -source create_project.tcl

# 2. 합성 및 구현
vivado -mode batch -source build.tcl ../vivado_project/audio_loopback.xpr

# 3. FPGA 프로그래밍
vivado -mode batch -source program.tcl
```

### 방법 3: GUI 사용

```bash
cd project1_fpga_only/scripts
vivado -mode batch -source create_project.tcl

# Vivado GUI 실행
vivado ../vivado_project/audio_loopback.xpr

# GUI에서 실행:
# Flow Navigator > Run Synthesis
# Flow Navigator > Run Implementation
# Flow Navigator > Generate Bitstream
```

## 테스트

### 1. 하드웨어 준비
1. Zybo Z7-20 보드 확인 (실크스크린에 "Zybo Z7-20" 표시)
2. 5V/2.5A 전원 어댑터 연결 (권장)
3. Micro USB 케이블 연결 (JTAG/UART)
4. Line In (J7 - 하늘색)에 오디오 소스 연결
5. Headphone (J5 - 검정색)에 헤드폰 연결

### 2. I2C 초기화 (중요!)

**방법 A: 코덱 사전 초기화 (권장)**
```bash
# 먼저 프로젝트 2로 코덱 초기화
cd ../project2_vitis
# (프로젝트 2 빌드 및 실행 - PS가 I2C로 코덱 설정)

# 전원 유지한 채로 프로젝트 1 로드
cd ../project1_fpga_only/scripts
vivado -mode batch -source program.tcl
```

**방법 B: 점퍼선 연결**
```bash
# HARDWARE_CONNECTION.md 참조
# Pmod JE1, JE2를 I2C 라인에 연결 (고급)
```

### 3. LED 상태 확인
- **LED[0]**: I2C 설정 완료 (켜져 있어야 함)
  - 꺼져 있으면: 방법 A로 재시도
- **LED[1]**: 오디오 데이터 수신 (오디오와 함께 깜박임)
- **LED[2]**: LR 클럭 활동 (빠른 깜박임 - ~49kHz)
- **LED[3]**: 오디오 레벨 표시
- **LD4** (시스템): FPGA Done (켜져 있어야 함)
- **LD5** (시스템): 전원 (켜져 있어야 함)

## 사양

- **샘플 레이트**: 48.828 kHz (실제), 48 kHz (목표)
- **오차**: 1.7% (오디오에서 허용 가능)
- **비트 깊이**: 24-bit
- **채널**: 2 (스테레오)
- **레이턴시**: ~1-2 샘플 (20-40 μs)

## 클럭 주파수 (Zybo Z7-20)

| 클럭 | 목표 주파수 | 실제 주파수 | 오차 |
|------|-------------|-------------|------|
| 입력 | - | 125 MHz | - |
| MCLK | 12.288 MHz | 12.5 MHz | 1.7% |
| BCLK | 3.072 MHz | 3.125 MHz | 1.7% |
| LRCLK | 48 kHz | 48.828 kHz | 1.7% |

**참고**: 1.7% 오차는 대부분의 오디오 애플리케이션에서 허용 가능합니다.
정확한 48kHz가 필요한 경우 PLL/MMCM 사용 (고급 옵션)

## 트러블슈팅

### LED[0]이 켜지지 않음
**원인**: I2C 통신 실패 (PS MIO 접근 불가)
**해결**: 
1. 방법 A (코덱 사전 초기화) 사용
2. 또는 프로젝트 2/3 사용

### 소리는 들리지만 LED[0] 꺼짐
**상태**: 정상 - 코덱이 기본 설정으로 동작 중
**참고**: 최적 성능을 위해 I2C 설정 권장

### 왜곡된 오디오
**원인**: 클럭 주파수 불일치
**해결**: 
```verilog
// clk_divider.v 확인
// 125MHz 입력 클럭이 올바르게 분주되는지 확인
```

### 빌드 오류
**참고**: TROUBLESHOOTING.md 파일 참조

## 고급 옵션

### 정확한 48kHz 샘플레이트

PLL/MMCM을 사용하여 125MHz에서 12.288MHz 생성:

```tcl
# Vivado IP Catalog에서
# Clocking Wizard 추가
# Input: 125MHz
# Output: 12.288MHz
```

그 다음 `clk_divider.v`를 12.288MHz 입력용으로 수정

## 참고 문서

- [HARDWARE_CONNECTION.md](HARDWARE_CONNECTION.md) - 상세 하드웨어 연결 가이드
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - 빌드 및 실행 문제 해결
- [Zybo Z7-20 Reference Manual](https://digilent.com/reference/programmable-logic/zybo-z7/reference-manual)
- [SSM2603 Datasheet](https://www.analog.com/media/en/technical-documentation/data-sheets/SSM2603.pdf)

## 라이선스

MIT 라이선스 - 루트 LICENSE 파일 참조

