# Zybo Z7-20 하드웨어 연결 가이드

## ⚠️ 중요: I2C 연결 주의사항

Zybo Z7-20에서 SSM2603 오디오 코덱의 I2C는 **PS MIO 핀에 연결**되어 있습니다:
- I2C SCL: PS MIO50
- I2C SDA: PS MIO51

### 프로젝트별 I2C 처리 방법

#### 프로젝트 1: FPGA Only (Pure PL)
**문제점:** PS를 사용하지 않으므로 MIO 핀에 접근 불가

**해결책 1 (권장): Pmod 커넥터를 통한 외부 I2C**
```
Pmod JE 사용:
- JE1 (V12) → I2C SCL
- JE2 (W16) → I2C SDA
- JE3, JE4 → 사용 안함

물리적 연결 필요:
1. Pmod JE1 핀을 SSM2603 SCL 핀에 점퍼선으로 연결
2. Pmod JE2 핀을 SSM2603 SDA 핀에 점퍼선으로 연결
3. 공통 GND 연결 확인
```

**해결책 2: 사전 설정된 코덱 사용**
```
코덱을 프로젝트 2나 3으로 먼저 초기화한 후,
전원을 끄지 않고 프로젝트 1 비트스트림 로드
(코덱 설정은 전원이 유지되는 동안 보존됨)
```

#### 프로젝트 2 & 3: PS+PL
**정상 동작:** PS의 I2C0를 통해 자동으로 코덱 제어 가능

## Zybo Z7-20 오디오 핀 배치 (실제 하드웨어 기준)

### I2S 오디오 신호 (PL 연결)

| 신호 | FPGA 핀 | 방향 | 설명 |
|------|---------|------|------|
| AC_MCLK | R19 | 출력 | 마스터 클럭 (12MHz) |
| AC_BCLK | R18 | 출력 | 비트 클럭 (I2S SCLK) |
| AC_PBLRC | R17 | 출력 | 재생 LR 클럭 (DACLRC) |
| AC_RECLRC | T19 | 출력 | 녹음 LR 클럭 (ADCLRC) |
| AC_DAC_SDATA | D18 | 출력 | 재생 데이터 (DAC로) |
| AC_ADC_SDATA | D19 | 입력 | 녹음 데이터 (ADC에서) |

### I2C 제어 신호

| 방법 | SCL | SDA | 비고 |
|------|-----|-----|------|
| PS (권장) | MIO50 | MIO51 | 프로젝트 2, 3 |
| PL (Pmod JE) | V12 | W16 | 프로젝트 1 (점퍼선 필요) |

### 오디오 커넥터

| 커넥터 | 타입 | 색상 | 신호 경로 |
|--------|------|------|-----------|
| J5 | Headphone Out | ⚫ Black | SSM2603 DAC → HP 앰프 |
| J6 | Mic In | 🌸 Pink | 마이크 → SSM2603 ADC |
| J7 | Line In | 🔵 Blue | Line In → SSM2603 ADC |

## 프로젝트 1 설정 방법

### 방법 A: Pmod 점퍼선 연결 (하드웨어 수정)

#### 필요한 재료
- 점퍼선 3개 (Female-Female)
- 멀티미터 (선택사항, 연결 확인용)

#### 연결 순서
```
1. Zybo Z7-20 전원 OFF

2. Pmod JE 커넥터 확인 (보드 상단)
   JE 핀 배치:
   [JE1][JE2][JE3][JE4]
   [GND][VCC][NC ][NC ]

3. 점퍼선 연결:
   Pmod JE1 (V12) ──→ 테스트 포인트 TP_SCL (보드 상의 I2C SCL)
   Pmod JE2 (W16) ──→ 테스트 포인트 TP_SDA (보드 상의 I2C SDA)
   Pmod GND       ──→ 공통 GND

주의: Zybo Z7-20은 I2C가 내부적으로 연결되어 있어
      실제로는 이 연결이 어렵습니다.
```

### 방법 B: 코덱 사전 초기화 (권장)

#### 순서
```bash
# 1단계: 프로젝트 2로 코덱 초기화
cd project2_vitis
# 비트스트림 프로그래밍 및 초기화 실행
# PS가 I2C를 통해 코덱 설정

# 2단계: 프로젝트 1 비트스트림 로드
# ⚠️ 중요: 보드 전원을 끄지 마세요!
cd ../project1_fpga_only/scripts
vivado -mode batch -source program.tcl

# 코덱 설정이 유지되어 오디오 작동
```

### 방법 C: 하드웨어 수정 (고급 사용자)

Zybo Z7-20 보드를 물리적으로 수정하여 I2C를 PL로 리라우팅:
```
⚠️ 경고: 보드 손상 위험!

1. PS MIO50/51 트레이스 절단
2. PL GPIO를 I2C 라인에 납땜
3. 풀업 저항 (4.7kΩ) 추가

권장하지 않음 - 보증 무효화
```

## 클럭 소스

Zybo Z7-20의 125MHz 이더넷 PHY 클럭을 사용:
- 핀: K17
- 주파수: 125MHz (실제)
- XDC에서 8ns 주기로 설정

## 전원 요구사항

- **권장:** 5V/2.5A 벽면 어댑터
- **최소:** USB 전원 (제한된 기능)
- 오디오 품질을 위해 벽면 어댑터 사용 권장

## LED 표시등

| LED | 핀 | 의미 (프로젝트 1) |
|-----|-----|-------------------|
| LD0 | M14 | I2C 설정 완료 |
| LD1 | M15 | 오디오 데이터 수신 |
| LD2 | G14 | LR 클럭 토글 |
| LD3 | D18 | 오디오 레벨 |
| LD4 | - | FPGA Done (시스템) |
| LD5 | - | 전원 (시스템) |

## 테스트 체크리스트

### 하드웨어 체크
- [ ] 전원 어댑터 연결됨
- [ ] USB 케이블 연결됨 (JTAG/UART)
- [ ] LED5 (전원) 켜짐
- [ ] 오디오 소스가 Line In (J7)에 연결됨
- [ ] 헤드폰이 HP Out (J5)에 연결됨

### 프로그래밍 체크
- [ ] 비트스트림 생성 완료
- [ ] FPGA 프로그래밍 성공
- [ ] LED4 (Done) 켜짐

### 오디오 테스트 체크
- [ ] LED0 켜짐 (I2C 완료)
- [ ] LED1 깜박임 (오디오 수신)
- [ ] 헤드폰에서 소리 들림

## 문제 해결

### LED0이 켜지지 않음
**원인:** I2C 통신 실패
**해결:**
- 방법 B (사전 초기화) 사용
- 또는 프로젝트 2/3 사용

### 소리는 들리지만 LED0 꺼짐
**정상:** 코덱이 기본 설정으로 동작 중
**참고:** 최적 성능을 위해 I2C 설정 필요

### 왜곡된 오디오
**원인:** 클럭 주파수 불일치
**확인:**
```verilog
// clk_divider.v에서
// 125MHz 입력 클럭 기준으로 재계산 필요
```

## 보드 사양 확인

```bash
# Zybo Z7-20 확인
- 실크스크린: "Zybo Z7-20"
- FPGA: XC7Z020-1CLG400C
- RAM: 1GB DDR3
- Flash: 16MB QSPI
```

## 참고 자료

- [Zybo Z7-20 Reference Manual](https://digilent.com/reference/programmable-logic/zybo-z7/reference-manual)
- [Zybo Z7-20 Schematic](https://digilent.com/reference/_media/reference/programmable-logic/zybo-z7/zybo-z7-20-sch.pdf)
- [Zybo Z7-20 Master XDC](https://github.com/Digilent/digilent-xdc/blob/master/Zybo-Z7-Master.xdc)
