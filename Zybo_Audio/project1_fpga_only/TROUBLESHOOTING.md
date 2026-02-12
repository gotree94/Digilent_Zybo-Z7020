# 빌드 문제 해결 가이드

## 일반적인 Vivado 빌드 오류

### 1. 파일 경로 오류

**오류 메시지:**
```
[Vivado 12-172] File or Directory '../hdl/audio_top.v' does not exist
```

**원인:** 
- 잘못된 작업 디렉토리에서 스크립트 실행
- 상대 경로 문제

**해결방법:**
```bash
# 올바른 위치로 이동
cd project1_fpga_only/scripts

# 스크립트 실행
vivado -mode batch -source create_project.tcl

# 또는 전체 빌드
./build.sh
```

### 2. I/O Standard 미지정 오류

**오류 메시지:**
```
[DRC NSTD-1] Unspecified I/O Standard: X out of Y logical ports use I/O standard (IOSTANDARD) value 'DEFAULT'
```

**원인:**
- XDC 파일에 핀의 IOSTANDARD가 지정되지 않음

**해결방법:**
XDC 파일에 모든 핀에 대해 IOSTANDARD 지정:
```tcl
set_property -dict {PACKAGE_PIN K17 IOSTANDARD LVCMOS33} [get_ports clk_100mhz]
```

### 3. 핀 위치 미지정 오류

**오류 메시지:**
```
[DRC UCIO-1] Unconstrained Logical Port: X out of Y logical ports have no user assigned specific location constraint (LOC)
```

**원인:**
- XDC 파일에 핀 위치(PACKAGE_PIN)가 지정되지 않음

**해결방법:**
모든 포트에 PACKAGE_PIN 지정:
```tcl
set_property -dict {PACKAGE_PIN T19 IOSTANDARD LVCMOS33} [get_ports ac_mclk]
```

### 4. 보드 파일을 찾을 수 없음

**오류 메시지:**
```
ERROR: [Board 49-71] The board_part definition was not found
```

**원인:**
- Zybo Z7-20 보드 파일이 설치되지 않음

**해결방법:**
```bash
# Vivado에서 보드 파일 설치
# Tools > Settings > Board Repository
# Digilent GitHub에서 보드 파일 다운로드
git clone https://github.com/Digilent/vivado-boards.git

# 보드 파일을 Vivado 디렉토리에 복사
cp -r vivado-boards/new/board_files/* \
  /tools/Xilinx/Vivado/2021.1/data/boards/board_files/

# 또는 보드 설정 없이 프로젝트 생성
# create_project.tcl에서 board_part 라인 제거
```

### 5. 타이밍 위반

**오류 메시지:**
```
[Timing 38-282] The design failed to meet the timing requirements
```

**해결방법:**
```tcl
# 타이밍 리포트 확인
report_timing_summary -file timing.rpt

# 클럭 제약 조건 확인
create_clock -period 10.000 -name sys_clk [get_ports clk_100mhz]

# false path 설정
set_false_path -from [get_clocks sys_clk] -to [get_ports {led[*]}]
```

### 6. 라이선스 오류

**오류 메시지:**
```
ERROR: [Common 17-349] Application Exception: Flexlm error
```

**해결방법:**
```bash
# 라이선스 서버 확인
echo $XILINXD_LICENSE_FILE

# 라이선스 설정
export XILINXD_LICENSE_FILE=2100@license_server

# 또는 무료 버전 사용 (WebPACK)
```

## 프로젝트별 문제

### Project 1: FPGA Only

#### I2C 통신 실패

**증상:** LED[0]이 켜지지 않음

**디버깅:**
```tcl
# ILA 추가하여 I2C 신호 모니터링
create_ip -name ila -vendor xilinx.com -library ip -module_name ila_0
set_property -dict [list CONFIG.C_NUM_OF_PROBES {2}] [get_ips ila_0]

# I2C 신호에 연결
connect_debug_port u_ila_0/probe0 [get_nets i2c_scl]
connect_debug_port u_ila_0/probe1 [get_nets i2c_sda]
```

**해결:**
- I2C 클럭 속도를 낮춤 (i2c_config.v의 CLK_DIV 값 증가)
- 풀업 저항 확인

#### 오디오 노이즈

**원인:** 클럭 주파수 부정확

**해결:**
```verilog
// clk_divider.v 수정
// 더 정확한 MCLK 생성
// 12MHz 대신 12.288MHz 사용
```

## 빌드 최적화

### 합성 최적화

```tcl
# 빠른 합성 (개발용)
set_property STEPS.SYNTH_DESIGN.ARGS.DIRECTIVE RuntimeOptimized [get_runs synth_1]

# 최적화된 합성 (최종 빌드)
set_property STEPS.SYNTH_DESIGN.ARGS.DIRECTIVE PerformanceOptimized [get_runs synth_1]
```

### 병렬 빌드

```bash
# 4개 작업 동시 실행
vivado -mode batch -source build.tcl -jobs 4

# 또는 TCL 스크립트에서
launch_runs synth_1 -jobs 8
```

## 유용한 명령어

### 프로젝트 정리

```bash
# 생성된 파일 모두 삭제
cd project1_fpga_only
rm -rf vivado_project/
rm -rf .Xil/
rm -rf output/

# 다시 빌드
cd scripts
./build.sh
```

### 로그 확인

```bash
# 합성 로그
cat vivado_project/audio_loopback.runs/synth_1/runme.log

# 구현 로그  
cat vivado_project/audio_loopback.runs/impl_1/runme.log

# Vivado 전체 로그
cat vivado.log
```

### 리포트 생성

```tcl
# 타이밍 리포트
report_timing_summary -max_paths 10 -file timing.rpt

# 리소스 사용률
report_utilization -file utilization.rpt

# 전력 소모
report_power -file power.rpt

# DRC 체크
report_drc -file drc.rpt
```

## 추가 도움말

### Vivado GUI에서 문제 확인

```bash
# GUI로 프로젝트 열기
cd project1_fpga_only/scripts
vivado ../vivado_project/audio_loopback.xpr

# Flow Navigator에서:
# - RTL Analysis > Schematic (회로도 확인)
# - Synthesis > Report Utilization
# - Implementation > Report Timing Summary
```

### 온라인 리소스

- [Xilinx Support](https://support.xilinx.com)
- [Digilent Forum](https://forum.digilentinc.com)
- [Vivado Design Suite User Guide](https://www.xilinx.com/support/documentation/sw_manuals/xilinx2021_1/ug893-vivado-ip.pdf)
