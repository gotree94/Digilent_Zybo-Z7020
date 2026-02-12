# 프로젝트 1: FPGA 전용 오디오 루프백 (Zybo Z7-20)

Verilog HDL만을 사용한 순수 PL (Programmable Logic) 구현입니다.

## ✅ Digilent 공식 핀 배치 적용됨

**중요 업데이트**: Digilent 공식 Master XDC 파일 기준으로 모든 핀 매핑 수정 완료!

### 주요 변경사항
- ✅ 올바른 오디오 핀 사용 (R19, R17, R18, T19, R16, Y18)
- ✅ **I2C가 PL GPIO에 연결됨 확인** (N18, N17)
- ✅ **순수 FPGA에서 I2C 직접 제어 가능!**
- ✅ Pmod 점퍼선 연결 불필요

## 설명

이 프로젝트는 Line In (J7)의 입력을 Headphone Out (J5)으로 직접 연결하는 간단한 오디오 루프백 시스템을 구현합니다. 

**모든 기능이 순수 FPGA(PL)에서 작동합니다 - PS 불필요!**

## 주요 기능

- 순수 Verilog HDL 구현
- SSM2603 코덱을 위한 I2C 마스터
- 오디오 데이터용 I2S 송수신기
- 125MHz 입력 클럭에서 오디오 클럭 생성
- LED 상태 표시

## Zybo Z7-20 사양

- **FPGA**: Xilinx Zynq-7000 XC7Z020-1CLG400C
- **입력 클럭**: 125MHz (이더넷 PHY 클럭, K17 핀)
- **보드 버전**: Rev. B.2 이상

## 핀 배치 (Digilent 공식 XDC 기준)

### 오디오 I2S 신호
| 신호 | FPGA 핀 | 설명 |
|------|---------|------|
| AC_BCLK | R19 | 비트 클럭 |
| AC_MCLK | R17 | 마스터 클럭 출력 |
| AC_PBDAT | R18 | 재생 데이터 (출력) |
| AC_PBLRC | T19 | 재생 LR 클럭 |
| AC_RECDAT | R16 | 녹음 데이터 (입력) |
| AC_RECLRC | Y18 | 녹음 LR 클럭 |

### I2C 신호 (PL GPIO - 직접 접근 가능!)
| 신호 | FPGA 핀 | 설명 |
|------|---------|------|
| AC_SCL | N18 | I2C 클럭 |
| AC_SDA | N17 | I2C 데이터 |

## 프로젝트 빌드

### 자동 빌드 (권장)

```bash
cd project1_fpga_only/scripts

# Vivado 환경 설정
source /tools/Xilinx/Vivado/2021.1/settings64.sh

# 원클릭 빌드
./build.sh
```

### 단계별 빌드

```bash
cd project1_fpga_only/scripts

# 1. 프로젝트 생성
vivado -mode batch -source create_project.tcl

# 2. 합성 및 구현
vivado -mode batch -source build.tcl ../vivado_project/audio_loopback.xpr

# 3. FPGA 프로그래밍
vivado -mode batch -source program.tcl
```

## 테스트

### 1. 하드웨어 준비
1. Zybo Z7-20 보드 확인
2. 5V/2.5A 전원 어댑터 연결
3. Micro USB 케이블 연결 (JTAG/UART)
4. Line In (J7 - 하늘색)에 오디오 소스 연결
5. Headphone (J5 - 검정색)에 헤드폰 연결

### 2. FPGA 프로그래밍
```bash
cd scripts
vivado -mode batch -source program.tcl
```

### 3. LED 상태 확인
- **LED[0]**: I2C 설정 완료 ✅ (켜져 있어야 함)
- **LED[1]**: 오디오 데이터 수신 (오디오와 함께 깜박임)
- **LED[2]**: LR 클럭 활동 (빠른 깜박임 - ~49kHz)
- **LED[3]**: 오디오 레벨 표시
- **LD4** (시스템): FPGA Done (켜져 있어야 함)
- **LD5** (시스템): 전원 (켜져 있어야 함)

### 4. 오디오 확인
헤드폰에서 Line In 오디오가 즉시 들려야 합니다!

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

## 트러블슈팅

### LED[0]이 켜지지 않음
**원인**: I2C 통신 실패
**해결**: 
1. I2C 클럭 속도 확인 (`i2c_config.v`)
2. 전원 공급 확인
3. TROUBLESHOOTING.md 참조

### 소리가 들리지 않음
**원인**: 볼륨 설정 또는 클럭 문제
**해결**:
1. LED[0] 확인 (I2C 설정 필요)
2. LED[1] 확인 (오디오 수신 확인)
3. 헤드폰 연결 및 볼륨 확인

### 왜곡된 오디오
**원인**: 클럭 주파수 불일치
**해결**: 
```verilog
// clk_divider.v 확인
// 125MHz 입력 클럭이 올바르게 분주되는지 확인
```

## 디렉토리 구조

```
project1_fpga_only/
├── hdl/                          # Verilog HDL 소스
│   ├── audio_top.v               # 최상위 모듈
│   ├── i2c_config.v              # I2C 설정
│   ├── i2s_rx.v                  # I2S 수신기
│   ├── i2s_tx.v                  # I2S 송신기
│   └── clk_divider.v             # 클럭 생성 (125MHz 기준)
├── constraints/
│   └── zybo_z7_audio.xdc         # Digilent 공식 핀 배치 ✅
├── scripts/
│   ├── create_project.tcl        # 프로젝트 생성
│   ├── build.tcl                 # 빌드 스크립트
│   ├── build.sh                  # 자동 빌드
│   └── program.tcl               # FPGA 프로그래밍
├── README.md                     # 영문 문서
├── README_KR.md                  # 한글 문서 (이 파일)
├── PINOUT_CORRECTION.md          # 핀 수정 내역 ⭐
├── HARDWARE_CONNECTION.md        # 하드웨어 연결 가이드
└── TROUBLESHOOTING.md            # 문제 해결 가이드
```

## 참고 문서

- [PINOUT_CORRECTION.md](PINOUT_CORRECTION.md) - ⭐ **핀 수정 내역 (필독!)**
- [HARDWARE_CONNECTION.md](HARDWARE_CONNECTION.md) - 하드웨어 연결 상세
- [TROUBLESHOOTING.md](TROUBLESHOOTING.md) - 빌드 및 실행 문제 해결
- [Digilent Zybo Z7 Master XDC](https://github.com/Digilent/digilent-xdc/blob/master/Zybo-Z7-Master.xdc)
- [Zybo Z7-20 Reference Manual](https://digilent.com/reference/programmable-logic/zybo-z7/reference-manual)

## 라이선스

MIT 라이선스 - 루트 LICENSE 파일 참조

---

## 🎉 업데이트 요약

**이전 버전의 문제점:**
- 잘못된 핀 매핑 사용
- I2C를 PS MIO로 잘못 이해
- 불필요한 Pmod 점퍼선 연결 방법 제시

**현재 버전 (수정됨):**
- ✅ Digilent 공식 XDC 핀 사용
- ✅ I2C가 PL GPIO임을 확인 (N18, N17)
- ✅ 순수 FPGA 프로젝트 완벽 작동
- ✅ 추가 하드웨어 연결 불필요

**이제 정말 간단합니다: 빌드 → 프로그램 → 작동!** 🎊


