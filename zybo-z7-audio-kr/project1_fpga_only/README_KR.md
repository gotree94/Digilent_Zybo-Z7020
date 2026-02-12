# 프로젝트 1: FPGA 전용 오디오 루프백

Verilog HDL만을 사용한 순수 PL (Programmable Logic) 구현입니다.

## 설명

이 프로젝트는 Line In (J7)의 입력을 Headphone Out (J5)으로 직접 연결하는 간단한 오디오 루프백 시스템을 구현합니다. 모든 처리는 PS (Processing System)를 사용하지 않고 FPGA 패브릭에서만 수행됩니다.

## 주요 기능

- 순수 Verilog HDL 구현
- SSM2603 코덱 설정을 위한 I2C 마스터
- 오디오 데이터용 I2S 송수신기
- 클럭 생성 (MCLK, BCLK, LRCLK)
- LED 상태 표시

## 디렉토리 구조

```
project1_fpga_only/
├── hdl/
│   ├── audio_top.v       # 최상위 모듈
│   ├── i2c_config.v      # I2C 설정
│   ├── i2s_rx.v          # I2S 수신기
│   ├── i2s_tx.v          # I2S 송신기
│   └── clk_divider.v     # 클럭 생성
├── constraints/
│   └── zybo_z7_audio.xdc # 핀 제약 조건
└── scripts/
    └── create_project.tcl # 프로젝트 생성 스크립트
```

## 프로젝트 빌드

### 방법 1: TCL 스크립트 사용

```bash
cd scripts
vivado -mode batch -source create_project.tcl
```

### 방법 2: 수동 생성

1. Vivado 실행
2. 새 프로젝트 생성
3. Zybo Z7-20 보드 선택
4. `hdl/` 디렉토리의 모든 HDL 파일 추가
5. `constraints/`의 제약 조건 파일 추가
6. `audio_top`을 최상위 모듈로 설정
7. 비트스트림 생성

## FPGA 프로그래밍

### Hardware Manager 사용

```tcl
open_hw_manager
connect_hw_server
open_hw_target
current_hw_device [get_hw_devices xc7z020_1]
set_property PROGRAM.FILE {경로/audio_top.bit} [get_hw_devices xc7z020_1]
program_hw_devices [get_hw_devices xc7z020_1]
```

### 명령줄 사용

```bash
vivado -mode batch -source program.tcl
```

## 테스트

1. Line In (J7 - 하늘색)에 오디오 소스 연결
2. Headphone (J5 - 검정색)에 헤드폰 연결
3. FPGA에 비트스트림 다운로드
4. LED 상태 확인:
   - **LED[0]**: I2C 설정 완료 (켜져 있어야 함)
   - **LED[1]**: 오디오 데이터 유효 (오디오와 함께 깜박임)
   - **LED[2]**: LR 클럭 활동 (빠른 깜박임 - 48kHz)
   - **LED[3]**: 오디오 레벨 표시기

## 사양

- 샘플 레이트: 48 kHz
- 비트 깊이: 24-bit
- 채널: 2 (스테레오)
- 레이턴시: ~1-2 샘플 (20-40 μs)

## 클럭 주파수

| 클럭 | 주파수 | 용도 |
|------|--------|------|
| MCLK | 12.5 MHz | 코덱 마스터 클럭 |
| BCLK | 3.125 MHz | I2S 비트 클럭 |
| LRCLK | 48 kHz | 좌/우 채널 선택 |

## 트러블슈팅

### 오디오 출력 없음

1. LED[0] 확인 - 꺼져있으면 I2C 설정 실패
2. I2C 연결 확인 (SCL: N18, SDA: N17)
3. 전원 공급 전압 확인

### 왜곡된 오디오

1. 오실로스코프로 클럭 주파수 확인
2. MCLK가 코덱에 도달하는지 확인 (T19)
3. 적절한 접지 확인

### LED[0]이 켜지지 않음

1. 보드의 I2C 풀업 저항 확인
2. 코덱 I2C 주소 확인 (0x1A)
3. `i2c_config.v`에서 I2C 클럭 속도 낮추기

## 라이선스

MIT 라이선스 - 루트 LICENSE 파일 참조
