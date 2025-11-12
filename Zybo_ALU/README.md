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
    
    # 프로젝트 디렉토리로 이동
    cd myproject
    
    # XSA 파일로 하드웨어 설정
    petalinux-config --get-hw-description=~/projects/

    petalinux-config -c rootfs
    ```
   
5. 빌드 및 부팅 이미지 생성:
    ```bash
    petalinux-build -c fsbl-firmware -x cleansstate # 에러 발생시
    petalinux-build -c device-tree -x cleansstate  # 에러 발생시
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

```
root@myproject:~# ./alu_test
Usage:
  ./alu_test <baseaddr_hex> write a=<0xAA|dec> b=<0xBB|dec> opcode=<0..7> ena=<0|1>
  ./alu_test <baseaddr_hex> read
opcode
0 plus 1 minus 2 multiply 3 devide 4 remain 5 compair 6 grather then 7 smaller then

Examples:
  ./alu_test 0x43C00000 write a=0x12 b=0x34 opcode=0 ena=1
  ./alu_test 0x43C00000 read
root@myproject:~# ./alu_test  ./alu_test 0x43C00000 write a=0x34 b=0x34 opcode=5 ena=1
Invalid base address: ./alu_test
root@myproject:~# ./alu_test 0x43C00000 write a=0x12 b=0x34 opcode=0 ena=1
[WRITE] BASE=0x43C00000 REG0=0x12340008 (a=0x12 b=0x34 opcode=0 ena=1)
[READ ] REG1=0x00000046  -> result=0x0046 (70)
root@myproject:~# ./alu_test 0x43C00000 write a=0x34 b=0x34 opcode=5 ena=1
[WRITE] BASE=0x43C00000 REG0=0x3434000D (a=0x34 b=0x34 opcode=5 ena=1)
[READ ] REG1=0x00000001  -> result=0x0001 (1)
root@myproject:~# ./alu_test 0x43C00000 write a=0x34 b=0x31 opcode=5 ena=1
[WRITE] BASE=0x43C00000 REG0=0x3431000D (a=0x34 b=0x31 opcode=5 ena=1)
[READ ] REG1=0x00000000  -> result=0x0000 (0)
root@myproject:~# ./alu_test 0x43C00000 write a=0x34 b=0x31 opcode=6 ena=1
[WRITE] BASE=0x43C00000 REG0=0x3431000E (a=0x34 b=0x31 opcode=6 ena=1)
[READ ] REG1=0x00000001  -> result=0x0001 (1)
root@myproject:~# ./alu_test 0x43C00000 write a=0x34 b=0x31 opcode=7 ena=1
[WRITE] BASE=0x43C00000 REG0=0x3431000F (a=0x34 b=0x31 opcode=7 ena=1)
[READ ] REG1=0x00000000  -> result=0x0000 (0)
root@myproject:~# ./alu_test 0x43C00000 write a=0x34 b=0x31 opcode=1 ena=1
[WRITE] BASE=0x43C00000 REG0=0x34310009 (a=0x34 b=0x31 opcode=1 ena=1)
[READ ] REG1=0x00000003  -> result=0x0003 (3)
root@myproject:~#
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

## 🔍 8. 스위치 / LED 추가

* REG2 (0x08): 스위치 상태 읽기 (읽기 전용) → REG2[3:0] = {SW3..SW0}
* REG3 (0x0C): LED 제어 (쓰기/읽기 가능) → LED[3:0] = REG3[3:0]

* 아래에 RTL 수정, BD 연결, C 코드 업데이트를 한 번에 정리해 드립니다.

1) RTL 수정 (alu_v1_0_S00_AXI.v)

1-1. 포트 추가
 * IP의 S00_AXI 모듈 포트에 스위치 입력/LED 출력 포트를 추가합니다.

```verilog
// Users to add ports here
input  wire [3:0] sw_in,   // ★ 추가: 보드의 4개 스위치 입력
output wire [3:0] led_out  // ★ 추가: 보드의 4개 LED 출력
// User ports ends
```

1-2. 입력 동기화(권장) + 디바운스(선택)
   * 스위치는 비동기이므로 2FF 동기화 정도는 해두는 게 안전합니다.

```verilog
// ★ 동기화 플립플롭 (간단 버전)
reg [3:0] sw_ff1, sw_ff2;
always @(posedge S_AXI_ACLK) begin
  if (!S_AXI_ARESETN) begin
    sw_ff1 <= 4'b0;
    sw_ff2 <= 4'b0;
  end else begin
    sw_ff1 <= sw_in;
    sw_ff2 <= sw_ff1;
  end
end
wire [3:0] sw_sync = sw_ff2; // REG2에 반영할 스위치
```

* 1-3. REG2/REG3 매핑
   * REG2: 읽기 전용으로 스위치 상태를 반영
   * REG3: 쓰기한 값의 하위 4비트로 LED를 구동

* (A) 쓰기 로직(기존 slv_reg_wren case문) 유지 + REG3 쓰기 허용
```verilog
// case (axi_awaddr[...]):
2'h2: begin
  // ★ REG2는 읽기 전용으로 둘 수도 있음(권장: 아래 read MUX에서만 생성)
  //    필요하면 사용자 용도로 RW로 남겨도 됨.
end
2'h3: begin
  for (byte_index=0; byte_index<=(C_S_AXI_DATA_WIDTH/8)-1; byte_index=byte_index+1)
    if (S_AXI_WSTRB[byte_index])
      slv_reg3[byte_index*8 +: 8] <= S_AXI_WDATA[byte_index*8 +: 8];
end
```

* (B) 읽기 MUX에 REG2, REG3 반영
```verilog
always @(*) begin
  case (axi_araddr[ADDR_LSB+OPT_MEM_ADDR_BITS:ADDR_LSB])
    2'h0: reg_data_out = slv_reg0;
    2'h1: reg_data_out = slv_reg1;                         // ALU 결과
    2'h2: reg_data_out = {28'b0, sw_sync};                 // ★ REG2: SW 입력
    2'h3: reg_data_out = slv_reg3;                         // ★ REG3: LED 레지스터
    default: reg_data_out = {C_S_AXI_DATA_WIDTH{1'b0}};
  endcase
end
```

* (C) LED 출력 연결
``` verilog
assign led_out = slv_reg3[3:0]; // ★ REG3 하위 4비트로 LED 구동
```

* 참고: REG2를 완전 읽기 전용으로 두려면, 쓰기 case에서 2'h2는 아무 것도 하지 않도록 두는 게 깔끔합니다(위 예시처럼).

* 2) ALU IP 상위(alu_v1_0.v) 포트 전달
   * IP 패키지의 top 모듈(alu_v1_0.v)에도 동일 포트를 추가하고, 내부 S00_AXI 인스턴스에 패스하세요.
```verilog
module alu_v1_0 #(
  // params...
)(
  // AXI 포트들 ...
  input  wire [3:0] sw_in,     // ★ 외부로 노출
  output wire [3:0] led_out    // ★ 외부로 노출
);
  // ...

  alu_v1_0_S00_AXI #(
    .C_S_AXI_DATA_WIDTH(C_S_AXI_DATA_WIDTH),
    .C_S_AXI_ADDR_WIDTH(C_S_AXI_ADDR_WIDTH)
  ) inst_S00_AXI (
    // 기존 AXI 연결 ...
    .sw_in (sw_in),       // ★ 패스
    .led_out (led_out)    // ★ 패스
  );

endmodule
```

* 3) Vivado Block Design 연결
   * ALU IP Re-package 후 BD에 다시 추가/갱신
   * ALU IP의 sw_in[3:0], led_out[3:0] 포트를 Make External로 빼거나, 별도 top wrapper에서 외부 핀과 연결
   * XDC 제약에 Zybo Z7-20 보드의 SW0..SW3, LD0..LD3 핀을 매핑
   * 핀번호는 Digilent 제공 Zybo Z7-20 Master XDC에서 복사(보드 리비전/모델별 다를 수 있으니 반드시 그 파일 참고)
   * 각 핀에 IOSTANDARD LVCMOS33 설정

* 예)
```tcl
## Switches
set_property PACKAGE_PIN <PIN_SW0> IOSTANDARD LVCMOS33 [get_ports {sw_in[0]}]
set_property PACKAGE_PIN <PIN_SW1> IOSTANDARD LVCMOS33 [get_ports {sw_in[1]}]
set_property PACKAGE_PIN <PIN_SW2> IOSTANDARD LVCMOS33 [get_ports {sw_in[2]}]
set_property PACKAGE_PIN <PIN_SW3> IOSTANDARD LVCMOS33 [get_ports {sw_in[3]}]

## LEDs
set_property PACKAGE_PIN <PIN_LD0> IOSTANDARD LVCMOS33 [get_ports {led_out[0]}]
set_property PACKAGE_PIN <PIN_LD1> IOSTANDARD LVCMOS33 [get_ports {led_out[1]}]
set_property PACKAGE_PIN <PIN_LD2> IOSTANDARD LVCMOS33 [get_ports {led_out[2]}]
set_property PACKAGE_PIN <PIN_LD3> IOSTANDARD LVCMOS33 [get_ports {led_out[3]}]
```

* 4) C 테스트 프로그램 업데이트
   * 기존 /dev/mem 프로그램에 LED 쓰기와 SW 읽기를 추가하면 됩니다.
   * REG2(0x08) 읽기 → switches = r2 & 0xF
   * REG3(0x0C) 쓰기/읽기 → leds 제어

* 아래는 핵심만 발췌한 변경(당신이 쓰던 alu_test.c 구조 기준):

```c
#define REG0_OFF   0x00u
#define REG1_OFF   0x04u
#define REG2_OFF   0x08u  // ★ SW
#define REG3_OFF   0x0Cu  // ★ LED

// 예: 인자에 leds=<0x0~0xF> 있으면 REG3에 반영
//     read 시 REG2/REG3도 함께 출력
...
if (do_write) {
    uint32_t leds = 0xFFFFFFFF; // 기본: 변경 없음 의미
    for (int i = 3; i < argc; ++i) {
        if (parse_kv_u32(argv[i], "leds", &leds)) continue;
        // 기존 a,b,opcode,ena 파싱 유지
    }
    ...
    // ALU 쓰기
    vbase[REG0_OFF/4] = reg0;

    // LED 지정이 들어왔으면 LED도 갱신
    if (leds != 0xFFFFFFFF) {
        uint32_t reg3 = vbase[REG3_OFF/4];
        reg3 = (reg3 & ~0xFu) | (leds & 0xFu);
        vbase[REG3_OFF/4] = reg3;
        printf("[WRITE] REG3(LED) <= 0x%08X (leds=%u)\n", reg3, (unsigned)(leds & 0xF));
    }

    // 결과/스위치 읽기 (옵션)
    uint32_t r1 = vbase[REG1_OFF/4];
    uint32_t r2 = vbase[REG2_OFF/4];
    printf("[READ ] REG1=0x%08X  result=0x%04X\n", r1, (unsigned)(r1 & 0xFFFF));
    printf("[READ ] REG2=0x%08X  switches[3:0]=0x%X\n", r2, (unsigned)(r2 & 0xF));
}
else { // read
    uint32_t r0 = vbase[REG0_OFF/4];
    uint32_t r1 = vbase[REG1_OFF/4];
    uint32_t r2 = vbase[REG2_OFF/4]; // ★
    uint32_t r3 = vbase[REG3_OFF/4]; // ★
    printf("[DUMP]\n");
    printf("  REG0=0x%08X\n", r0);
    printf("  REG1=0x%08X  result=0x%04X\n", r1, (unsigned)(r1 & 0xFFFF));
    printf("  REG2=0x%08X  switches[3:0]=0x%X\n", r2, (unsigned)(r2 & 0xF));
    printf("  REG3=0x%08X  leds[3:0]=0x%X\n", r3, (unsigned)(r3 & 0xF));
}
```

* 실행 예
```bash
# LED 0~3을 0b1010로 점등 + ALU ADD 실행
sudo ./alu_test 0x43C00000 write a=0x12 b=0x03 opcode=0 ena=1 leds=0xA

# 현재 스위치/LED/ALU 결과 덤프
sudo ./alu_test 0x43C00000 read
```

5) 디버깅 팁

* 스위치 방향(풀업/풀다운)에 따라 논리가 반대로 읽힐 수 있습니다 → 필요 시 ~sw_sync 로 반전
* 핀맵 불일치로 LED가 안 켜지면 XDC에서 핀/뱅크/IOSTANDARD 확인
* 레지스터가 읽히지 않으면 PetaLinux에서 /dev/mem 권한과 Base Address 확인

---

## 🧾 9. 라이선스 & 참고

- 본 예제는 **학습 및 교육용**으로 자유롭게 수정 및 배포 가능합니다.  
- Vivado 2022.2 / PetaLinux 2022.2 / Zybo Z7-20 기준 작성  
- 하드웨어 IP 수정 시 `Tools → Create and Package IP` 후 리패키징 필수

---

## 📚 References
- [Digilent Zybo Z7-20 Reference Manual](https://digilent.com/reference/programmable-logic/zybo-z7/reference-manual)
- [Xilinx UG980 — AXI4-Lite IP Interface Guide](https://docs.xilinx.com/)
- [PetaLinux Reference Guide (UG1144)](https://docs.xilinx.com/)
- [AXI4-Lite Template (Vivado)](https://xilinx.github.io/)


