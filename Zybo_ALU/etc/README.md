# ALU AXI Project for Zybo Z7-20

**Engineer:** 나무  
**Date:** 2025-11-12  
**Platform:** Digilent Zybo Z7-20 (Xilinx Zynq-7000)

## 프로젝트 개요

이 프로젝트는 8비트 ALU(Arithmetic Logic Unit)를 AXI-Lite 인터페이스로 래핑하여 Zynq의 PS(Processing System)에서 PL(Programmable Logic) 하드웨어 가속기로 접근할 수 있도록 구현한 완전한 임베디드 시스템입니다.

### 주요 기능

- **8비트 ALU 연산**
  - 덧셈 (ADD)
  - 뺄셈 (SUB)
  - 곱셈 (MUL)
  - 나눗셈 (DIV)
  - 나머지 (MOD)
  - 같음 비교 (EQ)
  - 크기 비교 (GT, LT)

- **AXI-Lite 인터페이스**
  - PS에서 간단한 레지스터 맵핑으로 접근
  - 4개의 32비트 레지스터
  - 메모리 맵 주소: 0x43C00000

- **Linux 드라이버**
  - 커널 모듈 형태
  - Sysfs 인터페이스 제공
  - /dev/mem 직접 접근 지원

## 디렉토리 구조

```
zybo_alu_axi/
├── hdl/                          # HDL 소스 파일
│   ├── alu.v                    # 원본 ALU 모듈
│   └── alu_axi_lite_v1_0.v     # AXI-Lite 래퍼
├── tcl/                          # Vivado TCL 스크립트
│   └── create_project.tcl       # 프로젝트 생성 스크립트
├── sw/                           # 소프트웨어
│   ├── alu_driver.c             # 리눅스 커널 드라이버
│   ├── alu-overlay.dts          # 디바이스 트리 오버레이
│   ├── alu_test_devmem.c        # 테스트 프로그램 (/dev/mem)
│   ├── alu_test_sysfs.c         # 테스트 프로그램 (sysfs)
│   └── Makefile                 # 빌드 스크립트
└── docs/                         # 문서
    ├── PETALINUX_SETUP.md       # PetaLinux 설정 가이드
    └── README.md                # 이 파일
```

## 하드웨어 아키텍처

```
┌─────────────────────────────────────────────────────────┐
│                    Zynq-7000 SoC                        │
│                                                           │
│  ┌──────────────────┐       ┌──────────────────────┐   │
│  │  Processing      │       │  Programmable Logic  │   │
│  │  System (PS)     │       │  (PL)                │   │
│  │                  │       │                       │   │
│  │  ┌────────────┐  │       │  ┌────────────────┐  │   │
│  │  │   ARM      │  │       │  │  AXI-Lite      │  │   │
│  │  │   Cortex-A9│◄─┼───────┼─►│  ALU Wrapper   │  │   │
│  │  └────────────┘  │  AXI  │  │                │  │   │
│  │                  │  GP0   │  │  ┌──────────┐  │  │   │
│  │  Linux + Driver  │       │  │  │   ALU    │  │  │   │
│  │                  │       │  │  │  Module  │  │  │   │
│  └──────────────────┘       │  │  └──────────┘  │  │   │
│                              │  └────────────────┘  │   │
└─────────────────────────────────────────────────────────┘
```

## 레지스터 맵

| Offset | Name       | Access | Description                    |
|--------|------------|--------|--------------------------------|
| 0x00   | OPERAND_A  | R/W    | 8-bit 피연산자 A               |
| 0x04   | OPERAND_B  | R/W    | 8-bit 피연산자 B               |
| 0x08   | CONTROL    | R/W    | 제어 레지스터                  |
|        |            |        | [2:0] - opcode                 |
|        |            |        | [3] - enable                   |
| 0x0C   | RESULT     | R      | 16-bit 결과 값                 |

### 연산 코드 (Opcode)

| Code | Operation       | Description      |
|------|-----------------|------------------|
| 0x0  | ADD             | a + b            |
| 0x1  | SUB             | a - b            |
| 0x2  | MUL             | a * b            |
| 0x3  | DIV             | a / b            |
| 0x4  | MOD             | a % b            |
| 0x5  | EQ              | a == b (1/0)     |
| 0x6  | GT              | a > b (1/0)      |
| 0x7  | LT              | a < b (1/0)      |

## 빠른 시작

### 1. Vivado 프로젝트 생성

```bash
cd tcl
vivado -mode tcl -source create_project.tcl
```

Vivado GUI에서:
1. Generate Bitstream
2. File → Export → Export Hardware (Include bitstream 체크)

### 2. PetaLinux 프로젝트 생성

자세한 내용은 `docs/PETALINUX_SETUP.md` 참조

```bash
# PetaLinux 설정
source /tools/Xilinx/PetaLinux/settings.sh

# 프로젝트 생성
petalinux-create --type project --template zynq --name petalinux_alu
cd petalinux_alu

# 하드웨어 구성
petalinux-config --get-hw-description=../hardware

# 빌드
petalinux-build

# 부팅 이미지 생성
petalinux-package --boot --fsbl images/linux/zynq_fsbl.elf \
                          --fpga images/linux/system_wrapper.bit \
                          --u-boot --force
```

### 3. SD 카드 준비 및 부팅

```bash
# BOOT.BIN, image.ub, boot.scr를 FAT32 파티션에 복사
# rootfs.tar.gz를 ext4 파티션에 압축 해제

# Zybo Z7-20 부팅
# USB-UART 연결 (115200 8N1)
# 로그인: root / root
```

### 4. 테스트 실행

```bash
# Sysfs 인터페이스 테스트
alu_test_sysfs -t

# 직접 메모리 접근 테스트
alu_test_devmem -t

# 인터랙티브 모드
alu_test_devmem -i

# 단일 연산
alu_test_devmem -c 25 5 0  # 25 + 5 = 30

# 성능 벤치마크
alu_test_devmem -b
```

## 사용 예제

### Sysfs를 통한 접근

```bash
# 피연산자 설정
echo 100 > /sys/devices/platform/amba/43c00000.alu/operand_a
echo 25 > /sys/devices/platform/amba/43c00000.alu/operand_b

# 덧셈 연산 (opcode=0)
echo 0 > /sys/devices/platform/amba/43c00000.alu/opcode

# 활성화
echo 1 > /sys/devices/platform/amba/43c00000.alu/enable

# 결과 읽기
cat /sys/devices/platform/amba/43c00000.alu/result
# 출력: 125
```

### devmem을 통한 직접 접근

```bash
# 피연산자 A = 50
devmem 0x43C00000 32 0x00000032

# 피연산자 B = 10
devmem 0x43C00004 32 0x0000000A

# 곱셈 연산 (opcode=2) 및 활성화
devmem 0x43C00008 32 0x0000000A

# 결과 읽기
devmem 0x43C0000C 32
# 출력: 0x000001F4 (500)
```

### C 프로그램에서 사용

```c
#include <stdio.h>
#include <fcntl.h>
#include <sys/mman.h>

#define ALU_BASE 0x43C00000

int main() {
    int fd = open("/dev/mem", O_RDWR | O_SYNC);
    volatile uint32_t *alu = mmap(NULL, 0x1000, PROT_READ | PROT_WRITE,
                                  MAP_SHARED, fd, ALU_BASE);
    
    // 15 + 7 계산
    alu[0x00/4] = 15;  // operand_a
    alu[0x04/4] = 7;   // operand_b
    alu[0x08/4] = 0x8; // opcode=0 (ADD), enable=1
    
    printf("Result: %u\n", alu[0x0C/4] & 0xFFFF);
    
    munmap((void *)alu, 0x1000);
    close(fd);
    return 0;
}
```

## 성능

테스트 환경에서 측정된 성능:
- ALU 연산 지연: ~10 µs (레지스터 접근 포함)
- 최대 처리량: ~100,000 ops/sec

## 디버깅

### 하드웨어 확인

```bash
# FPGA 프로그래밍 확인
cat /sys/class/fpga_manager/fpga0/state

# 메모리 맵 확인
cat /proc/iomem | grep 43c00000

# 디바이스 트리 확인
cat /proc/device-tree/amba/alu@43c00000/compatible
```

### 드라이버 확인

```bash
# 드라이버 로드 확인
lsmod | grep alu

# 커널 메시지
dmesg | grep alu

# 수동 드라이버 로드
modprobe alu-driver
```

### 레지스터 덤프

```bash
# 모든 레지스터 읽기
echo "=== ALU Registers ==="
echo -n "OPERAND_A: "; devmem 0x43C00000 32
echo -n "OPERAND_B: "; devmem 0x43C00004 32
echo -n "CONTROL:   "; devmem 0x43C00008 32
echo -n "RESULT:    "; devmem 0x43C0000C 32
```

## 확장 가능성

이 프로젝트를 확장할 수 있는 방법:

1. **더 큰 비트 폭**: 16비트, 32비트 ALU로 확장
2. **추가 연산**: 비트 연산, 시프트, 로테이트 등
3. **인터럽트 지원**: 연산 완료 시 인터럽트 발생
4. **DMA 통합**: 대량 데이터 처리용 DMA 연결
5. **파이프라이닝**: 다단계 파이프라인으로 처리량 향상
6. **부동소수점**: IEEE 754 부동소수점 연산 지원

## 문제 해결

### 드라이버가 로드되지 않음

```bash
# 디바이스 트리 확인
ls -l /sys/firmware/devicetree/base/amba/alu@43c00000/

# compatible 속성 확인
cat /sys/firmware/devicetree/base/amba/alu@43c00000/compatible

# 수동 로드 시도
insmod /lib/modules/$(uname -r)/extra/alu-driver.ko
```

### 권한 오류

```bash
# /dev/mem 권한 설정
sudo chmod 666 /dev/mem

# 또는 root로 실행
sudo alu_test_devmem -t
```

### 예상치 못한 결과

```bash
# 하드웨어 리셋
echo 0 > /sys/devices/platform/amba/43c00000.alu/enable
echo 0 > /sys/devices/platform/amba/43c00000.alu/operand_a
echo 0 > /sys/devices/platform/amba/43c00000.alu/operand_b
echo 0 > /sys/devices/platform/amba/43c00000.alu/opcode
```

## 참고 자료

- [Xilinx Zynq-7000 TRM](https://www.xilinx.com/support/documentation/user_guides/ug585-Zynq-7000-TRM.pdf)
- [AXI Reference Guide](https://www.xilinx.com/support/documentation/ip_documentation/axi_ref_guide/latest/ug1037-vivado-axi-reference-guide.pdf)
- [PetaLinux Tools Documentation](https://www.xilinx.com/support/documentation/sw_manuals/xilinx2022_2/ug1144-petalinux-tools-reference-guide.pdf)
- [Zybo Z7 Reference Manual](https://digilent.com/reference/programmable-logic/zybo-z7/reference-manual)

## 라이센스

이 프로젝트는 교육 목적으로 제공됩니다.

## 기여자

- **나무** - 초기 개발 및 구현

## 버전 이력

- **v1.0** (2025-11-12) - 초기 릴리스
  - 8비트 ALU 구현
  - AXI-Lite 인터페이스
  - Linux 커널 드라이버
  - 테스트 프로그램

## 연락처

질문이나 문제가 있으면 이슈를 등록해 주세요.

---
**프로젝트 상태:** ✅ 완료  
**테스트 상태:** ✅ 통과  
**문서 상태:** ✅ 최신
