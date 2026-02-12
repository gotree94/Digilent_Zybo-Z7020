# Zybo Z7-20 Audio Codec Project with VS Code & AI Development

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Xilinx Vivado](https://img.shields.io/badge/Vivado-2020.2+-red)](https://www.xilinx.com/products/design-tools/vivado.html)
[![Board](https://img.shields.io/badge/Board-Zybo%20Z7--20-blue)](https://digilent.com/reference/programmable-logic/zybo-z7/start)

Zybo Z7-20 개발 보드를 위한 VS Code 기반 FPGA 개발 환경 및 Audio Codec(SSM2603) 예제 프로젝트

## 📋 프로젝트 개요

이 프로젝트는 다음을 제공합니다:

- ✅ **Zybo Z7-20** 타겟 완전 설정 XDC 파일
- ✅ **SSM2603 Audio Codec** 인터페이스 예제
- ✅ **VS Code** 통합 개발 환경
- ✅ **Vivado TCL** 자동화 스크립트
- ✅ **Cocotb** Python 테스트벤치
- ✅ **AI 어시스턴트** (GitHub Copilot) 지원

## 🎯 주요 기능

### Hardware Features
- SSM2603 Audio Codec 제어 (I2S 인터페이스)
- Audio loopback (ADC → DAC)
- I2C 제어 인터페이스
- LED 상태 표시
- 스위치 및 버튼 입력

### Development Features
- VS Code Tasks를 통한 Vivado 자동화
- Verilator 린팅
- Cocotb 기반 검증
- 체계적인 빌드 스크립트

## 💻 시스템 요구사항

### 필수 소프트웨어
- **Xilinx Vivado**: 2020.2 이상 (2023.2 권장)
- **VS Code**: 1.85+
- **Python**: 3.8+
- **Git**: 2.25+

### 선택 사항 (검증용)
- **Verilator**: 최신 버전
- **Icarus Verilog**: 10.3+
- **GTKWave**: 파형 분석
- **Cocotb**: Python 검증 프레임워크

## 🚀 빠른 시작

### 1. 프로젝트 클론

```bash
git clone <repository-url>
cd zybo-z7-vscode-project
```

### 2. VS Code 열기

```bash
code .
```

### 3. Vivado 환경 설정

`.vscode/settings.json`에서 Vivado 경로 확인:

```json
{
    "terminal.integrated.env.linux": {
        "VIVADO_PATH": "/tools/Xilinx/Vivado/2023.2"
    }
}
```

### 4. 빌드 실행

**방법 1: VS Code Task 사용**
- `Ctrl+Shift+B` → "Vivado: Synthesis" 선택

**방법 2: 명령어 사용**
```bash
# Vivado 환경 설정
source /tools/Xilinx/Vivado/2023.2/settings64.sh

# 전체 빌드 (합성 + 구현 + 비트스트림)
vivado -mode batch -source scripts/full_build.tcl

# 또는 단계별 실행
vivado -mode batch -source scripts/synthesis.tcl
vivado -mode batch -source scripts/implementation.tcl
vivado -mode batch -source scripts/bitstream.tcl
```

### 5. 시뮬레이션 실행 (선택사항)

```bash
# Cocotb 설치
pip install cocotb cocotb-test

# 시뮬레이션 실행
make

# 파형 확인
make waves
```

## 📁 프로젝트 구조

```
zybo-z7-vscode-project/
├── .vscode/
│   ├── settings.json          # VS Code 설정
│   └── tasks.json             # Vivado 빌드 태스크
├── rtl/
│   └── top.v                  # Top 모듈 (Audio Codec 예제)
├── tb/
│   └── test_top.py            # Cocotb 테스트벤치
├── constraints/
│   └── zybo_z7_20.xdc         # Zybo Z7-20 핀 제약
├── scripts/
│   ├── synthesis.tcl          # 합성 스크립트
│   ├── implementation.tcl     # 구현 스크립트
│   ├── bitstream.tcl          # 비트스트림 생성
│   └── full_build.tcl         # 전체 빌드 플로우
├── reports/                   # 빌드 리포트 (생성됨)
├── build/                     # Vivado 프로젝트 (생성됨)
├── Makefile                   # Cocotb 시뮬레이션
├── .gitignore
└── README.md
```

## 🔌 Zybo Z7-20 핀 매핑

### Audio Codec (SSM2603)

| 신호 | FPGA 핀 | 방향 | 설명 |
|------|---------|------|------|
| `ac_bclk` | K18 | Input | Bit Clock (I2S) |
| `ac_recdat` | K17 | Input | Record Data (ADC) |
| `ac_pbdat` | M17 | Output | Playback Data (DAC) |
| `ac_reclrc` | M18 | Input | Record L/R Clock |
| `ac_pblrc` | L17 | Output | Playback L/R Clock |
| `ac_mclk` | T19 | Output | Master Clock (12.288 MHz) |
| `ac_muten` | P18 | Output | Mute Control |
| `ac_scl` | N18 | Inout | I2C Clock |
| `ac_sda` | N17 | Inout | I2C Data |

### 기본 I/O

| 신호 | 핀 | 설명 |
|------|-----|------|
| `clk` | K17 | 125 MHz 시스템 클럭 |
| `sw[3:0]` | G15, P15, W13, T16 | 슬라이드 스위치 |
| `btn[3:0]` | K18, P16, K19, Y16 | 푸시 버튼 |
| `led[3:0]` | M14, M15, G14, D18 | LED |

## 🛠️ VS Code 사용법

### 추천 Extensions

프로젝트를 열 때 다음 확장 프로그램 설치를 권장합니다:

```bash
code --install-extension mshr-h.veriloghdl
code --install-extension terostechnology.teroshdl
code --install-extension wavetrace.wavetrace
code --install-extension github.copilot
code --install-extension rashwell.tcl
```

### Tasks (빌드 자동화)

`Ctrl+Shift+P` → "Tasks: Run Task" 또는 `Ctrl+Shift+B`

사용 가능한 Tasks:
- **Vivado: Synthesis** - RTL 합성
- **Vivado: Implementation** - Place & Route
- **Vivado: Generate Bitstream** - 비트스트림 생성
- **Vivado: Full Build** - 전체 빌드 플로우
- **Simulate with Verilator** - 빠른 린팅
- **Run Cocotb Testbench** - Python 테스트 실행
- **Clean Build** - 빌드 파일 정리

## 🧪 검증 및 테스트

### Verilator 린팅

```bash
# 명령어 실행
verilator --lint-only rtl/top.v

# 또는 VS Code Task 사용
Ctrl+Shift+P → Tasks: Run Task → "Simulate with Verilator"
```

### Cocotb 시뮬레이션

```bash
# 시뮬레이션 실행
make

# 파형 뷰어 열기
make waves

# 린팅만 실행
make lint

# 정리
make clean
```

### 포함된 테스트

1. **test_basic_functionality**: LED, 스위치, 버튼 기본 동작
2. **test_audio_loopback**: Audio ADC → DAC 루프백
3. **test_mclk_generation**: Master Clock 생성 확인
4. **test_lrc_passthrough**: L/R Clock 통과 확인
5. **test_regression**: 장시간 안정성 테스트

## 📊 빌드 리포트

빌드 완료 후 `reports/` 디렉토리에 생성되는 파일:

```
reports/
├── post_synth_utilization.rpt   # 합성 후 리소스 사용량
├── post_synth_timing.rpt        # 합성 후 타이밍
├── post_impl_utilization.rpt    # 구현 후 리소스 사용량
├── post_impl_timing.rpt         # 구현 후 타이밍
├── post_impl_power.rpt          # 전력 분석
└── post_impl_drc.rpt            # DRC 체크 결과
```

## 🤖 AI 어시스턴트 활용

### GitHub Copilot 사용 예시

#### Verilog 모듈 생성

```verilog
// Type: "Create an I2C master controller"
// Copilot will suggest complete module implementation
```

#### 테스트벤치 생성

```python
# Type: "Create cocotb test for I2C write transaction"
# Copilot will generate test code
```

### 추천 프롬프트

VS Code에서 Copilot Chat 사용:
- "Optimize this FSM for low power"
- "Add error checking to this I2C controller"
- "Generate timing constraints for this design"
- "Create assertions for this FIFO interface"

## 🔧 문제 해결

### DRC 오류: NSTD-1 / UCIO-1

**증상**: I/O Standard 또는 LOC 미지정 오류

**해결**:
1. `constraints/zybo_z7_20.xdc` 파일 확인
2. 사용하는 모든 포트가 XDC에 정의되어 있는지 확인
3. 포트 이름이 RTL과 정확히 일치하는지 확인

### Vivado 경로 문제

**증상**: "vivado: command not found"

**해결**:
```bash
# .bashrc 또는 .zshrc에 추가
export VIVADO_PATH=/tools/Xilinx/Vivado/2023.2
source $VIVADO_PATH/settings64.sh

# 확인
vivado -version
```

### Cocotb 시뮬레이션 실패

**증상**: "ModuleNotFoundError: No module named 'cocotb'"

**해결**:
```bash
# 가상환경 사용 권장
python3 -m venv venv
source venv/bin/activate
pip install cocotb cocotb-test
```

### 타이밍 제약 위반

**해결 방법**:
1. `reports/post_impl_timing.rpt` 확인
2. 클럭 제약 검증
3. 필요시 `constraints/zybo_z7_20.xdc`에 추가 제약 설정

## 📚 참고 자료

### 공식 문서
- [Zybo Z7 Reference Manual](https://digilent.com/reference/programmable-logic/zybo-z7/reference-manual)
- [Zybo Z7 Schematic](https://digilent.com/reference/programmable-logic/zybo-z7/start)
- [SSM2603 Datasheet](https://www.analog.com/media/en/technical-documentation/data-sheets/SSM2603.pdf)
- [Vivado Design Suite User Guide](https://www.xilinx.com/support/documentation/sw_manuals/xilinx2023_2/ug835-vivado-tcl-commands.pdf)

### 튜토리얼
- [Digilent Zybo Z7 Resource Center](https://digilent.com/reference/programmable-logic/zybo-z7/start)
- [Cocotb Documentation](https://docs.cocotb.org/)
- [Vivado TCL Scripting](https://www.xilinx.com/support/documentation-navigation/design-hubs/dh0010-vivado-tcl-scripting-hub.html)

### 커뮤니티
- [Digilent Forum](https://forum.digilent.com/)
- [Xilinx Community](https://support.xilinx.com/s/)
- [Reddit r/FPGA](https://www.reddit.com/r/FPGA/)

## 🎓 교육 활용

이 프로젝트는 임베디드 시스템 교육에 최적화되어 있습니다:

### 실습 과제 예시

1. **기초**: LED 제어 및 스위치 입력
2. **중급**: I2C 프로토콜 구현
3. **고급**: Audio DSP 알고리즘 구현
4. **심화**: 실시간 Audio Effects 처리

### 학습 경로

```
Arduino → STM32 → Zybo Z7 (FPGA) → 고급 SoC
```

## 🤝 기여하기

개선 사항이나 버그 리포트를 환영합니다!

1. Fork the repository
2. Create feature branch (`git checkout -b feature/NewFeature`)
3. Commit changes (`git commit -m 'Add NewFeature'`)
4. Push to branch (`git push origin feature/NewFeature`)
5. Open Pull Request

## 📄 라이선스

이 프로젝트는 MIT 라이선스를 따릅니다.

## ✉️ 연락처

- **작성자**: 나무
- **소속**: 대학교 임베디드 시스템 연구실
- **GitHub**: [@yourhandle](https://github.com/yourhandle)

## 🙏 감사의 말

- Digilent for Zybo Z7-20 board
- AMD Xilinx for Vivado Design Suite
- Cocotb development team
- VS Code extension developers

---

**Last Updated**: 2025-02-12  
**Version**: 1.0.0  
**Board**: Zybo Z7-20 (xc7z020clg400-1)
