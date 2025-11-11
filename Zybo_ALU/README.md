# ⚙️ Zybo Z7-20 AXI-ALU with PetaLinux (Bare-metal Memory Access)

이 프로젝트는 **Zybo Z7-20 (Zynq-7020)** 보드에서 Vivado로 생성한 **AXI-Lite 기반 ALU IP**를  
**PetaLinux 사용자 공간(/dev/mem)** 에서 직접 접근하여 테스트하는 예제입니다.  
커널 드라이버 없이, 메모리 매핑 방식으로 AXI 레지스터를 제어합니다.

---

## 📁 프로젝트 구조

```
zybo_alu_project/
├── vivado_ip/
│   ├── alu_v1_0.v
│   ├── alu_v1_0_S00_AXI.v      # 수정된 AXI 슬레이브 파일 (ALU 연결 포함)
│   └── alu.v                   # 간단한 산술연산 모듈
├── petalinux_app/
│   ├── alu_test.c              # /dev/mem 접근용 C 테스트 프로그램
└── README.md                   # (현재 문서)
```

---

## 🧩 1. Vivado Design 개요

### 🔹 Block Diagram 구성
- **Zynq Processing System (PS7)**  
  - M_AXI_GP0 인터페이스 활성화  
- **ALU IP (axi_alu_v1_0)**  
  - S_AXI 포트 → PS7 M_AXI_GP0 연결  
  - 인터럽트 불필요  
- **Address Editor**  
  - ALU IP Base Address: `0x43C0_0000`
  - Range: 64 KB

### 🔹 ALU 모듈 (alu.v)
```verilog
module ALU(
    input  wire [7:0] a,
    input  wire [7:0] b,
    input  wire [2:0] opcode,
    input  wire       ena,
    output reg  [15:0] result
);
    always @(*) begin
        if (ena) begin
            case (opcode)
                3'b000: result = a + b;
                3'b001: result = a - b;
                3'b010: result = a * b;
                3'b011: result = (b != 0) ? a / b : 16'hFFFF;
                3'b100: result = a & b;
                3'b101: result = a | b;
                3'b110: result = a ^ b;
                3'b111: result = ~a;
                default: result = 16'h0000;
            endcase
        end else begin
            result = 16'h0000;
        end
    end
endmodule
```

### 🔹 AXI Slave 수정 포인트
`alu_v1_0_S00_AXI.v`의 주요 변경:
- `ALU.result` → 중간 `wire`(`alu_result`)로 연결
- `slv_reg1`은 **읽기 전용**으로 지정, `ena=1` 시 결과 래치
- 읽기 MUX는 블로킹(`=`) 할당 사용

---

## 💻 2. Vivado → Bitstream → PetaLinux Flow

1. Vivado에서 Block Design → HDL Wrapper 생성  
2. Bitstream 생성 (`Generate Bitstream`)  
3. `File → Export → Export Hardware (Include Bitstream)`  
4. PetaLinux 프로젝트 생성 및 하드웨어 가져오기:
   ```bash
   cp /mnt/share/design_top_wrapper.xsa ~/projects/

   # PetaLinux 환경이 활성화되어 있는지 확인
   unzip -l design_top_wrapper.xsa

   # Unzip
   unzip design_top_wrapper.xsa -d design_top_wrapper

   # bit 파일 복사
   cp design_top_wrapper/design_top_wrapper.bit myprojec/image/linux
   
   cd ~/projects

   # PetaLinux 환경이 활성화되어 있는지 확인
   source ~/petalinux/2022.2/settings.sh

   # Zybo Z7-20용 프로젝트 생성
   petalinux-create --type project --template zynq --name myproject

   # 프로젝트 디렉토리로 이동
   cd myproject

   # XSA 파일로 하드웨어 설정
   petalinux-config --get-hw-description=~/projects/

    # Root Filesystem 설정
   petalinux-config -c rootfs
   ```
   
5. 빌드 및 부팅 이미지 생성:
   ```bash
   petalinux-build

   # 부트 이미지 생성 (BOOT.BIN)
    petalinux-package --boot \
    --fsbl images/linux/zynq_fsbl.elf \
    --fpga images/linux/design_1_wrapper.bit \
    --u-boot images/linux/u-boot.elf \
    --force

    # WIC 이미지 생성
    petalinux-package --wic \
    --bootfiles "BOOT.BIN image.ub boot.scr" \
    --images-dir images/linux/
   ```

---

## 🧠 3. 레지스터 맵

| 주소(Offset) | 이름 | 설명 | 접근 |
|---------------|-------|------|-------|
| 0x00 | **REG0** | `{a[31:24], b[23:16], …, ena[3], opcode[2:0]}` | RW |
| 0x04 | **REG1** | `{16'h0, result[15:0]}` (ALU 결과) | **RO** |
| 0x08 | **REG2** | Reserved | RW |
| 0x0C | **REG3** | Reserved | RW |

> ⚠️ REG1은 AXI 쓰기 금지. ALU enable(ena=1)일 때만 결과가 래치됩니다.

---

## 🧪 4. PetaLinux 테스트 코드

`alu_test.c` — `/dev/mem` 접근 예제

```bash
# 컴파일 (PC 에서)
arm-linux-gnueabihf-gcc -o alu_test alu_test.c

# 컴파일 (보드 안에서)
gcc -O2 -Wall -o alu_test alu_test.c
```

### 실행 예시

```bash
# (예) Base 0x43C00000 에서 ADD(0)
sudo ./alu_test 0x43C00000 write a=0x12 b=0x34 opcode=0 ena=1

# 결과 확인
sudo ./alu_test 0x43C00000 read
```

출력 예:
```
[WRITE] BASE=0x43C00000 REG0=0x12340009 (a=0x12 b=0x34 opcode=0 ena=1)
[READ ] REG1=0x00000046 -> result=0x0046 (70)
```

---

## 🧰 5. /dev/mem 접근 원리

PetaLinux에서 커널 드라이버를 만들지 않고도 **AXI-Lite 레지스터**를 접근할 수 있습니다.

- `/dev/mem`을 `mmap()`하여 AXI 주소 공간을 직접 매핑  
- 쓰기: `*(base + REG0/4) = value`  
- 읽기: `result = *(base + REG1/4)`  
- `sudo` 권한 필요

---


## 🧩 6. 예상 동작 시나리오

| opcode | 연산 | 설명 |
|--------:|------|------|
| 0 | ADD | a + b |
| 1 | SUB | a - b |
| 2 | MUL | a × b |
| 3 | DIV | a ÷ b |
| 4 | AND | a & b |
| 5 | OR  | a \| b |
| 6 | XOR | a ^ b |
| 7 | NOT | ~a |

---

## 🔍 7. 디버깅 팁

| 문제 | 원인/해결 |
|------|------------|
| `Synthesis failed (8-685)` | ALU 출력이 reg(`slv_reg1`)에 직접 연결됨 → `wire` 중간 사용 |
| `/dev/mem open failed` | root 권한 필요 (`sudo`) |
| 결과가 항상 0 | `ena` 비트가 0이거나 RTL에서 `slv_reg1` 쓰기 누락 |
| 주소 mismatch | Vivado Address Editor의 Base Address 확인 필요 |

---

## 🧾 8. 라이선스 & 참고

- 본 예제는 **학습 및 교육용**으로 자유롭게 수정 및 배포 가능합니다.  
- Vivado 2022.2 / PetaLinux 2022.2 / Zybo Z7-20 기준 작성  
- 하드웨어 IP 수정 시 `Tools → Create and Package IP` 후 리패키징 필수

---

## 📚 References
- [Digilent Zybo Z7-20 Reference Manual](https://digilent.com/reference/programmable-logic/zybo-z7/reference-manual)
- [Xilinx UG980 — AXI4-Lite IP Interface Guide](https://docs.xilinx.com/)
- [PetaLinux Reference Guide (UG1144)](https://docs.xilinx.com/)
- [AXI4-Lite Template (Vivado)](https://xilinx.github.io/)


