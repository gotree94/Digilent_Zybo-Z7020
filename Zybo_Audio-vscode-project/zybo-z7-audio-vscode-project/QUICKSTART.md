# Zybo Z7-20 빠른 시작 가이드

## 🚀 5분 안에 시작하기

### 1단계: 프로젝트 준비 (30초)

```bash
# 프로젝트 다운로드 및 압축 해제
unzip zybo-z7-vscode-project.zip
cd zybo-z7-vscode-project

# VS Code 열기
code .
```

### 2단계: Vivado 환경 설정 (1분)

```bash
# Vivado 환경 변수 설정
source /tools/Xilinx/Vivado/2023.2/settings64.sh

# 버전 확인
vivado -version
```

### 3단계: 첫 빌드 실행 (3분)

**방법 A: VS Code에서 실행 (권장)**

1. `Ctrl+Shift+B` 누르기
2. "Vivado: Full Build" 선택
3. 하단 터미널에서 진행상황 확인

**방법 B: 터미널에서 실행**

```bash
vivado -mode batch -source scripts/full_build.tcl
```

### 4단계: 결과 확인 (30초)

빌드 완료 후:

```bash
# 비트스트림 파일 확인
ls -lh build/zybo_z7_audio.runs/impl_1/top.bit

# 리포트 확인
cat reports/post_impl_timing.rpt
```

## ✅ 체크리스트

빌드 전 확인사항:

- [ ] Vivado 2020.2 이상 설치됨
- [ ] VS Code 설치 및 실행 가능
- [ ] 프로젝트 디렉토리에 모든 파일 존재
- [ ] Vivado 환경 변수 설정됨

## 🎯 다음 단계

### LED Blink 테스트

```verilog
// rtl/top.v의 LED 제어 부분 수정
assign led[0] = counter[24];  // 느린 깜빡임
assign led[1] = counter[20];  // 빠른 깜빡임
```

### 시뮬레이션 실행

```bash
# Cocotb 설치 (최초 1회)
pip install cocotb

# 시뮬레이션
make

# 파형 확인
make waves
```

### 보드에 다운로드

1. Zybo Z7-20 보드를 USB로 연결
2. Vivado Hardware Manager 실행
3. 비트스트림 다운로드:
   ```bash
   # 또는 TCL 명령어로
   vivado -mode tcl
   open_hw_manager
   connect_hw_server
   open_hw_target
   set_property PROGRAM.FILE {build/zybo_z7_audio.runs/impl_1/top.bit} [get_hw_devices]
   program_hw_devices
   ```

## ⚡ 빠른 참조

### 자주 사용하는 명령어

```bash
# 전체 빌드
vivado -mode batch -source scripts/full_build.tcl

# 합성만
vivado -mode batch -source scripts/synthesis.tcl

# 린팅
verilator --lint-only rtl/*.v

# 시뮬레이션
make

# 정리
make clean
rm -rf build/ reports/*.rpt
```

### VS Code 단축키

- `Ctrl+Shift+B`: 빌드 실행
- `Ctrl+Shift+P`: 명령 팔레트
- `Ctrl+`` `: 터미널 열기
- `F5`: 디버깅 시작

## 🆘 자주 묻는 질문

**Q: "vivado: command not found" 오류**
```bash
A: source /tools/Xilinx/Vivado/2023.2/settings64.sh
```

**Q: DRC 오류 (NSTD-1, UCIO-1)**
```
A: constraints/zybo_z7_20.xdc 파일이 프로젝트에 포함되어 있는지 확인
```

**Q: 타이밍 위반**
```
A: reports/post_impl_timing.rpt 확인 후 클럭 제약 조정
```

## 📞 도움이 필요하신가요?

- README.md 전체 문서 참조
- GitHub Issues 등록
- Digilent Forum 검색

---

행운을 빕니다! 🎉
