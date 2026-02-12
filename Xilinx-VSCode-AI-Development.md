# Xilinx FPGA Development with VS Code and AI Plugins

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Xilinx](https://img.shields.io/badge/Xilinx-Vivado-red)](https://www.xilinx.com/)
[![VS Code](https://img.shields.io/badge/VS%20Code-1.85+-blue)](https://code.visualstudio.com/)

Xilinx(AMD) FPGA 개발을 위한 Visual Studio Code 환경 구축 및 AI 기반 설계/검증 가이드

## 📋 목차

- [개요](#개요)
- [시스템 요구사항](#시스템-요구사항)
- [설치 가이드](#설치-가이드)
- [VS Code Extensions](#vs-code-extensions)
- [Vivado 통합](#vivado-통합)
- [AI 기반 개발](#ai-기반-개발)
- [검증 환경 구축](#검증-환경-구축)
- [워크플로우 예시](#워크플로우-예시)
- [문제 해결](#문제-해결)
- [참고 자료](#참고-자료)

## 🎯 개요

이 가이드는 Xilinx FPGA 개발을 위해 VS Code 환경에서 AI 플러그인을 활용한 효율적인 설계 및 검증 방법을 제공합니다.

### 주요 기능

- ✅ VS Code 기반 HDL 개발 환경
- ✅ AI 어시스턴트를 활용한 코드 자동완성
- ✅ 실시간 문법 검사 및 린팅
- ✅ Vivado 도구 체인 통합
- ✅ Python 기반 검증 프레임워크
- ✅ 파형 분석 및 디버깅

## 💻 시스템 요구사항

### 필수 소프트웨어

- **OS**: Ubuntu 20.04/22.04 LTS (권장) 또는 Windows 10/11
- **VS Code**: 1.85 이상
- **Xilinx Vivado**: 2020.2 이상 (2023.2 권장)
- **Python**: 3.8 이상
- **Git**: 2.25 이상

### 권장 하드웨어

- **CPU**: Intel i5/AMD Ryzen 5 이상
- **RAM**: 16GB 이상 (32GB 권장)
- **Storage**: SSD 100GB 이상 여유 공간

## 🚀 설치 가이드

### 1. VS Code 설치

```bash
# Ubuntu/Debian
sudo snap install code --classic

# 또는 직접 다운로드
wget -O vscode.deb https://code.visualstudio.com/sha/download?build=stable&os=linux-deb-x64
sudo dpkg -i vscode.deb
```

### 2. Vivado 설치

```bash
# Vivado 설치 디렉토리 예시
export VIVADO_PATH=/tools/Xilinx/Vivado/2023.2

# 환경 변수 설정 (.bashrc에 추가)
source $VIVADO_PATH/settings64.sh
```

### 3. 검증 도구 설치

#### Verilator (Linux)

```bash
sudo apt-get update
sudo apt-get install -y verilator
verilator --version
```

#### Icarus Verilog

```bash
sudo apt-get install -y iverilog gtkwave
```

#### Cocotb (Python 검증 프레임워크)

```bash
pip3 install cocotb cocotb-test pytest
```

## 🔌 VS Code Extensions

### 필수 Extensions

VS Code에서 다음 확장 프로그램을 설치하세요:

```bash
# 명령어로 일괄 설치
code --install-extension mshr-h.veriloghdl
code --install-extension leafvmaple.verilog
code --install-extension eirikpre.systemverilog
code --install-extension github.copilot
code --install-extension wavetrace.wavetrace
```

#### 1. Verilog-HDL/SystemVerilog Support
- **Extension ID**: `mshr-h.veriloghdl`
- **기능**: 구문 강조, 자동완성, 린팅

#### 2. TerosHDL
- **Extension ID**: `terostechnology.teroshdl`
- **기능**: HDL 문서화, 블록 다이어그램 자동 생성

#### 3. WaveTrace
- **Extension ID**: `wavetrace.wavetrace`
- **기능**: VCD 파형 뷰어

#### 4. GitHub Copilot
- **Extension ID**: `github.copilot`
- **기능**: AI 기반 코드 자동완성

#### 5. TCL Language Support
- **Extension ID**: `rashwell.tcl`
- **기능**: Vivado TCL 스크립트 지원

### VS Code 설정 파일

프로젝트 루트에 `.vscode/settings.json` 생성:

```json
{
    "verilog.linting.linter": "verilator",
    "verilog.ctags.path": "/usr/bin/ctags",
    "verilog.formatting.verilogHDL.formatter": "verible-verilog-format",
    "files.associations": {
        "*.v": "verilog",
        "*.sv": "systemverilog",
        "*.vh": "verilog",
        "*.svh": "systemverilog",
        "*.xdc": "tcl"
    },
    "editor.formatOnSave": true,
    "terminal.integrated.env.linux": {
        "VIVADO_PATH": "/tools/Xilinx/Vivado/2023.2"
    }
}
```

## 🔗 Vivado 통합

### VS Code Tasks 설정

`.vscode/tasks.json` 파일 생성:

```json
{
    "version": "2.0.0",
    "tasks": [
        {
            "label": "Vivado: Synthesis",
            "type": "shell",
            "command": "vivado",
            "args": [
                "-mode", "batch",
                "-source", "${workspaceFolder}/scripts/synthesis.tcl"
            ],
            "group": {
                "kind": "build",
                "isDefault": true
            },
            "problemMatcher": []
        },
        {
            "label": "Vivado: Implementation",
            "type": "shell",
            "command": "vivado",
            "args": [
                "-mode", "batch",
                "-source", "${workspaceFolder}/scripts/implementation.tcl"
            ],
            "group": "build",
            "problemMatcher": []
        },
        {
            "label": "Vivado: Generate Bitstream",
            "type": "shell",
            "command": "vivado",
            "args": [
                "-mode", "batch",
                "-source", "${workspaceFolder}/scripts/bitstream.tcl"
            ],
            "group": "build",
            "problemMatcher": []
        },
        {
            "label": "Simulate with Verilator",
            "type": "shell",
            "command": "verilator",
            "args": [
                "--cc",
                "--exe",
                "--build",
                "${workspaceFolder}/rtl/*.v",
                "${workspaceFolder}/tb/tb_top.cpp"
            ],
            "group": "test",
            "problemMatcher": []
        }
    ]
}
```

### TCL 스크립트 예시

`scripts/synthesis.tcl`:

```tcl
# synthesis.tcl - Vivado 합성 스크립트

# 프로젝트 생성
create_project -force synth_project ./build -part xc7z020clg400-1

# RTL 소스 추가
add_files [glob ./rtl/*.v]
add_files -fileset constrs_1 [glob ./constraints/*.xdc]

# 최상위 모듈 설정
set_property top top_module [current_fileset]

# 합성 실행
launch_runs synth_1 -jobs 4
wait_on_run synth_1

# 결과 보고서
open_run synth_1
report_utilization -file ./reports/utilization.rpt
report_timing_summary -file ./reports/timing.rpt

# 프로젝트 닫기
close_project
```

## 🤖 AI 기반 개발

### 1. GitHub Copilot 활용

#### Verilog 모듈 자동 생성

```verilog
// AI Prompt: "Create a parameterized counter module"
module counter #(
    parameter WIDTH = 8
)(
    input wire clk,
    input wire rst_n,
    input wire en,
    output reg [WIDTH-1:0] count
);
    
    // Copilot이 자동으로 로직 제안
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            count <= {WIDTH{1'b0}};
        else if (en)
            count <= count + 1'b1;
    end
    
endmodule
```

#### SystemVerilog Assertions (SVA) 생성

```systemverilog
// AI Prompt: "Create assertions for FIFO interface"
property fifo_not_overflow;
    @(posedge clk) disable iff (!rst_n)
    (wr_en && full) |-> !overflow;
endproperty

assert property (fifo_not_overflow)
    else $error("FIFO overflow detected!");
```

### 2. AI 기반 테스트벤치 생성

```python
# AI Prompt: "Generate cocotb testbench for SPI master"
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer
from cocotb.binary import BinaryValue

@cocotb.test()
async def test_spi_transfer(dut):
    """Test SPI master data transfer"""
    
    # 클럭 생성
    clock = Clock(dut.clk, 10, units="ns")
    cocotb.start_soon(clock.start())
    
    # 리셋
    dut.rst_n.value = 0
    await Timer(20, units='ns')
    dut.rst_n.value = 1
    await RisingEdge(dut.clk)
    
    # 테스트 데이터 전송
    test_data = 0xA5
    dut.tx_data.value = test_data
    dut.tx_valid.value = 1
    
    await RisingEdge(dut.clk)
    dut.tx_valid.value = 0
    
    # 전송 완료 대기
    while dut.tx_done.value == 0:
        await RisingEdge(dut.clk)
    
    # 결과 확인
    assert dut.rx_data.value == test_data, f"Expected {test_data}, got {dut.rx_data.value}"
```

### 3. AI 코드 리뷰 및 최적화

VS Code에서 Copilot Chat 사용:

```
User: "Optimize this FSM for area"

module state_machine (
    input wire clk,
    input wire rst_n,
    input wire start,
    output reg done
);
    // 현재 코드...
endmodule

Copilot: "다음과 같이 one-hot encoding 대신 binary encoding 사용을 제안합니다..."
```

## 🧪 검증 환경 구축

### Cocotb 프로젝트 구조

```
project/
├── rtl/
│   ├── top_module.v
│   └── sub_module.v
├── tb/
│   ├── test_top.py
│   └── test_sub.py
├── Makefile
└── .vscode/
    └── settings.json
```

### Makefile 예시

```makefile
# Makefile for Cocotb simulation

SIM ?= icarus
TOPLEVEL_LANG ?= verilog

VERILOG_SOURCES = $(PWD)/rtl/top_module.v \
                  $(PWD)/rtl/sub_module.v

TOPLEVEL = top_module
MODULE = test_top

include $(shell cocotb-config --makefiles)/Makefile.sim

# 추가 타겟
.PHONY: clean wave

wave:
	gtkwave dump.vcd &

lint:
	verilator --lint-only $(VERILOG_SOURCES)
```

### 실행 방법

```bash
# 시뮬레이션 실행
make

# 파형 확인
make wave

# 린팅
make lint

# 정리
make clean
```

## 📊 워크플로우 예시

### 전체 개발 프로세스

```bash
# 1. 프로젝트 클론
git clone https://github.com/your-repo/fpga-project.git
cd fpga-project

# 2. VS Code 열기
code .

# 3. RTL 작성 (AI 어시스턴트 활용)
# - Copilot으로 코드 자동완성
# - Verilator로 실시간 문법 검사

# 4. 시뮬레이션
make sim

# 5. 합성 (VS Code Task)
# Ctrl+Shift+B → "Vivado: Synthesis"

# 6. 결과 확인
cat reports/utilization.rpt
cat reports/timing.rpt

# 7. 비트스트림 생성
# Ctrl+Shift+P → "Tasks: Run Task" → "Vivado: Generate Bitstream"
```

### 디버깅 워크플로우

```bash
# 1. Verilator로 빠른 검증
verilator --lint-only rtl/design.v

# 2. Cocotb로 기능 검증
make sim MODULE=test_design

# 3. 파형 분석
gtkwave dump.vcd

# 4. 타이밍 분석 (Vivado)
vivado -mode batch -source scripts/timing_analysis.tcl
```

## 🛠️ 프로젝트 템플릿

### 기본 디렉토리 구조

```
fpga-project/
├── .vscode/
│   ├── settings.json
│   ├── tasks.json
│   └── launch.json
├── rtl/
│   ├── top.v
│   └── modules/
│       └── *.v
├── tb/
│   ├── test_top.py
│   └── *.py
├── constraints/
│   └── *.xdc
├── scripts/
│   ├── synthesis.tcl
│   ├── implementation.tcl
│   └── bitstream.tcl
├── ip/
│   └── *.xci
├── reports/
├── build/
├── Makefile
├── README.md
└── .gitignore
```

### .gitignore 예시

```gitignore
# Vivado
*.jou
*.log
*.str
*.xpr
.Xil/
build/
*.cache/
*.hw/
*.ip_user_files/
*.runs/
*.sim/

# Python
__pycache__/
*.pyc
*.pyo
results.xml

# Simulation
*.vcd
*.fst
*.ghw
dump.vcd

# Reports
reports/*.rpt
reports/*.dcp
```

## 🔍 문제 해결

### 일반적인 문제

#### 1. Verilator 린팅 오류

```bash
# 문제: "verilator: command not found"
# 해결:
sudo apt-get install verilator

# 환경 변수 확인
which verilator
```

#### 2. Vivado 경로 문제

```bash
# .bashrc 또는 .zshrc에 추가
export VIVADO_PATH=/tools/Xilinx/Vivado/2023.2
source $VIVADO_PATH/settings64.sh

# 확인
vivado -version
```

#### 3. Cocotb 시뮬레이션 실패

```bash
# 문제: "ModuleNotFoundError: No module named 'cocotb'"
# 해결:
pip3 install --upgrade cocotb

# 가상환경 사용 권장
python3 -m venv venv
source venv/bin/activate
pip install cocotb cocotb-test
```

#### 4. VS Code Extension 충돌

```json
// settings.json에서 특정 linter 비활성화
{
    "verilog.linting.linter": "none",  // 충돌 시 일시적으로 비활성화
    "systemverilog.disableCompileOnSave": true
}
```

### 성능 최적화

#### Vivado 빌드 속도 향상

```tcl
# synthesis.tcl
set_param general.maxThreads 8
set_property STEPS.SYNTH_DESIGN.ARGS.DIRECTIVE RuntimeOptimized [get_runs synth_1]
```

#### VS Code 응답 속도 개선

```json
{
    "files.watcherExclude": {
        "**/build/**": true,
        "**/.Xil/**": true,
        "**/reports/**": true
    }
}
```

## 📚 참고 자료

### 공식 문서

- [Xilinx Vivado Documentation](https://www.xilinx.com/support/documentation-navigation/design-hubs/dh0006-vivado-design-hub.html)
- [Cocotb Documentation](https://docs.cocotb.org/)
- [VS Code Documentation](https://code.visualstudio.com/docs)

### 유용한 링크

- [TerosHDL Documentation](https://terostechnology.github.io/terosHDLdoc/)
- [Verilator Manual](https://verilator.org/guide/latest/)
- [GitHub Copilot for HDL](https://github.com/features/copilot)

### 튜토리얼

- [FPGA Development with VS Code](https://github.com/topics/fpga-development)
- [Cocotb Tutorial](https://docs.cocotb.org/en/stable/quickstart.html)
- [Vivado TCL Scripting](https://www.xilinx.com/support/documentation/sw_manuals/xilinx2023_2/ug835-vivado-tcl-commands.pdf)

### 커뮤니티

- [Xilinx Community Forums](https://support.xilinx.com/s/topic/0TO2E000000YKYAWA4/vivado)
- [Reddit r/FPGA](https://www.reddit.com/r/FPGA/)
- [Stack Overflow - FPGA](https://stackoverflow.com/questions/tagged/fpga)

## 🤝 기여하기

프로젝트 개선을 위한 기여를 환영합니다!

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 라이선스

이 프로젝트는 MIT 라이선스를 따릅니다. 자세한 내용은 [LICENSE](LICENSE) 파일을 참조하세요.

## ✉️ 연락처

- **작성자**: 나무
- **이메일**: your.email@example.com
- **GitHub**: [@yourhandle](https://github.com/yourhandle)

## 🙏 감사의 말

- AMD Xilinx for Vivado Design Suite
- Cocotb development team
- VS Code extension developers
- FPGA 커뮤니티의 모든 기여자들

---

**Last Updated**: 2025-02-12

**Version**: 1.0.0
