# 🧠 Bilateral Filter Pack — C / Python / Verilog (1995) + Testbench

엣지를 보존하면서 노이즈를 효과적으로 제거하는 **Bilateral Filter**의 C, Python, Verilog(1995, ModelSim 10.1 호환) 구현입니다.  
MRI / CT 영상의 전처리용으로 **입력 영상의 노이즈 레벨을 분석하여 자동으로 LUT를 최적화**하도록 설계되었습니다.

---

## 📘 1. 알고리즘 개요

출력 픽셀은 다음 식으로 계산됩니다:

\[
I_{out}(x,y) = \frac{\sum w_s(x,y) \cdot w_r(|I - I_{center}|) \cdot I}{\sum w_s(x,y) \cdot w_r(|I - I_{center}|)}
\]

| 구성 요소 | 설명 |
|------------|------|
| **공간 가중치(Spatial)** | 5×5 정수형 커널<br>중심 41, 축 ±1=26, ±2=7, 대각=16, 기사=4, 코너=1 |
| **범위 가중치(Range)** | `range_lut_256.mem`에서 조회 (0~255)<br>→ `exp(-d² / 2σᵣ²)` 기반 정수화 |
| **σᵣ 선택 기준** | σᵣ = clamp(1.5×σₙ, 8, 40)<br>σₙ: 입력 이미지(`brainct_001.bmp`)의 노이즈 추정값(MAD 기반) |
| **경계 처리** | Replicate Padding |
| **정수 연산 구조** | `sum_w`, `sum_wr` 누적 후 나눗셈 → 8bit clip |

---

## 🧩 2. 폴더 구성

```
bilateral_pack/
│
├─ bilateral.c                # C 구현
├─ bilateral.py               # Python 구현
├─ verilog/
│   ├─ bilateral_frame.v      # Verilog-1995 본체 (ModelSim 10.1 호환)
│   ├─ bilateral_tb.v         # Testbench (상대경로 ../..)
│   └─ common/
│       └─ range_lut_256.mem  # 범위 LUT (자동 생성)
│
├─ brainct_001.bmp            # 예시 입력 영상 (MRI/CT)
├─ range_lut_256_meta.json    # LUT 생성 시 파라미터 정보
├─ compare_results.py         # 결과 비교 유틸리티
└─ compare_gui.py             # 시각적 비교 GUI (BMP 비교)
```

---

## ⚙️ 3. 실행 흐름

### ✅ Step 1: LUT 자동 생성

`brainct_001.bmp`의 노이즈 수준을 기반으로 Bilateral의 σᵣ을 자동으로 조정합니다.

```bash
python make_range_lut.py
```

> 결과 파일:
> - `range_lut_256.mem`
> - `range_lut_256_meta.json`

---

### ✅ Step 2: 필터 실행

#### 🧮 (A) C 실행
```bash
cl /O2 bilateral.c
bilateral.exe
```

출력:
- `output_grayscale-c.bmp`
- `output_bilateral-c.bmp`
- `output_bilateral-c.mem`

#### 🐍 (B) Python 실행
```bash
python bilateral.py
```

출력:
- `output_grayscale-py.bmp`
- `output_bilateral-py.bmp`
- `output_bilateral-py.mem`

#### ⚡ (C) Verilog 실행 (ModelSim 10.1)
```bash
cd verilog
vlib work
vlog bilateral_frame.v
vlog bilateral_tb.v
vsim -c bilateral_tb -do "run -all; quit"
```

출력:
- `../../output_bilateral-vlog.mem`

---

## 🧠 4. LUT(`range_lut_256.mem`) 구조

| 행 번호 | HEX 값 | 의미 |
|----------|---------|------|
| 0 | FF | 밝기 차이 0 → 가중치 1.0 |
| 10 | FA | 작은 차이 → 약간의 감쇠 |
| 128 | 40 | 중간 차이 → 약한 영향 |
| 255 | 00 | 큰 차이 → 완전 무시 |

생성식:
```
LUT[d] = round(255 * exp(-d^2 / (2 * σ_r^2)))
```

---

## 🔬 5. 세 구현(C / Python / Verilog)의 동기화

| 항목 | C | Python | Verilog |
|------|--|---------|----------|
| 입력 포맷 | BMP | BMP | MEM(XX\r\n) |
| LUT 로딩 | fopen / fread | open().read() | `$readmemh` |
| 연산 | 정수 누적 | NumPy float → int 변환 | 정수 누적 |
| 결과 일치 | ✅ | ✅ | ✅ (1995 문법) |

---

## 🧩 6. 비교 도구

### `compare_results.py`
- C / Python / Verilog 결과 비교 (파일 크기, 바이트, 값 일치)
- MEM 파일의 줄바꿈(EOL) 차이까지 감지

### `compare_gui.py`
- BMP 시각 비교 도구
- `brainct_001.bmp` 원본과 결과 이미지 간 **차이 시각화**
- 차이 히트맵 및 평균 편차 로그 표시

---

## 💡 7. 트러블슈팅

| 문제 | 원인 | 해결 |
|------|------|------|
| LUT 불일치 | `range_lut_256.mem` 누락/위치 오류 | 실행 폴더에 동일 LUT 배치 |
| Verilog 컴파일 에러 | Verilog-2001 문법 사용 | 모든 파일 1995 문법으로 수정됨 |
| MEM 불일치 | EOL 차이 (`\r\n` vs `\n`) | C/Py 모두 `\r\n`로 통일 |
| 결과 값 차이 | LUT 다름 / 정규화 오류 | LUT 동일 여부 확인 |

---

## 📄 8. 메타 예시 (`range_lut_256_meta.json`)

```json
{
  "image": "brainct_001.bmp",
  "estimated_sigma_noise": 4.21,
  "chosen_sigma_r": 8.0,
  "formula": "exp(-d^2/(2*sigma_r^2))*255",
  "line_ending": "CRLF"
}
```

---

## 🧾 9. Bilateral 필터의 장점

| 항목 | 설명 |
|------|------|
| 엣지 보존 | Gaussian 대비 경계 손상 최소화 |
| 노이즈 제거 | Median보다 부드럽고 안정적 |
| 조정 가능 | LUT 기반 σᵣ 수정으로 강도 조절 |
| 하드웨어 구현 | 정수형 LUT 기반 구조로 FPGA 친화적 |

---

## 📦 10. 확장 계획

- LUT 자동 재학습 기능 추가 (`auto_sigma.py`)
- LUT를 σᵣ 파라미터별 다중 저장 (`range_lut_soft/medium/strong.mem`)
- Verilog 테스트 자동화 스크립트 (`run_all.tcl`)
- FPGA 적용 (Zybo Z7-20 기반)

---

### ✅ 결론

이 Bilateral 필터는 MRI/CT 영상의 전처리용으로 최적화되어 있으며,  
C / Python / Verilog 간 **정밀한 결과 일치**와 **하드웨어 구현 친화성**을 모두 만족합니다.
